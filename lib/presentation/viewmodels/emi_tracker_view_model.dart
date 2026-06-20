import 'package:flutter/foundation.dart';
import '../../domain/entities/emi_tracker_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/emi_tracker_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

class EmiTrackerViewModel extends ChangeNotifier {
  final EmiTrackerRepository _repository;
  final TransactionRepository _transactionRepository;

  List<EmiTrackerEntity> _emis = [];
  bool _isLoading = false;

  EmiTrackerViewModel(this._repository, this._transactionRepository);

  List<EmiTrackerEntity> get emis => _emis;
  bool get isLoading => _isLoading;

  Future<void> loadEmis() async {
    _isLoading = true;
    notifyListeners();

    _emis = await _repository.getEmis();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addEmi(EmiTrackerEntity emi) async {
    await _repository.addEmi(emi);
    _emis.insert(0, emi);
    // EMIs are liabilities. Balance is debited only when installments are marked paid.
    notifyListeners();
  }

  Future<void> updateEmi(EmiTrackerEntity emi) async {
    await _repository.updateEmi(emi);
    final index = _emis.indexWhere((e) => e.id == emi.id);
    if (index != -1) {
      _emis[index] = emi;
      notifyListeners();
    }
  }

  Future<void> deleteEmi(String id) async {
    await _repository.deleteEmi(id);
    _emis.removeWhere((e) => e.id == id);

    // Recursively delete all payment transactions from this EMI to adjust balance and clear statement history
    await _transactionRepository.deleteTransactionsByReference(id);

    notifyListeners();
  }

  /// Mark one EMI installment as paid (EMI mode)
  Future<void> markEmiPaid(String id) async {
    final index = _emis.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emi = _emis[index];
      if (!emi.isPayLater && emi.paidMonths < emi.totalMonths) {
        final updated = EmiTrackerEntity(
          id: emi.id,
          title: emi.title,
          provider: emi.provider,
          totalAmount: emi.totalAmount,
          monthlyEmi: emi.monthlyEmi,
          totalMonths: emi.totalMonths,
          paidMonths: emi.paidMonths + 1,
          startDate: emi.startDate,
          notes: emi.notes,
          isPayLater: false,
          accountId: emi.accountId,
        );
        await updateEmi(updated);

        // Record installment payment transaction (debit from selected account)
        final tx = TransactionEntity(
          id: '${emi.id}_payment_${updated.paidMonths}',
          amount: emi.monthlyEmi,
          type: TransactionType.emi,
          accountId: emi.accountId,
          categoryOrSource: 'EMI - ${emi.title}',
          date: DateTime.now(),
          description: 'Installment ${updated.paidMonths} of ${emi.totalMonths}',
          referenceId: emi.id,
        );
        await _transactionRepository.addTransaction(tx);
      }
    }
  }

  /// Mark pay later entry as paid (Pay Later mode)
  Future<void> markPayLaterPaid(String id) async {
    final index = _emis.indexWhere((e) => e.id == id);
    if (index != -1) {
      final emi = _emis[index];
      if (emi.isPayLater && !emi.isPaid) {
        final updated = EmiTrackerEntity(
          id: emi.id,
          title: emi.title,
          provider: emi.provider,
          totalAmount: emi.totalAmount,
          startDate: emi.startDate,
          notes: emi.notes,
          isPayLater: true,
          dueDate: emi.dueDate,
          isPaid: true,
          accountId: emi.accountId,
        );
        await updateEmi(updated);

        // Record pay later settlement transaction
        final tx = TransactionEntity(
          id: '${emi.id}_paid',
          amount: emi.totalAmount,
          type: TransactionType.emi,
          accountId: emi.accountId,
          categoryOrSource: 'Pay Later - ${emi.provider}',
          date: emi.dueDate ?? DateTime.now(),
          description: 'Settled',
          referenceId: emi.id,
        );
        await _transactionRepository.addTransaction(tx);
      }
    }
  }
}
