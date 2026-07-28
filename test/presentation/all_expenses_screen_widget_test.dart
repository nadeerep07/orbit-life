import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_budget_pro/domain/entities/expense_entity.dart';
import 'package:my_budget_pro/domain/entities/category_entity.dart';
import 'package:my_budget_pro/domain/entities/account_entity.dart';
import 'package:my_budget_pro/domain/entities/transaction_entity.dart';
import 'package:my_budget_pro/domain/repositories/expense_repository.dart';
import 'package:my_budget_pro/domain/repositories/category_repository.dart';
import 'package:my_budget_pro/domain/repositories/account_repository.dart';
import 'package:my_budget_pro/domain/repositories/transaction_repository.dart';
import 'package:my_budget_pro/presentation/viewmodels/expense_view_model.dart';
import 'package:my_budget_pro/presentation/viewmodels/budget_view_model.dart';
import 'package:my_budget_pro/presentation/viewmodels/month_view_model.dart';
import 'package:my_budget_pro/presentation/viewmodels/accounts_view_model.dart';
import 'package:my_budget_pro/presentation/viewmodels/theme_view_model.dart';
import 'package:my_budget_pro/presentation/screens/all_expenses_screen.dart';

class MockExpenseRepository implements ExpenseRepository {
  final List<ExpenseEntity> _expenses = [];
  @override
  Future<void> addExpense(ExpenseEntity expense) async => _expenses.add(expense);
  @override
  Future<void> deleteExpense(String id) async => _expenses.removeWhere((e) => e.id == id);
  @override
  Future<List<ExpenseEntity>> getExpenses() async => _expenses;
  @override
  Future<List<ExpenseEntity>> getExpensesByCategory(String categoryId) async =>
      _expenses.where((e) => e.categoryId == categoryId).toList();
  @override
  Future<List<ExpenseEntity>> getExpensesByMonth(DateTime month) async =>
      _expenses.where((e) => e.date.year == month.year && e.date.month == month.month).toList();
  @override
  Future<void> updateExpense(ExpenseEntity expense) async {
    final idx = _expenses.indexWhere((e) => e.id == expense.id);
    if (idx != -1) _expenses[idx] = expense;
  }
}

class MockCategoryRepository implements CategoryRepository {
  final List<CategoryEntity> _categories = [
    CategoryEntity(id: 'food', name: 'Food', monthlyBudget: 15000, month: DateTime.now().month, year: DateTime.now().year),
    CategoryEntity(id: 'shop', name: 'Shopping', monthlyBudget: 10000, month: DateTime.now().month, year: DateTime.now().year),
  ];
  @override
  Future<List<CategoryEntity>> getCategories() async => _categories;
  @override
  Future<void> addCategory(CategoryEntity category) async => _categories.add(category);
  @override
  Future<void> updateCategory(CategoryEntity category) async {}
  @override
  Future<void> deleteCategory(String id) async => _categories.removeWhere((c) => c.id == id);
}

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> _accounts = [
    const AccountEntity(id: 'sbi', name: 'SBI Bank', openingBalance: 50000),
  ];
  @override
  Future<List<AccountEntity>> getAccounts() async => _accounts;
  @override
  Future<void> addAccount(AccountEntity account) async => _accounts.add(account);
  @override
  Future<void> updateAccount(AccountEntity account) async {}
  @override
  Future<void> deleteAccount(String id) async => _accounts.removeWhere((a) => a.id == id);
  Future<void> updateBalance(String id, double delta) async {}
}

class MockTransactionRepository implements TransactionRepository {
  final List<TransactionEntity> _txs = [];
  @override
  Future<List<TransactionEntity>> getAllTransactions() async => _txs;
  @override
  Future<List<TransactionEntity>> getTransactionsByAccount(String accountId) async => [];
  @override
  Future<void> addTransaction(TransactionEntity transaction) async => _txs.add(transaction);
  @override
  Future<void> updateTransaction(TransactionEntity transaction) async {}
  @override
  Future<void> deleteTransaction(String transactionId) async {}
  @override
  Future<void> deleteTransactionsByReference(String referenceId) async {}
  @override
  Future<void> recalculateBalances() async {}
}

void main() {
  late MockExpenseRepository mockExpenseRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockAccountRepository mockAccountRepo;
  late MockTransactionRepository mockTxRepo;

  late ExpenseViewModel expenseVM;
  late BudgetViewModel budgetVM;
  late MonthViewModel monthVM;
  late AccountsViewModel accountsVM;
  late ThemeViewModel themeVM;

  setUp(() async {
    mockExpenseRepo = MockExpenseRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockAccountRepo = MockAccountRepository();
    mockTxRepo = MockTransactionRepository();

    expenseVM = ExpenseViewModel(mockExpenseRepo, mockTxRepo);
    budgetVM = BudgetViewModel(mockCategoryRepo);
    monthVM = MonthViewModel();
    accountsVM = AccountsViewModel(mockAccountRepo, mockTxRepo);
    themeVM = ThemeViewModel();

    await accountsVM.loadAccounts();
    await budgetVM.loadCategories(DateTime.now());
    await expenseVM.addExpense(
      ExpenseEntity(
        id: 'exp_1',
        categoryId: 'food',
        amount: 450,
        date: DateTime.now(),
        description: 'Dinner at Restaurant',
        accountId: 'sbi',
      ),
    );
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ExpenseViewModel>.value(value: expenseVM),
        ChangeNotifierProvider<BudgetViewModel>.value(value: budgetVM),
        ChangeNotifierProvider<MonthViewModel>.value(value: monthVM),
        ChangeNotifierProvider<AccountsViewModel>.value(value: accountsVM),
        ChangeNotifierProvider<ThemeViewModel>.value(value: themeVM),
      ],
      child: const MaterialApp(
        home: AllExpensesScreen(),
      ),
    );
  }

  group('AllExpensesScreen Widget Tests', () {
    testWidgets('Renders All Expenses title, summary card, and search input', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('All Expenses'), findsOneWidget);
      expect(find.text('FILTERED TOTAL'), findsOneWidget);
      expect(find.text('Dinner at Restaurant'), findsOneWidget);
      expect(find.text('Add Expense'), findsOneWidget);
    });

    testWidgets('Opens filter bottom sheet on filter action tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final filterBtn = find.byTooltip('Filter');
      expect(filterBtn, findsOneWidget);

      await tester.tap(filterBtn);
      await tester.pumpAndSettle();

      expect(find.text('FILTER EXPENSES'), findsOneWidget);
      expect(find.text('APPLY FILTERS', skipOffstage: false), findsOneWidget);
    });
  });
}
