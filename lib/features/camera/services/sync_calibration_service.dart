import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bioliminal/domain/models.dart';
import 'package:bioliminal/core/services/hardware_controller.dart';
import 'package:bioliminal/core/providers.dart';

class SyncResult {
  const SyncResult({required this.offsetMs, required this.confidence});
  final int offsetMs;
  final double confidence;
}

class SyncCalibrationService extends Notifier<SyncResult?> {
  static const int _windowSize = 30; // ~1 second @ 30fps
  final List<double> _visionVelocity = [];
  final List<double> _emgVelocity = [];

  DateTime? _visionPeakTime;
  DateTime? _emgPeakTime;

  @override
  SyncResult? build() {
    // Listen to vision landmarks
    ref.listen<List<PoseLandmark>>(currentLandmarksProvider, (prev, next) {
      if (next.isNotEmpty) _processVision(next);
    });

    // Listen to EMG data
    ref.listen<EMGData>(latestEMGDataProvider, (prev, next) {
      _processSensing(next);
    });

    return null;
  }

  void _processVision(List<PoseLandmark> landmarks) {
    if (state != null) return;

    // Monitor vertical position of both ankles
    final leftAnkleY = landmarks[27].y;
    final rightAnkleY = landmarks[28].y;
    final avgY = (leftAnkleY + rightAnkleY) / 2.0;

    _visionVelocity.add(avgY);
    if (_visionVelocity.length > _windowSize) _visionVelocity.removeAt(0);

    if (_visionVelocity.length < 3) return;

    // Detect sharp downward "impact" (peak in Y coordinate)
    final v1 =
        _visionVelocity[_visionVelocity.length - 2] -
        _visionVelocity[_visionVelocity.length - 3];
    final v2 =
        _visionVelocity[_visionVelocity.length - 1] -
        _visionVelocity[_visionVelocity.length - 2];

    if (v1 > 0.05 && v2 < -0.05) {
      _visionPeakTime = DateTime.now();
      _tryCalculateOffset();
    }
  }

  void _processSensing(EMGData data) {
    if (state != null) return;

    // Monitor calf activation (Gastroc/Soleus)
    final activation =
        (data.lGastroc + data.rGastroc + data.lSoleus + data.rSoleus) / 4.0;

    _emgVelocity.add(activation);
    if (_emgVelocity.length > _windowSize) _emgVelocity.removeAt(0);

    if (_emgVelocity.length < 3) return;

    // Detect sharp spike in activation
    final d1 =
        _emgVelocity[_emgVelocity.length - 1] -
        _emgVelocity[_emgVelocity.length - 2];

    if (d1 > 0.4) {
      // Huge jump in muscle firing
      _emgPeakTime = DateTime.now();
      _tryCalculateOffset();
    }
  }

  void _tryCalculateOffset() {
    if (_visionPeakTime != null && _emgPeakTime != null) {
      final delta = _visionPeakTime!.difference(_emgPeakTime!).inMilliseconds;

      // If peaks are within 500ms, accept the sync
      if (delta.abs() < 500) {
        state = SyncResult(offsetMs: delta, confidence: 0.95);
        ref.read(hardwareSyncOffsetProvider.notifier).value = delta;
      }
    }
  }

  void reset() {
    state = null;
    _visionPeakTime = null;
    _emgPeakTime = null;
    _visionVelocity.clear();
    _emgVelocity.clear();
  }
}

final syncCalibrationServiceProvider =
    NotifierProvider<SyncCalibrationService, SyncResult?>(
      SyncCalibrationService.new,
    );
