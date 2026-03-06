import 'package:flutter/foundation.dart';
import '../../domain/entities/emi_tracker_entity.dart';
import '../../domain/repositories/emi_tracker_repository.dart';
import 'accounts_view_model.dart';

class EmiTrackerViewModel extends ChangeNotifier {
  final EmiTrackerRepository _repository;

  List<EmiTrackerEntity> _emis = [];
  bool _isLoading = false;

  final AccountsViewModel _accountsViewModel;

  EmiTrackerViewModel(this._repository, this._accountsViewModel);

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
    // Note: We do NOT credit the account here.
    // EMIs are liabilities, not income. The account is debited only when
    // payments are made via markEmiPaid or markPayLaterPaid.
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
    // No balance adjustment needed on delete since we don't credit on create.
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
          accountId: emi
              .accountId, // ✅ preserve accountId so payments appear in account history
        );
        await updateEmi(updated);

        // Deduct EMI payment from account
        await _accountsViewModel.updateAccountBalance(
          emi.accountId,
          -emi.monthlyEmi,
        );
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
          accountId: emi
              .accountId, // ✅ preserve accountId so payment appears in account history
        );
        await updateEmi(updated);

        // Deduct settled amount from account
        await _accountsViewModel.updateAccountBalance(
          emi.accountId,
          -emi.totalAmount,
        );
      }
    }
  }
}
