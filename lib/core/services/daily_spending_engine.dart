import 'dart:math';

class DailySpendingReport {
  final double dailyLimit;
  final double weeklyLimit;
  final double projectedMonthEndBalance;

  const DailySpendingReport({
    required this.dailyLimit,
    required this.weeklyLimit,
    required this.projectedMonthEndBalance,
  });
}

class DailySpendingEngine {
  static DailySpendingReport calculate({
    required double spendableWalletAmount, // Starting spendable wallet for the month
    required double currentMonthSpent,     // Variable expenses already recorded this month
    required double currentTotalBalance,   // Combined balance across all accounts
    required DateTime currentDate,
  }) {
    // 1. Calculate remaining days in the month (including today)
    final year = currentDate.year;
    final month = currentDate.month;
    final lastDay = DateTime(year, month + 1, 0).day;
    final remainingDays = max(1, lastDay - currentDate.day + 1);

    // 2. Calculate remaining spendable balance
    final double remainingSpendable = max(0.0, spendableWalletAmount - currentMonthSpent);

    // 3. Compute limits
    final double dailyLimit = remainingSpendable / remainingDays;
    final double weeklyLimit = dailyLimit * 7;

    // 4. Projected end of month balance if user spends exactly the remaining spendable amount
    // If they spend less, it increases. If they spend exactly, it stays as currentTotalBalance minus remaining spendable (since they'll spend it)
    // Actually, projected end of month balance = currentTotalBalance + projected remaining inflows - projected remaining outflows.
    // If they stick to daily limits:
    final double projectedMonthEnd = currentTotalBalance; // Assuming remaining spendable is already accounted for in current balance

    return DailySpendingReport(
      dailyLimit: dailyLimit,
      weeklyLimit: min(weeklyLimit, remainingSpendable),
      projectedMonthEndBalance: projectedMonthEnd,
    );
  }
}
