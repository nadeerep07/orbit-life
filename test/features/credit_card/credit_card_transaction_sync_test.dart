import 'package:hive/hive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:my_budget_pro/domain/entities/transaction_entity.dart';
import 'package:my_budget_pro/features/credit_card/data/models/credit_card_account_model.dart';
import 'package:my_budget_pro/features/credit_card/data/datasources/credit_card_local_data_source.dart';
import 'package:my_budget_pro/data/datasources/local_data_source.dart';
import 'package:my_budget_pro/data/models/account_model.dart';
import 'package:my_budget_pro/data/models/transaction_model.dart';
import 'package:my_budget_pro/data/models/savings_model.dart';
import 'package:my_budget_pro/data/repositories/transaction_repository_impl.dart';

class FakeLocalDataSource implements LocalDataSource {
  final List<TransactionModel> transactions = [];
  final List<AccountModel> accounts = [
    AccountModel(id: 'supermoney', name: 'Credit Card', openingBalance: 6790.0),
    AccountModel(id: 'sbi', name: 'SBI', openingBalance: 10000.0),
  ];
  SavingsModel savings = SavingsModel(id: 'main_savings', totalAdded: 0, totalDebited: 0);

  @override
  Future<void> init() async {}

  @override
  Future<List<TransactionModel>> getTransactions() async => transactions;

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    transactions.removeWhere((t) => t.id == transaction.id);
    transactions.add(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    transactions.removeWhere((t) => t.id == id);
  }

  @override
  Future<List<AccountModel>> getAccounts() async => accounts;

  @override
  Future<void> updateAccount(AccountModel account) async {
    final idx = accounts.indexWhere((a) => a.id == account.id);
    if (idx != -1) accounts[idx] = account;
  }

  @override
  Future<SavingsModel?> getSavings() async => savings;

  @override
  Future<void> updateSavings(SavingsModel savings) async {
    this.savings = savings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeCreditCardLocalDataSource implements CreditCardLocalDataSource {
  CreditCardAccountModel? ccAccount = CreditCardAccountModel(
    id: 'supermoney',
    name: 'Credit Card',
    creditLimit: 21204.0,
    availableCredit: 6790.0,
    usedCredit: 14414.0,
    statementDateDay: 1,
    dueDateDay: 15,
    initialCreditMigrated: true,
    lastUpdated: DateTime.now(),
  );

  @override
  Future<void> init() async {}

  @override
  Future<CreditCardAccountModel?> getCreditCardAccount() async => ccAccount;

  @override
  Future<void> saveCreditCardAccount(CreditCardAccountModel account) async {
    ccAccount = account;
  }

  @override
  Stream<BoxEvent> watchCreditCardAccount() => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Credit Card Expense & Transaction Sync Tests', () {
    late FakeLocalDataSource localDS;
    late FakeCreditCardLocalDataSource ccLocalDS;
    late TransactionRepositoryImpl repo;

    setUp(() {
      localDS = FakeLocalDataSource();
      ccLocalDS = FakeCreditCardLocalDataSource();
      repo = TransactionRepositoryImpl(
        localDS,
        creditCardLocalDataSource: ccLocalDS,
      );
    });

    test('Adding credit card expense increases used credit and decreases available credit', () async {
      final tx = TransactionEntity(
        id: 'tx_1',
        amount: 500.0,
        type: TransactionType.expense,
        accountId: 'supermoney',
        categoryOrSource: 'Expense',
        date: DateTime.now(),
        description: 'Dinner',
        referenceId: 'ref_1',
      );

      await repo.addTransaction(tx);

      final cc = ccLocalDS.ccAccount!;
      expect(cc.usedCredit, equals(14914.0)); // 14414 + 500
      expect(cc.availableCredit, equals(6290.0)); // 21204 - 14914

      final superMoneyAccount = localDS.accounts.firstWhere((a) => a.id == 'supermoney');
      expect(superMoneyAccount.openingBalance, equals(6290.0));
    });

    test('Deleting credit card expense restores used credit and available credit', () async {
      final tx = TransactionEntity(
        id: 'tx_1',
        amount: 500.0,
        type: TransactionType.expense,
        accountId: 'supermoney',
        categoryOrSource: 'Expense',
        date: DateTime.now(),
        description: 'Dinner',
        referenceId: 'ref_1',
      );

      await repo.addTransaction(tx);
      expect(ccLocalDS.ccAccount!.usedCredit, equals(14914.0));

      await repo.deleteTransaction('tx_1');
      expect(ccLocalDS.ccAccount!.usedCredit, equals(14414.0));
      expect(ccLocalDS.ccAccount!.availableCredit, equals(6790.0));
    });

    test('Making credit card bill payment decreases used credit and increases available credit', () async {
      final tx = TransactionEntity(
        id: 'tx_pay_1',
        amount: 1000.0,
        type: TransactionType.transfer,
        accountId: 'sbi',
        targetAccountId: 'supermoney',
        categoryOrSource: 'Credit Card Bill Payment',
        date: DateTime.now(),
        description: 'Bill Pay',
        referenceId: 'cc_payment',
      );

      await repo.addTransaction(tx);

      final cc = ccLocalDS.ccAccount!;
      expect(cc.usedCredit, equals(13414.0)); // 14414 - 1000
      expect(cc.availableCredit, equals(7790.0)); // 21204 - 13414
    });
  });
}
