import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hardware_controller.dart';
import '../providers.dart';

enum BiofeedbackCue { none, vibrate, squeeze }

class BiofeedbackState {
  const BiofeedbackState({
    required this.gsRatio,
    required this.activeCue,
    required this.message,
  });

  final double gsRatio;
  final BiofeedbackCue activeCue;
  final String message;

  static BiofeedbackState empty() => const BiofeedbackState(
    gsRatio: 1.0,
    activeCue: BiofeedbackCue.none,
    message: 'Normal activation',
  );
}

class BiofeedbackEngine extends Notifier<BiofeedbackState> {
  @override
  BiofeedbackState build() {
    // Only run if premium is enabled
    final isPremium = ref.watch(isPremiumProvider);
    if (!isPremium) return BiofeedbackState.empty();

    // Listen to EMG data
    ref.listen<EMGData>(latestEMGDataProvider, (prev, next) {
      _analyze(next);
    });

    return BiofeedbackState.empty();
  }

  void _analyze(EMGData data) {
    // Gastrocnemius : Soleus Ratio (based on Uhlrich 2023)
    // Target: We want higher soleus activation relative to gastroc during squats
    // to reduce knee contact forces.

    final gastroc = (data.lGastroc + data.rGastroc) / 2.0;
    final soleus = (data.lSoleus + data.rSoleus) / 2.0;

    if (soleus < 0.05) return; // Ignore low signal

    final ratio = gastroc / soleus;

    BiofeedbackCue cue = BiofeedbackCue.none;
    String message = 'Optimal G:S Ratio';

    if (ratio > 1.5) {
      // Gastroc is too dominant
      cue = BiofeedbackCue.vibrate;
      message = 'Activate soleus more';
    } else if (ratio > 2.0) {
      // Critical imbalance
      cue = BiofeedbackCue.squeeze;
      message = 'High knee stress detected';
    }

    state = BiofeedbackState(gsRatio: ratio, activeCue: cue, message: message);

    // TODO: Send command back to ESP32 via HardwareController
  }
}

final biofeedbackEngineProvider =
    NotifierProvider<BiofeedbackEngine, BiofeedbackState>(
      BiofeedbackEngine.new,
    );
