import 'package:hive/hive.dart';
import '../models/credit_card_account_model.dart';
import '../models/fd_lot_model.dart';
import '../models/credit_card_statement_model.dart';
import '../models/cashback_transaction_model.dart';

import '../../../../core/services/cloud_sync_service.dart';

abstract class CreditCardLocalDataSource {
  Future<void> init();

  Future<CreditCardAccountModel?> getCreditCardAccount();
  Future<void> saveCreditCardAccount(CreditCardAccountModel account);

  Future<List<FdLotModel>> getFdLots();
  Future<void> addFdLot(FdLotModel lot);
  Future<void> updateFdLot(FdLotModel lot);

  Future<List<CreditCardStatementModel>> getStatements();
  Future<void> addStatement(CreditCardStatementModel statement);
  Future<void> updateStatement(CreditCardStatementModel statement);

  Future<List<CashbackTransactionModel>> getCashbackTransactions();
  Future<void> addCashbackTransaction(CashbackTransactionModel transaction);
  Future<void> updateCashbackTransaction(CashbackTransactionModel transaction);
}

class CreditCardLocalDataSourceImpl implements CreditCardLocalDataSource {
  late Box<CreditCardAccountModel> _accountBox;
  late Box<FdLotModel> _fdBox;
  late Box<CreditCardStatementModel> _statementBox;
  late Box<CashbackTransactionModel> _cashbackBox;

  @override
  Future<void> init() async {
    try {
      _accountBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
    } catch (_) {
      await Hive.deleteBoxFromDisk('credit_card_account_box');
      _accountBox = await Hive.openBox<CreditCardAccountModel>('credit_card_account_box');
    }

    try {
      _fdBox = await Hive.openBox<FdLotModel>('fd_lots_box');
    } catch (_) {
      await Hive.deleteBoxFromDisk('fd_lots_box');
      _fdBox = await Hive.openBox<FdLotModel>('fd_lots_box');
    }

    try {
      _statementBox = await Hive.openBox<CreditCardStatementModel>('credit_card_statements_box');
    } catch (_) {
      await Hive.deleteBoxFromDisk('credit_card_statements_box');
      _statementBox = await Hive.openBox<CreditCardStatementModel>('credit_card_statements_box');
    }

    try {
      _cashbackBox = await Hive.openBox<CashbackTransactionModel>('cashback_transactions_box');
    } catch (_) {
      await Hive.deleteBoxFromDisk('cashback_transactions_box');
      _cashbackBox = await Hive.openBox<CashbackTransactionModel>('cashback_transactions_box');
    }

    final ccBoxesToWatch = [_accountBox, _fdBox, _statementBox, _cashbackBox];
    for (var box in ccBoxesToWatch) {
      box.watch().listen((_) => CloudSyncService.triggerSync());
    }
  }

  @override
  Future<CreditCardAccountModel?> getCreditCardAccount() async {
    if (_accountBox.isEmpty) return null;
    return _accountBox.get('supermoney_account');
  }

  @override
  Future<void> saveCreditCardAccount(CreditCardAccountModel account) async {
    await _accountBox.put('supermoney_account', account);
  }

  @override
  Future<List<FdLotModel>> getFdLots() async {
    return _fdBox.values.toList();
  }

  @override
  Future<void> addFdLot(FdLotModel lot) async {
    await _fdBox.put(lot.id, lot);
  }

  @override
  Future<void> updateFdLot(FdLotModel lot) async {
    await _fdBox.put(lot.id, lot);
  }

  @override
  Future<List<CreditCardStatementModel>> getStatements() async {
    final list = _statementBox.values.toList();
    list.sort((a, b) => b.statementDate.compareTo(a.statementDate));
    return list;
  }

  @override
  Future<void> addStatement(CreditCardStatementModel statement) async {
    await _statementBox.put(statement.id, statement);
  }

  @override
  Future<void> updateStatement(CreditCardStatementModel statement) async {
    await _statementBox.put(statement.id, statement);
  }

  @override
  Future<List<CashbackTransactionModel>> getCashbackTransactions() async {
    final list = _cashbackBox.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<void> addCashbackTransaction(CashbackTransactionModel transaction) async {
    await _cashbackBox.put(transaction.id, transaction);
  }

  @override
  Future<void> updateCashbackTransaction(CashbackTransactionModel transaction) async {
    await _cashbackBox.put(transaction.id, transaction);
  }
}
