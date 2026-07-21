import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:my_budget_pro/domain/entities/income_entity.dart';
import 'package:my_budget_pro/domain/entities/account_entity.dart';
import 'package:my_budget_pro/domain/entities/transaction_entity.dart';
import 'package:my_budget_pro/domain/repositories/income_repository.dart';
import 'package:my_budget_pro/domain/repositories/account_repository.dart';
import 'package:my_budget_pro/domain/repositories/transaction_repository.dart';
import 'package:my_budget_pro/presentation/viewmodels/income_view_model.dart';
import 'package:my_budget_pro/presentation/viewmodels/accounts_view_model.dart';
import 'package:my_budget_pro/presentation/viewmodels/theme_view_model.dart';
import 'package:my_budget_pro/presentation/screens/income_screen.dart';

class MockIncomeRepository implements IncomeRepository {
  final List<IncomeEntity> _incomes = [];

  @override
  Future<void> addIncome(IncomeEntity income) async {
    _incomes.add(income);
  }

  @override
  Future<void> deleteIncome(String id) async {
    _incomes.removeWhere((i) => i.id == id);
  }

  @override
  Future<List<IncomeEntity>> getIncomes() async => _incomes;

  @override
  Future<void> updateIncome(IncomeEntity income) async {
    final idx = _incomes.indexWhere((i) => i.id == income.id);
    if (idx != -1) _incomes[idx] = income;
  }
}

class MockAccountRepository implements AccountRepository {
  final List<AccountEntity> _accounts = [
    const AccountEntity(id: 'sbi', name: 'SBI Bank', openingBalance: 50000),
    const AccountEntity(id: 'hdfc', name: 'HDFC Bank', openingBalance: 25000),
  ];

  @override
  Future<List<AccountEntity>> getAccounts() async => _accounts;

  @override
  Future<void> addAccount(AccountEntity account) async => _accounts.add(account);

  @override
  Future<void> updateAccount(AccountEntity account) async {}

  @override
  Future<void> deleteAccount(String id) async => _accounts.removeWhere((a) => a.id == id);

  @override
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
  late MockIncomeRepository mockIncomeRepo;
  late MockAccountRepository mockAccountRepo;
  late MockTransactionRepository mockTxRepo;
  late IncomeViewModel incomeVM;
  late AccountsViewModel accountsVM;
  late ThemeViewModel themeVM;

  setUp(() async {
    mockIncomeRepo = MockIncomeRepository();
    mockAccountRepo = MockAccountRepository();
    mockTxRepo = MockTransactionRepository();

    incomeVM = IncomeViewModel(mockIncomeRepo, mockTxRepo);
    accountsVM = AccountsViewModel(mockAccountRepo, mockTxRepo);
    themeVM = ThemeViewModel();

    await accountsVM.loadAccounts();
    await incomeVM.addIncome(
      IncomeEntity(
        id: 'inc_1',
        source: 'Salary',
        description: 'July Salary Payment',
        amount: 50000,
        date: DateTime.now(),
        accountId: 'sbi',
      ),
    );
  });

  Widget buildTestableWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<IncomeViewModel>.value(value: incomeVM),
        ChangeNotifierProvider<AccountsViewModel>.value(value: accountsVM),
        ChangeNotifierProvider<ThemeViewModel>.value(value: themeVM),
      ],
      child: const MaterialApp(
        home: IncomeScreen(),
      ),
    );
  }

  group('IncomeScreen Widget Tests', () {
    testWidgets('Renders Income Tracker title and Total Monthly Income card', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      expect(find.text('Income Tracker'), findsOneWidget);
      expect(find.text('TOTAL MONTHLY INCOME'), findsOneWidget);
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Add Income'), findsOneWidget);
    });

    testWidgets('Opens Add Income bottom sheet on FAB tap', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestableWidget());
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      await tester.tap(fab);
      await tester.pumpAndSettle();

      expect(find.text('ADD INCOME RECORD'), findsOneWidget);
      expect(find.text('INCOME AMOUNT'), findsOneWidget);
      expect(find.text('CONTINUE & ALLOCATE INCOME'), findsOneWidget);
    });
  });
}
