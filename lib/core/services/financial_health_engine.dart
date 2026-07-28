import 'dart:math';

class HealthReport {
  final int score;
  final double savingsRate;
  final double debtRatio;
  final double emergencyCoverage;
  final double budgetCompliance;
  final List<String> feedback;
  final List<String> improvements;

  const HealthReport({
    required this.score,
    required this.savingsRate,
    required this.debtRatio,
    required this.emergencyCoverage,
    required this.budgetCompliance,
    required this.feedback,
    required this.improvements,
  });
}

class FinancialHealthEngine {
  static HealthReport calculate({
    required double monthlyIncome,
    required double monthlyExpenses,
    required double outstandingDebt,
    required double currentEmergencyFund,
    required double targetEmergencyFund,
    required double totalBudgetLimit,
    required Map<String, double> categoryBudgets,
    required Map<String, double> categorySpent,
  }) {
    // 1. Savings Rate (Target: >= 20% of income)
    double savingsRate = 0.0;
    if (monthlyIncome > 0.0) {
      savingsRate = (monthlyIncome - monthlyExpenses) / monthlyIncome;
    }
    double savingsScore = 0.0;
    if (savingsRate >= 0.20) {
      savingsScore = 25.0;
    } else if (savingsRate > 0.0) {
      savingsScore = (savingsRate / 0.20) * 25.0;
    }

    // 2. Debt Ratio (Target: Debt Payments / Income < 30%)
    // Let's proxy with outstandingDebt relative to annual income, or just monthly debt payments if available.
    // Let's use Outstanding Debt vs Monthly Income: Target < 3x monthly income.
    double debtRatio = 0.0;
    if (monthlyIncome > 0.0) {
      debtRatio = outstandingDebt / monthlyIncome;
    }
    double debtScore = 25.0;
    if (debtRatio > 3.0) {
      debtScore = 0.0;
    } else if (debtRatio > 0.0) {
      debtScore = 25.0 - (debtRatio / 3.0) * 25.0;
    }

    // 3. Emergency Fund Coverage (Target: 100% of target fund goal)
    double emergencyFundCoverage = 0.0;
    if (targetEmergencyFund > 0.0) {
      emergencyFundCoverage = currentEmergencyFund / targetEmergencyFund;
    }
    double emergencyScore = min(20.0, emergencyFundCoverage * 20.0);

    // 4. Budget Compliance (Target: Spent <= Budget in each category)
    double complianceRatio = 1.0;
    if (categoryBudgets.isNotEmpty) {
      int compliantCount = 0;
      categoryBudgets.forEach((catId, limit) {
        final spent = categorySpent[catId] ?? 0.0;
        if (spent <= limit) {
          compliantCount++;
        }
      });
      complianceRatio = compliantCount / categoryBudgets.length;
    }
    double complianceScore = complianceRatio * 15.0;

    // 5. Cash Flow Stability (Outflow vs Inflow: Target monthlyExpenses < monthlyIncome)
    double cashFlowScore = 0.0;
    if (monthlyExpenses < monthlyIncome) {
      cashFlowScore = 15.0;
    } else if (monthlyExpenses == monthlyIncome) {
      cashFlowScore = 7.5;
    }

    // Aggregate Score
    final int finalScore = (savingsScore + debtScore + emergencyScore + complianceScore + cashFlowScore).round().clamp(0, 100);

    // Dynamic Feedback and Improvements
    final List<String> feedback = [];
    final List<String> improvements = [];

    if (finalScore >= 80) {
      feedback.add('Excellent financial health! You are managing allocation and saving effectively.');
    } else if (finalScore >= 50) {
      feedback.add('Moderate financial health. There are opportunities to improve debt reduction or savings.');
    } else {
      feedback.add('Critical financial state. High obligations or low savings are putting strain on cash flow.');
    }

    // Recommendations
    if (savingsRate < 0.10) {
      feedback.add('Savings rate is low (${(savingsRate * 100).toStringAsFixed(0)}%).');
      improvements.add('Consider switching to Growth Mode or raising your monthly savings allocation.');
    }
    if (debtRatio > 1.5) {
      feedback.add('Outstanding debt ratio is high compared to monthly salary.');
      improvements.add('We recommend activating Recovery Mode to focus surplus funds on debt payoff.');
    }
    if (emergencyFundCoverage < 0.5) {
      feedback.add('Emergency fund coverage is low (${(emergencyFundCoverage * 100).toStringAsFixed(0)}%).');
      improvements.add('Target setting aside extra cash specifically for the Emergency Fund.');
    }
    if (complianceRatio < 0.8) {
      feedback.add('Overspent in multiple category budgets.');
      improvements.add('Enable overspending alerts or lower variable budget limits.');
    }

    if (improvements.isEmpty) {
      improvements.add('Continue maintaining your current budgeting and savings discipline.');
    }

    return HealthReport(
      score: finalScore,
      savingsRate: savingsRate,
      debtRatio: debtRatio,
      emergencyCoverage: emergencyFundCoverage,
      budgetCompliance: complianceRatio,
      feedback: feedback,
      improvements: improvements,
    );
  }
}
