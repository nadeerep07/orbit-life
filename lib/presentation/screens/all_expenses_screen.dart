import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/responsive.dart';
import '../viewmodels/expense_view_model.dart';
import '../viewmodels/budget_view_model.dart';
import '../viewmodels/month_view_model.dart';
import '../viewmodels/accounts_view_model.dart';
import 'add_expense_screen.dart';
import '../widgets/custom_snackbar.dart';

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
                      'FILTER EXPENSES',
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
                    'APPLY FILTERS',
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

  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  IconData _getCategoryIcon(String catName) {
    final name = catName.toLowerCase();
    if (name.contains('food') || name.contains('eat') || name.contains('dining')) return Icons.restaurant_rounded;
    if (name.contains('transport') || name.contains('fuel') || name.contains('car')) return Icons.directions_car_rounded;
    if (name.contains('shop') || name.contains('cloth') || name.contains('fashion')) return Icons.shopping_bag_rounded;
    if (name.contains('health') || name.contains('medical') || name.contains('doctor')) return Icons.local_hospital_rounded;
    if (name.contains('entertainment') || name.contains('movie') || name.contains('fun')) return Icons.movie_rounded;
    if (name.contains('bill') || name.contains('util') || name.contains('electric')) return Icons.receipt_rounded;
    if (name.contains('grocery') || name.contains('supermarket')) return Icons.local_grocery_store_rounded;
    if (name.contains('travel') || name.contains('flight') || name.contains('hotel')) return Icons.flight_rounded;
    if (name.contains('invest') || name.contains('saving')) return Icons.savings_rounded;
    if (name.contains('edu') || name.contains('school') || name.contains('course')) return Icons.school_rounded;
    return Icons.payments_rounded;
  }

  // ── Build ─────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final expenseVM = context.watch<ExpenseViewModel>();
    final budgetVM = context.watch<BudgetViewModel>();
    final monthVM = context.watch<MonthViewModel>();
    final currentMonth = monthVM.currentMonth;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

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
    final r = Responsive(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            const Text('All Expenses', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
            Text(
              DateFormat('MMMM yyyy').format(currentMonth),
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.normal, color: Colors.grey),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.tune_rounded, size: 22),
                tooltip: 'Filter',
                onPressed: () => _showFilterSheet(context),
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$_activeFilterCount',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          if (_activeFilterCount > 0)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 20),
              tooltip: 'Clear filters',
              onPressed: _clearAllFilters,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpenseScreen())),
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Expense', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: r.contentMaxWidth),
          child: Column(
            children: [
              // ── Hero Summary Banner ───────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 8),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E2E), Color(0xFF2A2A3E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text(
                                'FILTERED TOTAL',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFF87171), letterSpacing: 1.1),
                              ),
                              if (_activeFilterCount > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF87171).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text('$_activeFilterCount Active', style: const TextStyle(fontSize: 10, color: Color(0xFFF87171), fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${expenses.length} Expense Record${expenses.length == 1 ? '' : 's'}',
                            style: const TextStyle(fontSize: 12, color: Colors.white70),
                          ),
                        ],
                      ),
                      Text(
                        '$currencySymbol${totalSpent == totalSpent.truncateToDouble() ? totalSpent.toStringAsFixed(0) : totalSpent.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFFF87171), letterSpacing: -0.5),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Active Filter Bar Chips ───────────────────────────────────
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

              // ── Search Input ─────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search expenses by description...',
                    hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade500),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.cancel_rounded, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Theme.of(context).cardColor,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(18),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),

              // ── Expense List ─────────────────────────────────────────────
              Expanded(
                child: expenseVM.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : expenses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_rounded, size: 54, color: Colors.grey.shade600),
                                const SizedBox(height: 14),
                                const Text('No expenses found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                                const SizedBox(height: 6),
                                Text('Try clearing filters or search query.', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                                const SizedBox(height: 16),
                                if (_activeFilterCount > 0)
                                  ElevatedButton.icon(
                                    onPressed: _clearAllFilters,
                                    icon: const Icon(Icons.filter_alt_off_rounded, size: 16),
                                    label: const Text('Clear Filters'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Theme.of(context).colorScheme.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                  ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: r.horizontalPadding, vertical: 8),
                            itemCount: expenses.length,
                            itemBuilder: (context, index) {
                              final expense = expenses[index];
                              final catName = budgetVM.categories.isEmpty
                                  ? expense.categoryId
                                  : budgetVM.categories
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
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.85),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                                ),
                                onDismissed: (_) => _deleteExpense(context, expense),
                                child: GestureDetector(
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => AddExpenseScreen(existingExpense: expense)),
                                  ),
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).cardColor,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.08)),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: isDarkMode ? 0.2 : 0.03),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEF4444).withValues(alpha: 0.10),
                                            borderRadius: BorderRadius.circular(16),
                                          ),
                                          child: Icon(_getCategoryIcon(catName), color: const Color(0xFFEF4444), size: 22),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                expense.description.isNotEmpty ? expense.description : catName,
                                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 3),
                                              Text(catName, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
                                              const SizedBox(height: 2),
                                              Text(
                                                DateFormat('dd MMM, yyyy · hh:mm a').format(expense.date),
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              if (expense.isFromSavings)
                                                Container(
                                                  margin: const EdgeInsets.only(top: 4),
                                                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.green.withValues(alpha: 0.12),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text('From Savings', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                                ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '- $currencySymbol${expense.amount == expense.amount.truncateToDouble() ? expense.amount.toStringAsFixed(0) : expense.amount.toStringAsFixed(2)}',
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
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
        ),
      ),
    );
  }

  void _deleteExpense(BuildContext context, expense) async {
    final expenseVM = context.read<ExpenseViewModel>();
    await expenseVM.deleteExpense(expense.id);

    if (mounted) {
      AppSnackBar.show(
        context,
        message: 'Expense deleted',
        isError: false,
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
