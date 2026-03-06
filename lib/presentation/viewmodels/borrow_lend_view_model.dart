import 'package:flutter/material.dart';
import '../../domain/entities/borrow_lend_transaction_entity.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import '../../domain/repositories/borrow_lend_repository.dart';
import '../../core/services/notification_service.dart';
import 'accounts_view_model.dart';
import 'package:uuid/uuid.dart';

class BorrowLendViewModel extends ChangeNotifier {
  final BorrowLendRepository _repository;
  final AccountsViewModel _accountsViewModel;

  List<BorrowLendEntity> _entries = [];
  List<BorrowLendEntity> get entries => _entries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BorrowLendViewModel(this._repository, this._accountsViewModel);

  Future<void> loadEntries() async {
    _isLoading = true;
    notifyListeners();

    _entries = await _repository.getBorrowLends();
    _entries.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEntry(BorrowLendEntity entry) async {
    await _repository.addBorrowLend(entry);

    double amountChange = entry.type == 'lent' ? -entry.amount : entry.amount;
    await _accountsViewModel.updateAccountBalance(
      entry.accountId,
      amountChange,
    );

    if (entry.status == 'pending' && entry.dueDate != null) {
      await _scheduleReminder(entry);
    }

    await loadEntries();
  }

  Future<void> markAsCompleted(
    BorrowLendEntity entry,
    String accountIdToUpdate,
  ) async {
    final updatedEntry = BorrowLendEntity(
      id: entry.id,
      personName: entry.personName,
      phoneNumber: entry.phoneNumber,
      amount: entry.amount,
      type: entry.type,
      date: entry.date,
      dueDate: entry.dueDate,
      note: entry.note,
      status: 'completed',
      accountId: accountIdToUpdate,
    );

    await _repository.updateBorrowLend(updatedEntry);

    double amountChange = entry.type == 'lent' ? entry.amount : -entry.amount;
    await _accountsViewModel.updateAccountBalance(
      accountIdToUpdate,
      amountChange,
    );

    await NotificationService().cancelNotification(entry.id.hashCode.abs());

    await loadEntries();
  }

  Future<void> deleteEntry(BorrowLendEntity entry) async {
    await _repository.deleteBorrowLend(entry.id);

    if (entry.status == 'pending') {
      double amountChange = entry.type == 'lent' ? entry.amount : -entry.amount;
      await _accountsViewModel.updateAccountBalance(
        entry.accountId,
        amountChange,
      );
    }

    await NotificationService().cancelNotification(entry.id.hashCode.abs());
    await loadEntries();
  }

  Future<void> updateEntry(BorrowLendEntity updatedEntry) async {
    await _repository.updateBorrowLend(updatedEntry);
    await loadEntries();
  }

  Future<void> addTransactionToEntry({
    required BorrowLendEntity entry,
    required double amountToPay,
    required String accountIdToUpdate,
    required DateTime date,
  }) async {
    final transactionType = entry.type == 'lent' ? 'received' : 'repaid';

    final newTransaction = BorrowLendTransactionEntity(
      id: const Uuid().v4(),
      amount: amountToPay,
      type: transactionType,
      date: date,
      accountId: accountIdToUpdate,
    );

    final updatedTransactions = List<BorrowLendTransactionEntity>.from(
      entry.transactions,
    )..add(newTransaction);

    final totalPaidAfterTrx = updatedTransactions.fold(
      0.0,
      (sum, t) => sum + t.amount,
    );
    final newStatus = totalPaidAfterTrx >= entry.amount
        ? 'completed'
        : entry.status;

    final updatedEntry = entry.copyWith(
      transactions: updatedTransactions,
      status: newStatus,
    );

    await _repository.updateBorrowLend(updatedEntry);

    double amountChange = entry.type == 'lent' ? amountToPay : -amountToPay;
    await _accountsViewModel.updateAccountBalance(
      accountIdToUpdate,
      amountChange,
    );

    if (newStatus == 'completed') {
      await NotificationService().cancelNotification(entry.id.hashCode.abs());
    }

    await loadEntries();
  }

  Future<void> _scheduleReminder(BorrowLendEntity entry) async {
    if (entry.dueDate == null) return;
    final id = entry.id.hashCode.abs();

    DateTime scheduleTime = entry.dueDate!.subtract(const Duration(days: 1));
    scheduleTime = DateTime(
      scheduleTime.year,
      scheduleTime.month,
      scheduleTime.day,
      10,
      0,
    );

    if (scheduleTime.isBefore(DateTime.now())) {
      scheduleTime = DateTime(
        entry.dueDate!.year,
        entry.dueDate!.month,
        entry.dueDate!.day,
        10,
        0,
      );
    }

    if (scheduleTime.isAfter(DateTime.now())) {
      String title = 'Reminder';
      String body = entry.type == 'lent'
          ? '${entry.personName} needs to repay ₹${entry.amount.toStringAsFixed(0)} tomorrow.'
          : 'You need to repay ${entry.personName} ₹${entry.amount.toStringAsFixed(0)} tomorrow.';

      await NotificationService().scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduleTime,
      );
    }
  }
}
