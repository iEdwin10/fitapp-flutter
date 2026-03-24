import 'package:flutter/services.dart';

/// Multi-tone haptic system - Apple UIFeedbackGenerator inspired
class HapticService {
  HapticService._();

  // LIGHT - scroll, hover, soft select
  static Future<void> light() => HapticFeedback.lightImpact();

  // MEDIUM - button tap, card tap, navigation
  static Future<void> medium() => HapticFeedback.mediumImpact();

  // HEAVY - drag drop, delete, strong CTA
  static Future<void> heavy() => HapticFeedback.heavyImpact();

  // SELECTION - tab switch, picker scroll
  static Future<void> selection() => HapticFeedback.selectionClick();

  // SUCCESS - workout saved, playlist done
  // Pattern: medium -> 80ms -> heavy -> 50ms -> light
  static Future<void> success() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 80));
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 50));
    await HapticFeedback.lightImpact();
  }

  // TIMER END - countdown finished, recognisable even in pocket
  // Pattern: 3x heavy with increasing gap
  static Future<void> timerEnd() async {
    for (int i = 0; i < 3; i++) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(Duration(milliseconds: 80 + i * 40));
    }
  }

  // SERIES VALIDATED - satisfying medium + heavy double
  static Future<void> seriesValidated() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    await HapticFeedback.heavyImpact();
  }

  // ERROR - wrong action, freemium wall
  static Future<void> error() async {
    await HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    await HapticFeedback.heavyImpact();
  }

  // SWAP - machine occupee substitution
  static Future<void> swap() async {
    await HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    await HapticFeedback.mediumImpact();
  }
}
