import 'dart:math';
import '../../domain/entities/borrow_lend_entity.dart';
import '../../domain/entities/account_entity.dart';

class DebtRecommendation {
  final double minimumPayment;
  final double recommendedPayment;
  final double aggressivePayment;

  const DebtRecommendation({
    required this.minimumPayment,
    required this.recommendedPayment,
    required this.aggressivePayment,
  });
}

class DebtOptimizationEngine {
  static DebtRecommendation calculate({
    required List<BorrowLendEntity> borrowLends,
    required List<AccountEntity> accounts,
    required Map<String, double> accountBalances, // passing computed balances to avoid raw direct calculations
    required double incomeAmount,
    required double totalObligations,
  }) {
    double totalCreditCardDebt = 0.0;
    double totalBorrowedDebt = 0.0;
    double overdueBorrowedDebt = 0.0;

    // 1. Evaluate Credit Card accounts (negative balances or containing "credit card")
    for (final acc in accounts) {
      final balance = accountBalances[acc.id] ?? 0.0;
      final isCC = acc.name.toLowerCase().contains('credit') || acc.name.toLowerCase().contains('card');
      
      if (balance < 0.0) {
        totalCreditCardDebt += balance.abs();
      } else if (isCC && balance > 0.0) {
        // If CC has positive balance but is considered debt (some ledger entries write CC usage as positive balance liability)
        // Let's protect against different ledger mappings
        totalCreditCardDebt += balance;
      }
    }

    // 2. Evaluate pending borrowed records
    final now = DateTime.now();
    for (final bl in borrowLends) {
      if (bl.type == 'borrowed' && bl.status == 'pending') {
        final remaining = bl.remainingAmount;
        totalBorrowedDebt += remaining;

        if (bl.dueDate != null && bl.dueDate!.isBefore(now)) {
          overdueBorrowedDebt += remaining;
        }
      }
    }

    // Calculations:
    // Minimum Payment: 5% of CC debt + overdue borrowed debt + 5% of pending borrowed debt
    double minCC = totalCreditCardDebt * 0.05;
    double minBL = overdueBorrowedDebt + (totalBorrowedDebt - overdueBorrowedDebt) * 0.05;
    double minTotal = minCC + minBL;

    // Recommended Payment: 15% of CC debt + 25% of pending borrowed debt
    double recCC = totalCreditCardDebt * 0.15;
    double recBL = overdueBorrowedDebt + (totalBorrowedDebt - overdueBorrowedDebt) * 0.25;
    double recTotal = recCC + recBL;

    // Aggressive Payment: 35% of CC debt + 50% of pending borrowed debt
    double aggCC = totalCreditCardDebt * 0.35;
    double aggBL = overdueBorrowedDebt + (totalBorrowedDebt - overdueBorrowedDebt) * 0.50;
    double aggTotal = aggCC + aggBL;

    // Constrain by net capacity
    final double capacity = max(0.0, incomeAmount - totalObligations);
    
    // Minimum should at least represent critical overdue but capped at capacity
    minTotal = minTotal.clamp(0.0, capacity);
    recTotal = recTotal.clamp(minTotal, capacity);
    aggTotal = aggTotal.clamp(recTotal, capacity);

    return DebtRecommendation(
      minimumPayment: minTotal,
      recommendedPayment: recTotal,
      aggressivePayment: aggTotal,
    );
  }
}
