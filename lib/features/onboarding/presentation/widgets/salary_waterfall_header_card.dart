import 'package:flutter/material.dart';

class SalaryWaterfallHeaderCard extends StatelessWidget {
  final double totalIncome;
  final double totalEmis;
  final double monthlySavingsTarget;
  final double recurringExpenses;
  final String currentStepFocus; // 'income', 'emis', 'savings', 'expenses'

  const SalaryWaterfallHeaderCard({
    super.key,
    required this.totalIncome,
    required this.totalEmis,
    required this.monthlySavingsTarget,
    required this.recurringExpenses,
    required this.currentStepFocus,
  });

  @override
  Widget build(BuildContext context) {
    final remainingAfterEmis = (totalIncome - totalEmis).clamp(0.0, double.infinity);
    final remainingAfterSavings = (remainingAfterEmis - monthlySavingsTarget).clamp(0.0, double.infinity);
    final finalSpendableBalance = (remainingAfterSavings - recurringExpenses).clamp(0.0, double.infinity);

    final spendableRatio = totalIncome > 0 ? (finalSpendableBalance / totalIncome).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF151C2C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF26334D)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.waterfall_chart_rounded, color: Color(0xFF60A5FA), size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'SALARY WATERFALL FLOW',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF94A3B8),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF334155)),
                ),
                child: Text(
                  'Inflow: ₹${totalIncome.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF34D399)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Waterfall Steps Breakdown
          _buildWaterfallRow(
            title: '1. Monthly Salary / Income',
            amount: totalIncome,
            color: const Color(0xFF10B981),
            isHighlighted: currentStepFocus == 'income',
            icon: Icons.south_west_rounded,
          ),
          const SizedBox(height: 6),
          _buildWaterfallRow(
            title: '2. Priority 1: Fixed EMIs & Loans',
            amount: -totalEmis,
            color: const Color(0xFFEC4899),
            isHighlighted: currentStepFocus == 'emis',
            icon: Icons.receipt_long_rounded,
            subText: 'Deducted first from Salary (Left: ₹${remainingAfterEmis.toStringAsFixed(0)})',
          ),
          const SizedBox(height: 6),
          _buildWaterfallRow(
            title: '3. Priority 2: Monthly Savings Target',
            amount: -monthlySavingsTarget,
            color: const Color(0xFF60A5FA),
            isHighlighted: currentStepFocus == 'savings',
            icon: Icons.savings_rounded,
            subText: 'Saved for future wealth (Left: ₹${remainingAfterSavings.toStringAsFixed(0)})',
          ),
          const SizedBox(height: 6),
          _buildWaterfallRow(
            title: '4. Priority 3: Living Expenses',
            amount: -recurringExpenses,
            color: const Color(0xFFF59E0B),
            isHighlighted: currentStepFocus == 'expenses',
            icon: Icons.north_east_rounded,
            subText: 'Budgeted out of remaining cash flow',
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF26334D), height: 1),
          ),

          // Remaining Spendable Pool
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Available Spendable Living Fund',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      'Safe monthly operating budget',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 10, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '₹${finalSpendableBalance.toStringAsFixed(0)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: finalSpendableBalance > 0 ? const Color(0xFF34D399) : Colors.redAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Progress Ratio Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: spendableRatio,
              minHeight: 6,
              backgroundColor: const Color(0xFF0F172A),
              valueColor: AlwaysStoppedAnimation<Color>(
                finalSpendableBalance > 0 ? const Color(0xFF10B981) : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaterfallRow({
    required String title,
    required double amount,
    required Color color,
    required bool isHighlighted,
    required IconData icon,
    String? subText,
  }) {
    final amountStr = amount < 0 ? '-₹${amount.abs().toStringAsFixed(0)}' : '₹${amount.toStringAsFixed(0)}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isHighlighted ? color.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: isHighlighted ? Border.all(color: color.withValues(alpha: 0.4)) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(icon, size: 14, color: color),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w500,
                          color: isHighlighted ? Colors.white : Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                amountStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: amount < 0 ? color : const Color(0xFF34D399),
                ),
              ),
            ],
          ),
          if (subText != null && isHighlighted) ...[
            const SizedBox(height: 2),
            Text(
              subText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.9)),
            ),
          ],
        ],
      ),
    );
  }
}
