import 'dart:async';
import 'dart:developer' as developer;
import 'dart:math' as math;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Hardware Models
// ---------------------------------------------------------------------------

enum HardwareConnectionState { disconnected, scanning, connecting, connected }

class EMGData {
  const EMGData({required this.channels, required this.timestamp});

  /// 10 channels of raw/processed sEMG data (0.0 to 1.0 normalized).
  final List<double> channels;
  final DateTime timestamp;

  /// Mapping indices to anatomical regions.
  double get lGastroc => channels[0];
  double get lSoleus => channels[1];
  double get rGastroc => channels[2];
  double get rSoleus => channels[3];
  double get lVastusMedialis => channels[4];
  double get rVastusMedialis => channels[5];
  double get lGluteMedius => channels[6];
  double get rGluteMedius => channels[7];
  double get lErectorSpinae => channels[8];
  double get rErectorSpinae => channels[9];

  static EMGData empty() => EMGData(
        channels: List.filled(10, 0.0),
        timestamp: DateTime.now(),
      );
}

// ---------------------------------------------------------------------------
// HardwareController
// ---------------------------------------------------------------------------

class HardwareController extends Notifier<HardwareConnectionState> {
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<List<int>>? _dataSubscription;
  BluetoothDevice? _targetDevice;

  final _emgDataController = StreamController<EMGData>.broadcast();
  Stream<EMGData> get emgDataStream => _emgDataController.stream;

  // Smoothing (Exponential Moving Average)
  final List<double> _smoothedValues = List.filled(10, 0.0);
  static const double _alpha = 0.2;

  // Random for mock data
  final _random = math.Random();

  // Placeholder UUIDs for ESP32-S3
  static const String _serviceUuid = 'FF01';
  static const String _characteristicUuid = 'FF02';

  @override
  HardwareConnectionState build() {
    ref.onDispose(() {
      _scanSubscription?.cancel();
      _dataSubscription?.cancel();
      _targetDevice?.disconnect();
      _emgDataController.close();
    });
    return HardwareConnectionState.disconnected;
  }

  // -- Connection Logic --

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
      developer.log('BLE Scan Error', error: e, name: 'HardwareController');
      state = HardwareConnectionState.disconnected;
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    _scanSubscription?.cancel();
    await FlutterBluePlus.stopScan();
    
    state = HardwareConnectionState.connecting;
    _targetDevice = device;

    try {
      await device.connect();
      state = HardwareConnectionState.connected;

      final services = await device.discoverServices();
      for (final s in services) {
        if (s.uuid.toString().toUpperCase().contains(_serviceUuid)) {
          for (final c in s.characteristics) {
            if (c.uuid.toString().toUpperCase().contains(_characteristicUuid)) {
              _subscribeToData(c);
              break;
            }
          }
        }
      }
    } catch (e) {
      developer.log('BLE Connection Error', error: e, name: 'HardwareController');
      state = HardwareConnectionState.disconnected;
    }
  }

  void _subscribeToData(BluetoothCharacteristic characteristic) {
    _dataSubscription = characteristic.lastValueStream.listen((value) {
      if (value.length >= 10) {
        final rawChannels = value.take(10).map((v) => v / 255.0).toList();
        _processRawData(rawChannels);
      }
    });
    characteristic.setNotifyValue(true);
  }

  void _processRawData(List<double> raw) {
    for (var i = 0; i < 10; i++) {
      _smoothedValues[i] = (_alpha * raw[i]) + ((1 - _alpha) * _smoothedValues[i]);
    }
    _emgDataController.add(EMGData(
      channels: List.from(_smoothedValues),
      timestamp: DateTime.now(),
    ));
  }

  // -- Mock Mode for Demos --

  Timer? _mockTimer;
  void startMockData() {
    _mockTimer?.cancel();
    state = HardwareConnectionState.connected;
    
    _mockTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      final t = DateTime.now().millisecondsSinceEpoch / 1000.0;
      final mockRaw = List.generate(10, (i) {
        return (math.sin(t * 2 + i) + 1.0) / 2.0 * (0.5 + _random.nextDouble() * 0.5);
      });
      _processRawData(mockRaw);
    });
  }

  void stopMockData() {
    _mockTimer?.cancel();
    state = HardwareConnectionState.disconnected;
  }
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final hardwareControllerProvider =
    NotifierProvider<HardwareController, HardwareConnectionState>(
  HardwareController.new,
);

final emgDataStreamProvider = StreamProvider<EMGData>((ref) {
  final controller = ref.watch(hardwareControllerProvider.notifier);
  return controller.emgDataStream;
});

final latestEMGDataProvider = Provider<EMGData>((ref) {
  final stream = ref.watch(emgDataStreamProvider);
  return stream.value ?? EMGData.empty();
});
