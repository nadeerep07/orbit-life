import 'dart:math';
import '../../domain/entities/settings_entity.dart';

class SavingsRecommendation {
  final double minimum;
  final double recommended;
  final double stretch;

  const SavingsRecommendation({
    required this.minimum,
    required this.recommended,
    required this.stretch,
  });
}

class SavingsRecommendationEngine {
  static SavingsRecommendation calculate({
    required double incomeAmount,
    required double totalObligations,
    required double outstandingDebt,
    required double currentSavings,
    required SettingsEntity settings,
  }) {
    final double netCapacity = max(0.0, incomeAmount - totalObligations);

    if (netCapacity <= 0.0) {
      return const SavingsRecommendation(minimum: 0.0, recommended: 0.0, stretch: 0.0);
    }

    // Evaluate emergency fund coverage multiplier (range 0.8 to 1.5)
    // If savings are far below the emergency goal, we boost savings recommendations.
    double emergencyMultiplier = 1.0;
    if (settings.emergencyFundGoal > 0.0) {
      final double progress = currentSavings / settings.emergencyFundGoal;
      if (progress < 0.2) {
        emergencyMultiplier = 1.4; // Very low savings -> save aggressively
      } else if (progress < 0.5) {
        emergencyMultiplier = 1.2;
      } else if (progress > 1.0) {
        emergencyMultiplier = 0.8; // Fully funded -> can save less
      }
    }

    // Evaluate debt multiplier (range 0.5 to 1.0)
    // If outstanding debt is very high relative to income, we scale back savings to prioritize debt payoff.
    double debtMultiplier = 1.0;
    if (incomeAmount > 0.0) {
      final double debtRatio = outstandingDebt / incomeAmount;
      if (debtRatio > 1.0) {
        debtMultiplier = 0.5; // High debt -> reduce savings rate
      } else if (debtRatio > 0.5) {
        debtMultiplier = 0.75;
      }
    }

    // Baseline rates of net capacity
    double minRate = 0.10; // 10% of net capacity
    double recRate = 0.20; // 20% of net capacity
    double strRate = 0.35; // 35% of net capacity

    // Adjust rates using our intelligence multipliers
    double calculatedMin = netCapacity * minRate * debtMultiplier;
    double calculatedRec = netCapacity * recRate * emergencyMultiplier * debtMultiplier;
    double calculatedStr = netCapacity * strRate * emergencyMultiplier;

    // Ensure within logical bounds
    calculatedMin = calculatedMin.clamp(0.0, netCapacity * 0.4);
    calculatedRec = calculatedRec.clamp(calculatedMin, netCapacity * 0.6);
    calculatedStr = calculatedStr.clamp(calculatedRec, netCapacity * 0.9);

    return SavingsRecommendation(
      minimum: calculatedMin,
      recommended: calculatedRec,
      stretch: calculatedStr,
    );
  }
}
