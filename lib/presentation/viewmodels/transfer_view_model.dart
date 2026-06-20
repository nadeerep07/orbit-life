import 'package:flutter/foundation.dart';
import '../../domain/entities/transfer_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transfer_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

class TransferViewModel extends ChangeNotifier {
  final TransferRepository _repository;
  final TransactionRepository _transactionRepository;

  List<TransferEntity> _transfers = [];
  bool _isLoading = false;

  TransferViewModel(this._repository, this._transactionRepository);

  List<TransferEntity> get transfers => _transfers;
  bool get isLoading => _isLoading;

  Future<void> loadTransfers() async {
    _isLoading = true;
    notifyListeners();

    _transfers = await _repository.getTransfers();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransfer(TransferEntity transfer) async {
    await _repository.addTransfer(transfer);
    _transfers.insert(0, transfer);

    final tx = TransactionEntity(
      id: transfer.id,
      amount: transfer.amount,
      type: TransactionType.transfer,
      accountId: transfer.fromAccountId,
      targetAccountId: transfer.toAccountId,
      categoryOrSource: 'Transfer',
      date: transfer.date,
      description: transfer.description,
      referenceId: transfer.id,
    );
    await _transactionRepository.addTransaction(tx);

    notifyListeners();
  }

  Future<void> updateTransfer(
    TransferEntity newTransfer,
    TransferEntity oldTransfer,
  ) async {
    await _repository.updateTransfer(newTransfer);
    final index = _transfers.indexWhere((t) => t.id == newTransfer.id);
    if (index != -1) {
      _transfers[index] = newTransfer;

      final tx = TransactionEntity(
        id: newTransfer.id,
        amount: newTransfer.amount,
        type: TransactionType.transfer,
        accountId: newTransfer.fromAccountId,
        targetAccountId: newTransfer.toAccountId,
        categoryOrSource: 'Transfer',
        date: newTransfer.date,
        description: newTransfer.description,
        referenceId: newTransfer.id,
      );
      await _transactionRepository.updateTransaction(tx);

      notifyListeners();
    }
  }

  Future<void> deleteTransfer(TransferEntity transfer) async {
    await _repository.deleteTransfer(transfer.id);
    _transfers.removeWhere((t) => t.id == transfer.id);

    await _transactionRepository.deleteTransaction(transfer.id);

    notifyListeners();
  }
}
