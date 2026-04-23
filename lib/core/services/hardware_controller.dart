import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sample_batch.dart';

enum HardwareConnectionState { disconnected, scanning, connecting, connected }

/// BLE bridge to the ESP32 firmware (sketch `bicep_autonomous` or, with
/// the ratified 2026-04-21 amendment, `bicep_hybrid`).
///
/// Subscribes to FF02 NOTIFY for the 310-byte raw EMG stream. Per the
/// pose-authoritative amendment
/// (`bioliminal-ops/decisions/2026-04-21-pose-authoritative-rep-counting.md`),
/// phone now writes rep boundaries back to firmware over FF04 so firmware
/// can reconcile its local envelope-peak count with the authoritative
/// pose-derived count. Three FF04 writes survive:
///
/// - `SET_SESSION_STATE(Calibrating)` on session start
/// - `SET_SESSION_STATE(Idle)` on session end
/// - `OP_REP_CONFIRMED(rep_num, t_ms)` on every pose-confirmed rep
///
/// Firmware still owns fatigue detection + haptic cue firing inside the
/// session; the app consumes `repCount` (now phone-authoritative, written
/// back verbatim by firmware) and `cueEvent` (enum — fatigue fade /
/// urgent / stop / calibration_done) fields from every packet.
///
/// Protocol contract:
/// - Service: `FF01`
/// - Notify char: `FF02` (310 B @ 40 Hz, raw + rect + env @ 2 kHz, plus
///   rep_count + cue_event in the 10-byte header)
/// - Write char:  `FF04`
///   - 0x12 SET_SESSION_STATE   [state u8]
///   - 0x13 OP_REP_CONFIRMED    [rep_num u8][t_ms u24 LE]
class HardwareController extends Notifier<HardwareConnectionState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _notifySubscription;
  StreamSubscription<BluetoothConnectionState>? _connectionSubscription;
  BluetoothDevice? _targetDevice;
  BluetoothCharacteristic? _commandChar;

  final _rawEmgController = StreamController<SampleBatch>.broadcast();
  Stream<SampleBatch> get rawEmgStream => _rawEmgController.stream;

  final _seqGapController = StreamController<int>.broadcast();
  Stream<int> get seqGapStream => _seqGapController.stream;

  // Firmware-driven session counters, exposed as incremental streams so the
  // UI can react only when they change (not on every 25 ms packet tick).
  final _repCountController = StreamController<int>.broadcast();
  Stream<int> get repCountStream => _repCountController.stream;

  // Broadcasts once per firmware cue fire (cue_event bit0 transitions low→high
  // in the packet header). Payload is void because the cue type is not
  // surfaced by the autonomous firmware — the flash indicator only needs the
  // event timing.
  final _cueEventController = StreamController<void>.broadcast();
  Stream<void> get cueEventStream => _cueEventController.stream;

  int? _lastSeqNum;
  int? _lastRepCount;
  int _malformedPacketCount = 0;

  // Remembered FF04 SET_SESSION_STATE value so we can resync firmware after a
  // BLE reconnect. Firmware resets to Idle on disconnect; without this, the
  // app reconnects, the user keeps curling, and no FF02 packets arrive because
  // the firmware gate is still closed.
  int? _lastSessionState;

  // Set to true once FF02 NOTIFY is armed during service discovery. Paired
  // with a non-null _commandChar check to detect a silent discovery failure
  // (peripheral advertised FF01 but is missing one of the characteristics).
  bool _notifyCharFound = false;

  static const String _serviceUuid = 'FF01';
  static const String _notifyCharUuid = 'FF02';
  static const String _writeCharUuid = 'FF04';

  @override
  HardwareConnectionState build() {
    ref.onDispose(() {
      _scanSubscription?.cancel();
      _notifySubscription?.cancel();
      _connectionSubscription?.cancel();
      _targetDevice?.disconnect();
      _rawEmgController.close();
      _seqGapController.close();
      _repCountController.close();
      _cueEventController.close();
    });
    return HardwareConnectionState.disconnected;
  }

  Future<void> startScan() async {
    if (state != HardwareConnectionState.disconnected) return;
    state = HardwareConnectionState.scanning;

    try {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 10));
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.device.platformName.contains('Bioliminal') ||
              r.device.remoteId.str.contains('ESP32')) {
            _connectToDevice(r.device);
            break;
          }
        }
      });
    } catch (e) {
      developer.log('BLE scan error', error: e, name: 'HardwareController');
      state = HardwareConnectionState.disconnected;
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();

    state = HardwareConnectionState.connecting;
    _targetDevice = device;
    _lastSeqNum = null;
    _lastRepCount = null;
    _notifyCharFound = false;
    _commandChar = null;

    try {
      await device.connect();

      _connectionSubscription = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _commandChar = null;
          _lastSeqNum = null;
          _lastRepCount = null;
          _notifyCharFound = false;
          state = HardwareConnectionState.disconnected;
        }
      });

      final services = await device.discoverServices();
      for (final s in services) {
        if (!s.uuid.toString().toUpperCase().contains(_serviceUuid)) continue;
        for (final c in s.characteristics) {
          final cu = c.uuid.toString().toUpperCase();
          if (cu.contains(_notifyCharUuid)) {
            await _subscribeToNotify(c);
          } else if (cu.contains(_writeCharUuid)) {
            _commandChar = c;
          }
        }
      }

      if (!_notifyCharFound || _commandChar == null) {
        developer.log(
          'BLE discovery incomplete (FF02=$_notifyCharFound, FF04=${_commandChar != null}); disconnecting',
          name: 'HardwareController',
        );
        await device.disconnect();
        return;
      }

      state = HardwareConnectionState.connected;

      // Firmware resets to Idle on disconnect. If we had a session state in
      // flight (Calibrating/Active) before the drop, re-assert it so sampling
      // and FF02 notifications resume without the user restarting the set.
      final lastState = _lastSessionState;
      if (lastState != null) {
        developer.log(
          'resyncing SET_SESSION_STATE=$lastState after connect',
          name: 'HardwareController',
        );
        await sendCommand([0x12, lastState]);
      }
    } catch (e) {
      developer.log('BLE connect error', error: e, name: 'HardwareController');
      state = HardwareConnectionState.disconnected;
    }
  }

  Future<void> _subscribeToNotify(
    BluetoothCharacteristic characteristic,
  ) async {
    await _notifySubscription?.cancel();
    await characteristic.setNotifyValue(true);
    _notifySubscription = characteristic.lastValueStream.listen(_onPacket);
    _notifyCharFound = true;
  }

  void _onPacket(List<int> bytes) {
    final batch = SampleBatch.decode(bytes);
    if (batch == null) {
      _malformedPacketCount++;
      if (_malformedPacketCount == 1 || _malformedPacketCount % 100 == 0) {
        developer.log(
          'malformed FF02 packet (len=${bytes.length}, count=$_malformedPacketCount)',
          name: 'HardwareController',
        );
      }
      return;
    }

    final last = _lastSeqNum;
    if (last != null) {
      final gap = (batch.seqNum - last - 1) & 0xFF;
      if (gap > 0) _seqGapController.add(gap);
    }
    _lastSeqNum = batch.seqNum;

    if (_lastRepCount != batch.repCount) {
      _lastRepCount = batch.repCount;
      _repCountController.add(batch.repCount);
    }
    if (batch.cueFired) {
      _cueEventController.add(null);
    }

    _rawEmgController.add(batch);
  }

  /// Write an arbitrary opcode payload to FF04. Returns silently when the
  /// command characteristic isn't yet discovered (still scanning / connecting)
  /// — caller is expected to gate on connection state when correctness matters.
  Future<void> sendCommand(List<int> bytes) async {
    final ch = _commandChar;
    if (ch == null) {
      developer.log(
        'sendCommand dropped — FF04 not discovered',
        name: 'HardwareController',
      );
      return;
    }
    final withResponse = ch.properties.write;
    try {
      await ch.write(bytes, withoutResponse: !withResponse);
    } catch (e) {
      developer.log('FF04 write error', error: e, name: 'HardwareController');
    }
  }

  // Cue-firing helpers are **no-ops** in the hardware-led branch. The
  // autonomous firmware decides when to buzz based on its own fatigue
  // tracking; the app doesn't push PULSE_BURST (0x10) or STOP_HAPTIC (0x11)
  // anymore. The helpers are kept so existing call sites compile, but they
  // return immediately without touching the BLE stack.
  Future<void> fireFatigueFade() async {}
  Future<void> fireFatigueUrgent() async {}
  Future<void> fireFormAlert() async {}
  Future<void> stopHaptic([int motorIdx = 0]) async {}

  Future<void> setSessionState(int sessionState) {
    _lastSessionState = sessionState;
    return sendCommand([0x12, sessionState]);
  }

  /// Inform firmware that the phone has pose-confirmed rep number [repNum]
  /// at wall-clock time [tMs]. Fires on every boundary emitted by the
  /// pose `RepDetector`; firmware overwrites its local count and logs
  /// `[rep-disagree]` when local and phone counts diverge by more than 1.
  ///
  /// `t_ms` is encoded as u24 LE (wraps every ~4.6 hours, which is well
  /// beyond any single session). Opcode and payload shape match the
  /// 2026-04-21 amendment and are documented in the firmware's FF04
  /// opcode table — see `bicep_hybrid.ino` and `bicep_realtime.ino`.
  Future<void> sendRepConfirmed(int repNum, int tMs) async {
    final t24 = tMs & 0xFFFFFF;
    await sendCommand([
      0x13,
      repNum & 0xFF,
      t24 & 0xFF,
      (t24 >> 8) & 0xFF,
      (t24 >> 16) & 0xFF,
    ]);
  }
}

final hardwareControllerProvider =
    NotifierProvider<HardwareController, HardwareConnectionState>(
      HardwareController.new,
    );

final rawEmgStreamProvider = StreamProvider<SampleBatch>((ref) {
  return ref.watch(hardwareControllerProvider.notifier).rawEmgStream;
});

final seqGapStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(hardwareControllerProvider.notifier).seqGapStream;
});

final hardwareRepCountStreamProvider = StreamProvider<int>((ref) {
  return ref.watch(hardwareControllerProvider.notifier).repCountStream;
});

final hardwareCueEventStreamProvider = StreamProvider<void>((ref) {
  return ref.watch(hardwareControllerProvider.notifier).cueEventStream;
});
