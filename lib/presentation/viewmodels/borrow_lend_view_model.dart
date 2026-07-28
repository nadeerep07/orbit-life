import 'package:flutter/material.dart';
import '../../domain/entities/borrow_lend_transaction_entity.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/borrow_lend_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../core/services/notification_service.dart';
import '../../core/utils/currency_formatter.dart';
import 'package:uuid/uuid.dart';

class BorrowLendViewModel extends ChangeNotifier {
  final BorrowLendRepository _repository;
  final TransactionRepository _transactionRepository;

  List<BorrowLendEntity> _entries = [];
  List<BorrowLendEntity> get entries => _entries;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BorrowLendViewModel(this._repository, this._transactionRepository);

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

    final tx = TransactionEntity(
      id: entry.id,
      amount: entry.amount,
      type: entry.type == 'lent'
          ? TransactionType.lend
          : TransactionType.borrow,
      accountId: entry.accountId,
      categoryOrSource: entry.type == 'lent'
          ? 'Lent to ${entry.personName}'
          : 'Borrowed from ${entry.personName}',
      date: entry.date,
      description: entry.note,
      referenceId: entry.id,
    );
    await _transactionRepository.addTransaction(tx);

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
      transactions: entry.transactions, // Preserve partial transactions if any
    );

    await _repository.updateBorrowLend(updatedEntry);

    // Calculate remaining amount unpaid to close as a single complete payment
    final paidAmount = entry.transactions.fold(0.0, (sum, t) => sum + t.amount);
    final remainingAmount = entry.amount - paidAmount;

    if (remainingAmount > 0) {
      final tx = TransactionEntity(
        id: '${entry.id}_completion',
        amount: remainingAmount,
        type: entry.type == 'lent'
            ? TransactionType.income
            : TransactionType.expense,
        accountId: accountIdToUpdate,
        categoryOrSource: entry.type == 'lent'
            ? 'Repayment received from ${entry.personName}'
            : 'Repaid to ${entry.personName}',
        date: DateTime.now(),
        description: 'Fully Completed Settlement',
        referenceId: entry.id,
      );
      await _transactionRepository.addTransaction(tx);
    }

    await NotificationService().cancelNotification(entry.id.hashCode.abs());

    await loadEntries();
  }

  Future<void> deleteEntry(BorrowLendEntity entry) async {
    await _repository.deleteBorrowLend(entry.id);

    // Recursively delete all transactions (base + partial payments) associated with this borrow/lend
    await _transactionRepository.deleteTransactionsByReference(entry.id);

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

    // Record the partial payment transaction
    final tx = TransactionEntity(
      id: newTransaction.id,
      amount: amountToPay,
      type: entry.type == 'lent'
          ? TransactionType.income
          : TransactionType.expense,
      accountId: accountIdToUpdate,
      categoryOrSource: entry.type == 'lent'
          ? 'Repayment received from ${entry.personName}'
          : 'Repaid to ${entry.personName}',
      date: date,
      description: 'Partial repayment',
      referenceId: entry.id,
    );
    await _transactionRepository.addTransaction(tx);

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
          ? '${entry.personName} needs to repay $currencySymbol${entry.amount.toStringAsFixed(0)} tomorrow.'
          : 'You need to repay ${entry.personName} $currencySymbol${entry.amount.toStringAsFixed(0)} tomorrow.';

      await NotificationService().scheduleNotification(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduleTime,
      );
    }
  }
}
