import 'dart:math';

class SpendableWallet {
  final double totalSpendableAmount;

  const SpendableWallet({required this.totalSpendableAmount});
}

class SpendableWalletEngine {
  static SpendableWallet calculate({
    required double incomeAmount,
    required double totalObligations,
    required double savingsAllocation,
    required double debtAllocation,
  }) {
    // Total Spendable = Income - Obligations - Savings - Debt
    final double balance = incomeAmount - totalObligations - savingsAllocation - debtAllocation;

    return SpendableWallet(
      totalSpendableAmount: max(0.0, balance),
    );
  }
}
