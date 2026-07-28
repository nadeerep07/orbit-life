import 'package:equatable/equatable.dart';

class SmartCategoryBudget extends Equatable {
  final String categoryId;
  final String categoryName;
  final double recommendedAmount;
  final double currentAmount;
  final String reasonExplanation;
  final double confidencePercentage;
  final bool isLocked;

  const SmartCategoryBudget({
    required this.categoryId,
    required this.categoryName,
    required this.recommendedAmount,
    this.currentAmount = 0.0,
    required this.reasonExplanation,
    this.confidencePercentage = 85.0,
    this.isLocked = false,
  });

  double get difference => recommendedAmount - currentAmount;

  SmartCategoryBudget copyWith({
    String? categoryId,
    String? categoryName,
    double? recommendedAmount,
    double? currentAmount,
    String? reasonExplanation,
    double? confidencePercentage,
    bool? isLocked,
  }) {
    return SmartCategoryBudget(
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      recommendedAmount: recommendedAmount ?? this.recommendedAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      reasonExplanation: reasonExplanation ?? this.reasonExplanation,
      confidencePercentage: confidencePercentage ?? this.confidencePercentage,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  @override
  List<Object?> get props => [
        categoryId,
        categoryName,
        recommendedAmount,
        currentAmount,
        reasonExplanation,
        confidencePercentage,
        isLocked,
      ];
}

class SmartBudgetResult extends Equatable {
  final List<SmartCategoryBudget> categoryBudgets;
  final double totalRecommendedBudget;
  final double totalIncome;
  final double totalFixedObligations;
  final double overallConfidence;

  const SmartBudgetResult({
    required this.categoryBudgets,
    required this.totalRecommendedBudget,
    required this.totalIncome,
    required this.totalFixedObligations,
    this.overallConfidence = 88.0,
  });

  @override
  List<Object?> get props => [
        categoryBudgets,
        totalRecommendedBudget,
        totalIncome,
        totalFixedObligations,
        overallConfidence,
      ];
}
