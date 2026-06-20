import '../../domain/entities/emi_tracker_entity.dart';
import '../../domain/entities/settings_entity.dart';

class ObligationItem {
  final String title;
  final double amount;
  final String type; // 'EMI', 'Subscription', 'Rent', 'Utilities', etc.

  const ObligationItem({
    required this.title,
    required this.amount,
    required this.type,
  });
}

class ObligationAnalysis {
  final double totalObligations;
  final List<ObligationItem> obligations;

  const ObligationAnalysis({
    required this.totalObligations,
    required this.obligations,
  });
}

class ObligationAnalysisEngine {
  static ObligationAnalysis analyze({
    required List<EmiTrackerEntity> emis,
    required SettingsEntity settings,
  }) {
    final List<ObligationItem> items = [];

    // 1. Detect active monthly EMIs (where isPayLater is false and paidMonths < totalMonths)
    for (final emi in emis) {
      if (!emi.isPayLater && emi.paidMonths < emi.totalMonths) {
        items.add(
          ObligationItem(
            title: emi.title,
            amount: emi.monthlyEmi,
            type: 'EMI',
          ),
        );
      } else if (emi.isPayLater && !emi.isPaid) {
        // Pay later items due in current month can count as obligations
        final now = DateTime.now();
        if (emi.dueDate != null &&
            emi.dueDate!.year == now.year &&
            emi.dueDate!.month == now.month) {
          items.add(
            ObligationItem(
              title: emi.title,
              amount: emi.totalAmount,
              type: 'Pay Later',
            ),
          );
        }
      }
    }

    // 2. Include fixed category budgets (such as Rent, Utilities, Insurance if specified)
    // We inspect the category names in settings.categoryBudgets matching rent/util/insurance
    settings.categoryBudgets.forEach((categoryName, budget) {
      final nameLower = categoryName.toLowerCase();
      if (nameLower.contains('rent') ||
          nameLower.contains('utility') ||
          nameLower.contains('utilities') ||
          nameLower.contains('insurance') ||
          nameLower.contains('bill') ||
          nameLower.contains('subscription') ||
          nameLower.contains('tax')) {
        items.add(
          ObligationItem(
            title: categoryName,
            amount: budget,
            type: 'Fixed Expense',
          ),
        );
      }
    });

    final total = items.fold(0.0, (sum, item) => sum + item.amount);

    return ObligationAnalysis(
      totalObligations: total,
      obligations: items,
    );
  }
}
