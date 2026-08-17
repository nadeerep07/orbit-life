import 'package:equatable/equatable.dart';

class FinancialAnalysisResult extends Equatable {
  final int healthScore; // 0 to 100
  final double netWorth;
  final double totalLiquidCash;
  final double monthlyIncome;
  final double monthlyExpenses;
  final double monthlyEmis;
  final double monthlyFreeCash;
  final double debtToIncomeRatio; // percentage
  final double savingsRate; // percentage
  final double creditUtilizationRatio; // percentage
  final double emergencyFundCoverageMonths;
  final String riskLevel; // 'Low', 'Moderate', 'High'
  final Map<String, String> metricExplanations;

  const FinancialAnalysisResult({
    required this.healthScore,
    required this.netWorth,
    required this.totalLiquidCash,
    required this.monthlyIncome,
    required this.monthlyExpenses,
    required this.monthlyEmis,
    required this.monthlyFreeCash,
    required this.debtToIncomeRatio,
    required this.savingsRate,
    required this.creditUtilizationRatio,
    required this.emergencyFundCoverageMonths,
    required this.riskLevel,
    required this.metricExplanations,
  });

  @override
  List<Object?> get props => [
        healthScore,
        netWorth,
        totalLiquidCash,
        monthlyIncome,
        monthlyExpenses,
        monthlyEmis,
        monthlyFreeCash,
        debtToIncomeRatio,
        savingsRate,
        creditUtilizationRatio,
        emergencyFundCoverageMonths,
        riskLevel,
        metricExplanations,
      ];
}
