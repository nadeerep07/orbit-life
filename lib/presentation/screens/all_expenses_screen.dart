import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../theme/app_theme.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/month_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import 'add_expense_screen.dart';

class AllExpensesScreen extends StatefulWidget {
  const AllExpensesScreen({super.key});

  @override
  State<AllExpensesScreen> createState() => _AllExpensesScreenState();
}

class _AllExpensesScreenState extends State<AllExpensesScreen> {
  String _searchQuery = '';
  String? _paymentFilter;
  String? _categoryFilter; // null = all categories
  DateTimeRange? _dateRange; // null = full month

  // ── active filter count badge ─────────────────────────────────
  int get _activeFilterCount {
    int count = 0;
    if (_paymentFilter != null && _paymentFilter != 'All') count++;
    if (_categoryFilter != null) count++;
    if (_dateRange != null) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _paymentFilter = null;
      _categoryFilter = null;
      _dateRange = null;
    });
  }

  // ── Filter bottom sheet ───────────────────────────────────────
  void _showFilterSheet(BuildContext context) {
    final budgetVM = context.read<BudgetViewModel>();
    final accountsVM = context.read<AccountsViewModel>();

    // temp copies for the sheet
    String? tempCategory = _categoryFilter;
    String? tempPayment = _paymentFilter;
    DateTimeRange? tempDateRange = _dateRange;

    final categories = budgetVM.categories;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ListView(
              controller: scrollCtrl,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Title row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Expenses',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setSheetState(() {
                          tempCategory = null;
                          tempPayment = null;
                          tempDateRange = null;
                        });
                      },
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
                const Divider(),

                // ── Category ─────────────────────────────────────
                const Text(
                  'Category',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: tempCategory == null,
                      onSelected: (_) =>
                          setSheetState(() => tempCategory = null),
                    ),
                    ...categories.map(
                      (cat) => FilterChip(
                        label: Text(cat.name),
                        selected: tempCategory == cat.id,
                        onSelected: (_) =>
                            setSheetState(() => tempCategory = cat.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Payment Method ────────────────────────────────
                const Text(
                  'Payment Method',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    FilterChip(
                      label: const Text('All'),
                      selected: tempPayment == null || tempPayment == 'All',
                      onSelected: (_) =>
                          setSheetState(() => tempPayment = null),
                    ),
                    FilterChip(
                      label: const Text('Savings'),
                      selected: tempPayment == 'savings',
                      onSelected: (_) =>
                          setSheetState(() => tempPayment = 'savings'),
                    ),
                    ...accountsVM.accounts.map(
                      (acc) => FilterChip(
                        label: Text(acc.name),
                        selected: tempPayment == acc.id,
                        onSelected: (_) =>
                            setSheetState(() => tempPayment = acc.id),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Date Range ────────────────────────────────────
                const Text(
                  'Date Range',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 12),
                    child: Icon(Icons.date_range),
                  ),
                  title: Text(
                    tempDateRange == null
                        ? 'All time'
                        : '${DateFormat('dd MMM').format(tempDateRange!.start)}  →  ${DateFormat('dd MMM').format(tempDateRange!.end)}',
                  ),
                  trailing: tempDateRange != null
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () =>
                              setSheetState(() => tempDateRange = null),
                        )
                      : const Padding(
                          padding: EdgeInsets.only(right: 12),
                          child: Icon(Icons.chevron_right),
                        ),
                  onTap: () async {
                    final now = DateTime.now();
                    final picked = await showDateRangePicker(
                      context: ctx,
                      firstDate: DateTime(2020),
                      lastDate: now.add(const Duration(days: 365)),
                      initialDateRange: tempDateRange,
                      builder: (ctx, child) =>
                          Theme(data: Theme.of(ctx), child: child!),
                    );
                    if (picked != null) {
                      setSheetState(() => tempDateRange = picked);
                    }
                  },
                ),
                const SizedBox(height: 28),

                // Apply button
                FilledButton(
                  onPressed: () {
                    setState(() {
                      _categoryFilter = tempCategory;
                      _paymentFilter = tempPayment;
                      _dateRange = tempDateRange;
                    });
                    Navigator.pop(ctx);
                  },
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Apply Filters',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final budgetVM = context.watch<BudgetViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final currentMonth = monthVM.currentMonth;

    var expenses = expenseVM.getExpensesForMonth(currentMonth);

    // Search
    if (_searchQuery.isNotEmpty) {
      expenses = expenses
          .where(
            (e) => e.description.toLowerCase().contains(
              _searchQuery.toLowerCase(),
            ),
          )
          .toList();
    }

    // Category filter
    if (_categoryFilter != null) {
      expenses = expenses
          .where((e) => e.categoryId == _categoryFilter)
          .toList();
    }

    // Payment / account filter
    if (_paymentFilter != null && _paymentFilter != 'All') {
      if (_paymentFilter == 'savings') {
        expenses = expenses.where((e) => e.isFromSavings).toList();
      } else {
        expenses = expenses
            .where((e) => !e.isFromSavings && e.accountId == _paymentFilter)
            .toList();
      }
    }

    // Date range filter
    if (_dateRange != null) {
      final start = _dateRange!.start;
      final end = _dateRange!.end.add(const Duration(days: 1));
      expenses = expenses
          .where(
            (e) =>
                e.date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                e.date.isBefore(end),
          )
          .toList();
    }

    final totalSpent = expenses.fold(0.0, (sum, e) => sum + e.amount);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('All Expenses'),
            Text(
              DateFormat('MMMM yyyy').format(currentMonth),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        actions: [
          // Filter button with badge
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter',
                onPressed: () => _showFilterSheet(context),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (_activeFilterCount > 0)
            IconButton(
              icon: const Icon(Icons.clear_all),
              tooltip: 'Clear filters',
              onPressed: _clearAllFilters,
            ),
          IconButton(
            icon: const Icon(Icons.add_circle, color: Colors.greenAccent),
            tooltip: 'Add Expense',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(
              context,
            ).colorScheme.primary.withValues(alpha: 0.05),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Text(
                      'Filtered Total',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_activeFilterCount > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '$_activeFilterCount filter${_activeFilterCount > 1 ? 's' : ''} active',
                          style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '$currencySymbol${totalSpent.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ],
            ),
          ),

          // Active filter chips
          if (_activeFilterCount > 0)
            _ActiveFilterBar(
              categoryFilter: _categoryFilter,
              paymentFilter: _paymentFilter,
              dateRange: _dateRange,
              budgetVM: budgetVM,
              accountsVM: context.watch<AccountsViewModel>(),
              onRemoveCategory: () => setState(() => _categoryFilter = null),
              onRemovePayment: () => setState(() => _paymentFilter = null),
              onRemoveDateRange: () => setState(() => _dateRange = null),
            ),

          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by description...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            ),
          ),

          // Expense list
          Expanded(
            child: expenses.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No expenses found.',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters or add a new expense.',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_activeFilterCount > 0)
                          FilledButton.tonal(
                            onPressed: _clearAllFilters,
                            child: const Text('Clear Filters'),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      final expense = expenses[index];
                      final catName = budgetVM.categories
                          .firstWhere(
                            (c) => c.id == expense.categoryId,
                            orElse: () => budgetVM.categories.first,
                          )
                          .name;

                      return Dismissible(
                        key: Key(expense.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.error,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        onDismissed: (_) {
                          _deleteExpense(context, expense);
                        },
                        child: IOSCard(
                          padding: const EdgeInsets.all(12),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.primary.withValues(alpha: 0.1),
                              child: Text(
                                catName.isNotEmpty
                                    ? catName[0].toUpperCase()
                                    : '?',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              expense.description.isNotEmpty
                                  ? expense.description
                                  : catName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 2),
                                Text(
                                  catName,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  DateFormat(
                                    'dd MMM, yyyy · hh:mm a',
                                  ).format(expense.date),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                if (expense.isFromSavings)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    margin: const EdgeInsets.only(top: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(
                                        alpha: 0.12,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'From Savings',
                                      style: TextStyle(
                                        color: Colors.green,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '$currencySymbol${expense.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => AddExpenseScreen(
                                          existingExpense: expense,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _deleteExpense(BuildContext context, expense) async {
    final expenseVM = context.read<ExpenseViewModel>();
    await expenseVM.deleteExpense(expense.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted successfully')),
      );
    }
  }
}

// ── Active filter chips row ─────────────────────────────────────
class _ActiveFilterBar extends StatelessWidget {
  final String? categoryFilter;
  final String? paymentFilter;
  final DateTimeRange? dateRange;
  final BudgetViewModel budgetVM;
  final AccountsViewModel accountsVM;
  final VoidCallback onRemoveCategory;
  final VoidCallback onRemovePayment;
  final VoidCallback onRemoveDateRange;

  const _ActiveFilterBar({
    required this.categoryFilter,
    required this.paymentFilter,
    required this.dateRange,
    required this.budgetVM,
    required this.accountsVM,
    required this.onRemoveCategory,
    required this.onRemovePayment,
    required this.onRemoveDateRange,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (categoryFilter != null) {
      final cat = budgetVM.categories.firstWhere(
        (c) => c.id == categoryFilter,
        orElse: () => budgetVM.categories.first,
      );
      chips.add(
        _Chip(
          label: cat.name,
          icon: Icons.label_outline,
          onDelete: onRemoveCategory,
        ),
      );
    }

    if (paymentFilter != null && paymentFilter != 'All') {
      final label = paymentFilter == 'savings'
          ? 'Savings'
          : accountsVM.accounts
                .firstWhere(
                  (a) => a.id == paymentFilter,
                  orElse: () => accountsVM.accounts.first,
                )
                .name;
      chips.add(
        _Chip(
          label: label,
          icon: Icons.account_balance_wallet_outlined,
          onDelete: onRemovePayment,
        ),
      );
    }

    if (dateRange != null) {
      chips.add(
        _Chip(
          label:
              '${DateFormat('dd MMM').format(dateRange!.start)} – ${DateFormat('dd MMM').format(dateRange!.end)}',
          icon: Icons.date_range,
          onDelete: onRemoveDateRange,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Wrap(spacing: 8, runSpacing: 4, children: chips),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onDelete;

  const _Chip({
    required this.label,
    required this.icon,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(
        icon,
        size: 14,
        color: Theme.of(context).colorScheme.primary,
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      deleteIcon: const Icon(Icons.close, size: 14),
      onDeleted: onDelete,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      backgroundColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.08),
      side: BorderSide(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      ),
    );
  }
}
