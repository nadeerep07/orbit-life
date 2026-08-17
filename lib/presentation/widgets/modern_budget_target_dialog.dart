import 'package:flutter/material.dart';
import '../../core/utils/currency_formatter.dart';

enum BudgetTargetType {
  monthlyBudget,
  savingsGoal,
  emergencyFund,
  categoryLimit,
}

class ModernBudgetTargetDialog extends StatefulWidget {
  final BudgetTargetType type;
  final double initialValue;
  final double? monthlyBudgetLimit; // For emergency fund & category insights
  final String? categoryName;
  final Future<void> Function(double newValue) onSave;

  const ModernBudgetTargetDialog({
    super.key,
    required this.type,
    required this.initialValue,
    this.monthlyBudgetLimit,
    this.categoryName,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    required BudgetTargetType type,
    required double initialValue,
    double? monthlyBudgetLimit,
    String? categoryName,
    required Future<void> Function(double newValue) onSave,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ModernBudgetTargetDialog(
        type: type,
        initialValue: initialValue,
        monthlyBudgetLimit: monthlyBudgetLimit,
        categoryName: categoryName,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ModernBudgetTargetDialog> createState() => _ModernBudgetTargetDialogState();
}

class _ModernBudgetTargetDialogState extends State<ModernBudgetTargetDialog> {
  late TextEditingController _controller;
  double _currentValue = 0.0;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.initialValue;
    _controller = TextEditingController(
      text: _currentValue > 0 ? _currentValue.toStringAsFixed(0) : '',
    );
    _controller.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final parsed = double.tryParse(_controller.text.replaceAll(',', '').trim()) ?? 0.0;
    if (parsed != _currentValue) {
      setState(() {
        _currentValue = parsed;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  void _addAmount(double increment) {
    final newAmount = _currentValue + increment;
    _controller.text = newAmount.toStringAsFixed(0);
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: _controller.text.length),
    );
  }

  String get _title {
    switch (widget.type) {
      case BudgetTargetType.monthlyBudget:
        return 'Monthly Budget Limit';
      case BudgetTargetType.savingsGoal:
        return 'Savings Target Goal';
      case BudgetTargetType.emergencyFund:
        return 'Emergency Fund Target';
      case BudgetTargetType.categoryLimit:
        return widget.categoryName != null
            ? 'Set Limit: ${widget.categoryName}'
            : 'Category Budget Limit';
    }
  }

  String get _subtitle {
    switch (widget.type) {
      case BudgetTargetType.monthlyBudget:
        return 'Cap total spending across all categories every month.';
      case BudgetTargetType.savingsGoal:
        return 'Set your desired monthly accumulation or long-term target.';
      case BudgetTargetType.emergencyFund:
        return 'Build a financial safety net for unexpected expenses.';
      case BudgetTargetType.categoryLimit:
        return 'Manage allocation for this specific expense category.';
    }
  }

  List<Color> get _gradientColors {
    switch (widget.type) {
      case BudgetTargetType.monthlyBudget:
        return const [Color(0xFF3B82F6), Color(0xFF1D4ED8)]; // Electric Blue
      case BudgetTargetType.savingsGoal:
        return const [Color(0xFF10B981), Color(0xFF047857)]; // Emerald Green
      case BudgetTargetType.emergencyFund:
        return const [Color(0xFFF59E0B), Color(0xFFD97706)]; // Warm Amber/Gold
      case BudgetTargetType.categoryLimit:
        return const [Color(0xFF8B5CF6), Color(0xFF6D28D9)]; // Deep Purple
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case BudgetTargetType.monthlyBudget:
        return Icons.account_balance_wallet_rounded;
      case BudgetTargetType.savingsGoal:
        return Icons.savings_rounded;
      case BudgetTargetType.emergencyFund:
        return Icons.verified_user_rounded;
      case BudgetTargetType.categoryLimit:
        return Icons.pie_chart_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: _gradientColors.first.withValues(alpha: isDark ? 0.25 : 0.15),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header Banner with Gradient Accent
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _gradientColors.first.withValues(alpha: 0.12),
                      _gradientColors.last.withValues(alpha: 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: _gradientColors.first.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(_icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            _subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Amount Input Container
                    Text(
                      'TARGET AMOUNT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBgColor,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: _gradientColors.first.withValues(alpha: 0.4),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: _gradientColors.first,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              autofocus: true,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: textPrimary,
                              ),
                              decoration: const InputDecoration(
                                hintText: '0',
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                          if (_controller.text.isNotEmpty)
                            IconButton(
                              icon: Icon(Icons.cancel_rounded, color: textSecondary, size: 20),
                              onPressed: () {
                                _controller.clear();
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Quick Preset Increments Chips
                    Text(
                      'QUICK ADD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildPresetChip('+₹1k', 1000, isDark, textPrimary, textSecondary),
                        _buildPresetChip('+₹5k', 5000, isDark, textPrimary, textSecondary),
                        _buildPresetChip('+₹10k', 10000, isDark, textPrimary, textSecondary),
                        _buildPresetChip('+₹25k', 25000, isDark, textPrimary, textSecondary),
                        _buildPresetChip('+₹50k', 50000, isDark, textPrimary, textSecondary),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Dynamic Insights Widget
                    _buildInsightCard(isDark, cardBgColor, borderColor, textPrimary, textSecondary),

                    const SizedBox(height: 24),

                    // Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: _isSaving ? null : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: _gradientColors,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: _gradientColors.first.withValues(alpha: 0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _handleSave,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Save Target',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetChip(
    String label,
    double value,
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    final chipBg = isDark ? const Color(0xFF334155).withValues(alpha: 0.6) : const Color(0xFFF1F5F9);

    return InkWell(
      onTap: () => _addAmount(value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: chipBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF475569) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    bool isDark,
    Color cardBgColor,
    Color borderColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    String insightTitle = '';
    String insightBody = '';
    IconData insightIcon = Icons.insights_rounded;

    if (widget.type == BudgetTargetType.monthlyBudget) {
      final dailyAvg = _currentValue / 30.0;
      insightTitle = 'Daily Allowance Insight';
      insightBody = 'Allows an average of ${CurrencyFormatter.format(dailyAvg)}/day over a 30-day month.';
      insightIcon = Icons.calendar_today_rounded;
    } else if (widget.type == BudgetTargetType.emergencyFund) {
      final monthlyRef = (widget.monthlyBudgetLimit != null && widget.monthlyBudgetLimit! > 0)
          ? widget.monthlyBudgetLimit!
          : 30000.0; // Default fallback estimate
      final monthsCovered = _currentValue / monthlyRef;
      insightTitle = 'Emergency Safety Runway';
      insightBody = 'Provides approx. ${monthsCovered.toStringAsFixed(1)} months of emergency expense coverage based on monthly limit (${CurrencyFormatter.format(monthlyRef)}).';
      insightIcon = Icons.shield_moon_rounded;
    } else if (widget.type == BudgetTargetType.savingsGoal) {
      insightTitle = 'Target Goal Value';
      insightBody = 'Target total savings: ${CurrencyFormatter.format(_currentValue)}. Helps auto-calculate financial wellness score.';
      insightIcon = Icons.auto_graph_rounded;
    } else {
      insightTitle = 'Category Allocation';
      insightBody = 'Allocates ${CurrencyFormatter.format(_currentValue)} specifically for this expense category.';
      insightIcon = Icons.pie_chart_outline_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(insightIcon, color: _gradientColors.first, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insightTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  insightBody,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: textSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSave() async {
    if (_currentValue < 0) return;

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(_currentValue);
      if (mounted) {
        Navigator.pop(context);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
