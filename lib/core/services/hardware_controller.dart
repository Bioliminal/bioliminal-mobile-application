import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'sample_batch.dart';

enum HardwareConnectionState { disconnected, scanning, connecting, connected }

/// BLE bridge to the ESP32 firmware (sketch `bicep_realtime`).
///
/// Subscribes to FF02 NOTIFY for the 308-byte raw EMG stream and writes cue
/// payloads to FF04. Decoded packets are exposed as a broadcast
/// [Stream<SampleBatch>]; sequence-number gaps are surfaced separately so
/// downstream UI can light a "dropped packet" badge without parsing every
/// batch.
///
/// Protocol contract:
/// - Service: `FF01`
/// - Notify char: `FF02` (308 B @ 40 Hz, raw + rect + env @ 2 kHz)
/// - Write char:  `FF04` (variable, opcodes 0x10/0x11/0x12)
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

  int? _lastSeqNum;
  int _malformedPacketCount = 0;

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

    try {
      await device.connect();
      state = HardwareConnectionState.connected;

      _connectionSubscription = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          _commandChar = null;
          _lastSeqNum = null;
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
    } catch (e) {
      developer.log('BLE connect error', error: e, name: 'HardwareController');
      state = HardwareConnectionState.disconnected;
    }
  }

  Future<void> _subscribeToNotify(BluetoothCharacteristic characteristic) async {
    await characteristic.setNotifyValue(true);
    _notifySubscription = characteristic.lastValueStream.listen(_onPacket);
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

  // Pre-computed cue payloads from haptic-cueing-handshake.md §"BLE protocol".
  // Kept here for BleDebugView smoke testing; production cue dispatch should go
  // through CueDispatcher → Cue.writeTo() so v2 pressure cues plug in cleanly.
  static const List<int> _payloadFatigueFade =
      [0x10, 0x00, 0xB4, 0x02, 0xC8, 0x00, 0x96, 0x00];
  static const List<int> _payloadFatigueUrgent =
      [0x10, 0x00, 0xE6, 0x02, 0xC8, 0x00, 0x96, 0x00];
  static const List<int> _payloadFormAlert =
      [0x10, 0x00, 0xE6, 0x03, 0x64, 0x00, 0x50, 0x00];

  Future<void> fireFatigueFade() => sendCommand(_payloadFatigueFade);
  Future<void> fireFatigueUrgent() => sendCommand(_payloadFatigueUrgent);
  Future<void> fireFormAlert() => sendCommand(_payloadFormAlert);
  Future<void> stopHaptic([int motorIdx = 0]) =>
      sendCommand([0x11, motorIdx]);
  Future<void> setSessionState(int sessionState) =>
      sendCommand([0x12, sessionState]);
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
