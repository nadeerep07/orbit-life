import 'package:flutter/foundation.dart';
import '../../domain/entities/mileage_entry_entity.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/mileage_repository.dart';
import 'expense_view_model.dart';
import 'accounts_view_model.dart';

class MileageViewModel extends ChangeNotifier {
  final MileageRepository _repository;
  final ExpenseViewModel _expenseViewModel;

  List<MileageEntryEntity> _entries = [];
  List<MileageEntryEntity> get entries => _entries;

  MileageViewModel(
    this._repository,
    this._expenseViewModel,
    AccountsViewModel? accountsViewModel,
  );

  Future<void> loadEntries() async {
    _entries = await _repository.getMileageEntries();
    // Sort descending by date (newest first)
    _entries.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> addEntry(MileageEntryEntity entry) async {
    // 1. Calculate distance & mileage based on previous entry
    final enrichedEntry = _calculateMileage(entry);

    // 2. Create linked Expense
    final linkedExpenseId = 'mileage_exp_${enrichedEntry.id}';

    // Find generic Category (assuming Petrol or Transportation exists)
    final expense = ExpenseEntity(
      id: linkedExpenseId,
      categoryId: _getPetrolCategoryId() ?? 'default',
      amount: enrichedEntry.totalCost,
      description:
          'Fuel Fill - Mileage Tracker ${enrichedEntry.notes.isNotEmpty ? "- ${enrichedEntry.notes}" : ""}',
      date: enrichedEntry.date,
      accountId: enrichedEntry.paymentMethodId,
      source: 'mileage_tracker',
    );

    // 3. Save Expense (automatically triggers transaction creation and balance deduction)
    await _expenseViewModel.addExpense(expense);

    // 4. Save enriched entry
    final finalizedEntry = MileageEntryEntity(
      id: enrichedEntry.id,
      date: enrichedEntry.date,
      odometerReading: enrichedEntry.odometerReading,
      petrolLitres: enrichedEntry.petrolLitres,
      pricePerLitre: enrichedEntry.pricePerLitre,
      totalCost: enrichedEntry.totalCost,
      distanceTravelled: enrichedEntry.distanceTravelled,
      mileage: enrichedEntry.mileage,
      paymentMethodId: enrichedEntry.paymentMethodId,
      notes: enrichedEntry.notes,
      linkedExpenseId: linkedExpenseId,
    );

    await _repository.addMileageEntry(finalizedEntry);
    await loadEntries();
  }

  Future<void> updateEntry(MileageEntryEntity updatedEntry) async {
    // 1. Fetch old entry to reverse expense effects
    final oldEntryIndex = _entries.indexWhere((e) => e.id == updatedEntry.id);
    if (oldEntryIndex == -1) return;
    final oldEntry = _entries[oldEntryIndex];

    // 2. Recalculate distance & mileage
    final enrichedEntry = _calculateMileage(updatedEntry);

    // 3. Update linked Expense
    final expenseIdToUpdate =
        oldEntry.linkedExpenseId ?? 'mileage_exp_${enrichedEntry.id}';

    final updatedExpense = ExpenseEntity(
      id: expenseIdToUpdate,
      categoryId: _getPetrolCategoryId() ?? 'default',
      amount: enrichedEntry.totalCost,
      description:
          'Fuel Fill - Mileage Tracker ${enrichedEntry.notes.isNotEmpty ? "- ${enrichedEntry.notes}" : ""}',
      date: enrichedEntry.date,
      accountId: enrichedEntry.paymentMethodId,
      source: 'mileage_tracker',
    );

    // Apply updated expense (automatically updates transaction and balance ledger)
    await _expenseViewModel.updateExpense(updatedExpense);

    final finalizedEntry = MileageEntryEntity(
      id: enrichedEntry.id,
      date: enrichedEntry.date,
      odometerReading: enrichedEntry.odometerReading,
      petrolLitres: enrichedEntry.petrolLitres,
      pricePerLitre: enrichedEntry.pricePerLitre,
      totalCost: enrichedEntry.totalCost,
      distanceTravelled: enrichedEntry.distanceTravelled,
      mileage: enrichedEntry.mileage,
      paymentMethodId: enrichedEntry.paymentMethodId,
      notes: enrichedEntry.notes,
      linkedExpenseId: expenseIdToUpdate,
    );

    await _repository.updateMileageEntry(finalizedEntry);
    await loadEntries();
  }

  Future<void> deleteEntry(String id) async {
    final entry = _entries.firstWhere((e) => e.id == id);

    // Delete linked expense (automatically deletes transaction and refunds balance)
    if (entry.linkedExpenseId != null) {
      await _expenseViewModel.deleteExpense(entry.linkedExpenseId!);
    }

    // Delete mileage entry
    await _repository.deleteMileageEntry(id);
    await loadEntries();
  }

  MileageEntryEntity _calculateMileage(MileageEntryEntity newEntry) {
    if (_entries.isEmpty) {
      return MileageEntryEntity(
        id: newEntry.id,
        date: newEntry.date,
        odometerReading: newEntry.odometerReading,
        petrolLitres: newEntry.petrolLitres,
        pricePerLitre: newEntry.pricePerLitre,
        totalCost: newEntry.totalCost,
        paymentMethodId: newEntry.paymentMethodId,
        notes: newEntry.notes,
        distanceTravelled: 0,
        mileage: 0,
        linkedExpenseId: newEntry.linkedExpenseId,
      );
    }

    final previousEntries = _entries
        .where((e) => e.date.isBefore(newEntry.date) && e.id != newEntry.id)
        .toList();
    previousEntries.sort((a, b) => b.date.compareTo(a.date));

    if (previousEntries.isEmpty) {
      return MileageEntryEntity(
        id: newEntry.id,
        date: newEntry.date,
        odometerReading: newEntry.odometerReading,
        petrolLitres: newEntry.petrolLitres,
        pricePerLitre: newEntry.pricePerLitre,
        totalCost: newEntry.totalCost,
        paymentMethodId: newEntry.paymentMethodId,
        notes: newEntry.notes,
        distanceTravelled: 0,
        mileage: 0,
        linkedExpenseId: newEntry.linkedExpenseId,
      );
    }

    final previousOdo = previousEntries.first.odometerReading;
    final distance = newEntry.odometerReading - previousOdo;

    double mileage = 0;
    if (newEntry.petrolLitres > 0 && distance > 0) {
      mileage = distance / newEntry.petrolLitres;
    }

    return MileageEntryEntity(
      id: newEntry.id,
      date: newEntry.date,
      odometerReading: newEntry.odometerReading,
      petrolLitres: newEntry.petrolLitres,
      pricePerLitre: newEntry.pricePerLitre,
      totalCost: newEntry.totalCost,
      paymentMethodId: newEntry.paymentMethodId,
      notes: newEntry.notes,
      distanceTravelled: distance > 0 ? distance : 0,
      mileage: mileage,
      linkedExpenseId: newEntry.linkedExpenseId,
    );
  }

  double get totalDistanceTravelled {
    return _entries.fold(
      0.0,
      (sum, item) => sum + (item.distanceTravelled ?? 0),
    );
  }

  double get totalPetrolUsed {
    return _entries.fold(0.0, (sum, item) => sum + item.petrolLitres);
  }

  double get totalPetrolCost {
    return _entries.fold(0.0, (sum, item) => sum + item.totalCost);
  }

  double get averageMileage {
    if (totalPetrolUsed == 0) return 0;
    return totalDistanceTravelled / totalPetrolUsed;
  }

  double get costPerKm {
    if (totalDistanceTravelled == 0) return 0;
    return totalPetrolCost / totalDistanceTravelled;
  }

  String? _getPetrolCategoryId() {
    return null;
  }
}
