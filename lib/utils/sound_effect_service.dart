import 'package:flutter/services.dart';

/// Kid-friendly sound and haptic feedback service
class SoundEffectService {
  static bool soundEnabled = true;
  static bool hapticsEnabled = true;

  /// Playful tap/pop feedback for fills, color picks, and button presses
  static void playPop() {
    if (hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Celebratory vibration and audio cue on save or complete
  static void playCelebrate() {
    if (hapticsEnabled) {
      HapticFeedback.mediumImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        HapticFeedback.heavyImpact();
      });
    }
    if (soundEnabled) {
      SystemSound.play(SystemSoundType.click);
    }
  }

  /// Subtle feedback on brush stroke or slider adjustment
  static void playTick() {
    if (hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }
}
