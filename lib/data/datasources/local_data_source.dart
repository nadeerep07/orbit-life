import 'package:hive/hive.dart';
import '../models/category_model.dart';
import '../models/expense_model.dart';
import '../models/account_model.dart';
import '../models/savings_model.dart';
import '../models/income_model.dart';
import '../models/mileage_entry_model.dart';
import '../models/transfer_model.dart';
import '../models/goal_model.dart';
import '../models/service_model.dart';
import '../models/diet_model.dart';
import '../models/emi_tracker_model.dart';
import '../models/borrow_lend_model.dart';
import '../models/investment_model.dart';

abstract class LocalDataSource {
  Future<void> init();

  // Categories
  Future<List<CategoryModel>> getCategories();
  Future<void> addCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);

  // Expenses
  Future<List<ExpenseModel>> getExpenses();
  Future<void> addExpense(ExpenseModel expense);
  Future<void> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);

  // Accounts
  Future<List<AccountModel>> getAccounts();
  Future<void> addAccount(AccountModel account);
  Future<void> updateAccount(AccountModel account);
  Future<void> deleteAccount(String id);

  // Incomes
  Future<List<IncomeModel>> getIncomes();
  Future<void> addIncome(IncomeModel income);
  Future<void> updateIncome(IncomeModel income);
  Future<void> deleteIncome(String id);

  // Savings
  Future<SavingsModel?> getSavings();
  Future<void> updateSavings(SavingsModel savings);

  // Mileage
  Future<List<MileageEntryModel>> getMileageEntries();
  Future<void> addMileageEntry(MileageEntryModel entry);
  Future<void> updateMileageEntry(MileageEntryModel entry);
  Future<void> deleteMileageEntry(String id);

  // Transfers
  Future<List<TransferModel>> getTransfers();
  Future<void> addTransfer(TransferModel transfer);
  Future<void> updateTransfer(TransferModel transfer);
  Future<void> deleteTransfer(String id);

  // Goals
  Future<List<GoalModel>> getGoals();
  Future<void> addGoal(GoalModel goal);
  Future<void> updateGoal(GoalModel goal);
  Future<void> deleteGoal(String id);

  // Services
  Future<List<ServiceModel>> getServices();
  Future<void> addService(ServiceModel service);
  Future<void> updateService(ServiceModel service);
  Future<void> deleteService(String id);

  // Diet
  Future<DietProfileModel?> getDietProfile();
  Future<void> saveDietProfile(DietProfileModel profile);
  Future<List<MealEntryModel>> getMealEntries();
  Future<void> addMealEntry(MealEntryModel entry);
  Future<void> deleteMealEntry(String id);

  // EMI Tracker
  Future<List<EmiTrackerModel>> getEmis();
  Future<void> addEmi(EmiTrackerModel emi);
  Future<void> updateEmi(EmiTrackerModel emi);
  Future<void> deleteEmi(String id);

  // Borrow & Lend
  Future<List<BorrowLendModel>> getBorrowLends();
  Future<void> addBorrowLend(BorrowLendModel borrowLend);
  Future<void> updateBorrowLend(BorrowLendModel borrowLend);
  Future<void> deleteBorrowLend(String id);

  // Investments
  Future<List<InvestmentModel>> getInvestments();
  Future<void> addInvestment(InvestmentModel investment);
  Future<void> updateInvestment(InvestmentModel investment);
  Future<void> deleteInvestment(String id);
}

class HiveDataSourceImpl implements LocalDataSource {
  late Box<CategoryModel> _categoryBox;
  late Box<ExpenseModel> _expenseBox;
  late Box<AccountModel> _accountBox;
  late Box<SavingsModel> _savingsBox;
  late Box<IncomeModel> _incomeBox;
  late Box<MileageEntryModel> _mileageBox;
  late Box<TransferModel> _transferBox;
  late Box<GoalModel> _goalBox;
  late Box<ServiceModel> _serviceBox;
  late Box<DietProfileModel> _dietProfileBox;
  late Box<MealEntryModel> _mealEntryBox;
  late Box<EmiTrackerModel> _emiTrackerBox;
  late Box<BorrowLendModel> _borrowLendBox;
  late Box<InvestmentModel> _investmentBox;

  @override
  Future<void> init() async {
    _categoryBox = await Hive.openBox<CategoryModel>('categories');
    _expenseBox = await Hive.openBox<ExpenseModel>('expenses');
    _accountBox = await Hive.openBox<AccountModel>('accounts');
    _savingsBox = await Hive.openBox<SavingsModel>('savingsBox');
    _incomeBox = await Hive.openBox<IncomeModel>('incomeBox');
    _mileageBox = await Hive.openBox<MileageEntryModel>('mileageBox');
    _transferBox = await Hive.openBox<TransferModel>('transferBox');
    _goalBox = await Hive.openBox<GoalModel>('goalBox');
    _serviceBox = await Hive.openBox<ServiceModel>('serviceBox');
    _dietProfileBox = await Hive.openBox<DietProfileModel>('dietProfileBox');
    _mealEntryBox = await Hive.openBox<MealEntryModel>('mealEntryBox');
    _emiTrackerBox = await Hive.openBox<EmiTrackerModel>('emiTrackerBox');
    _borrowLendBox = await Hive.openBox<BorrowLendModel>('borrowLendBox');
    _investmentBox = await Hive.openBox<InvestmentModel>('investmentBox');

    // Initialize default categories if box is empty
    await _migrateLegacyCategories();
    await _migrateAccountsAndIncomes();
  }

  Future<void> _migrateAccountsAndIncomes() async {
    final settingsBox = await Hive.openBox('settingsBox');
    final bool hasMigrated = settingsBox.get(
      'migration_accounts_incomes_v1',
      defaultValue: false,
    );

    if (hasMigrated) return; // Already migrated

    // 1. Setup Default Accounts if not exists
    if (_accountBox.isEmpty) {
      final defaultAccounts = [
        AccountModel(id: 'sbi', name: 'SBI', openingBalance: 0),
        AccountModel(id: 'hdfc', name: 'HDFC', openingBalance: 0),
        AccountModel(
          id: 'airtel',
          name: 'Airtel Payment Bank',
          openingBalance: 0,
        ),
        AccountModel(
          id: 'supermoney',
          name: 'Super Money Credit Card',
          openingBalance: 0,
        ),
        AccountModel(id: 'cash', name: 'Cash', openingBalance: 0),
      ];
      for (var acc in defaultAccounts) {
        await _accountBox.put(acc.id, acc);
      }
    }

    // 2. Migrate existing expenses to 'cash' account if they don't have one
    final allExpenses = _expenseBox.values.toList();
    for (var expense in allExpenses) {
      // In Dart/Hive, adding a new field might make it null or empty string initially
      if (expense.accountId.isEmpty) {
        final updatedExpense = ExpenseModel(
          id: expense.id,
          categoryId: expense.categoryId,
          amount: expense.amount,
          description: expense.description,
          date: expense.date,
          accountId: 'cash', // Default to Cash
          isFromSavings: expense.isFromSavings,
        );
        await _expenseBox.put(updatedExpense.id, updatedExpense);
      }
    }

    await settingsBox.put('migration_accounts_incomes_v1', true);
  }

  Future<void> _migrateLegacyCategories() async {
    final settingsBox = await Hive.openBox('settingsBox');
    final bool hasMigrated = settingsBox.get(
      'migration_legacy_categories',
      defaultValue: false,
    );

    if (hasMigrated) return; // Already ran

    final allCategories = _categoryBox.values.toList();
    final legacyCategories = allCategories
        .where((c) => c.month == null || c.year == null)
        .toList();

    if (legacyCategories.isEmpty) {
      // Nothing to migrate, mark as done
      await settingsBox.put('migration_legacy_categories', true);
      return;
    }

    final allExpenses = _expenseBox.values.toList();

    // Find all unique (month, year) combos from expenses
    final Map<String, DateTime> uniqueMonths = {};
    for (var expense in allExpenses) {
      final key = '${expense.date.year}_${expense.date.month}';
      uniqueMonths[key] = DateTime(expense.date.year, expense.date.month);
    }

    // Always include current month just in case
    final now = DateTime.now();
    uniqueMonths['${now.year}_${now.month}'] = DateTime(now.year, now.month);

    // For every unique month and legacy category, clone the category into that month
    final Map<String, String> oldIdToNewIdMap = {}; // oldId_month_year -> newId

    for (var date in uniqueMonths.values) {
      for (var legacyCat in legacyCategories) {
        final newId = '${legacyCat.id}_${date.month}_${date.year}_migrated';

        final newCat = CategoryModel(
          id: newId,
          name: legacyCat.name,
          monthlyBudget: legacyCat.monthlyBudget,
          isCustom: legacyCat.isCustom,
          month: date.month,
          year: date.year,
        );

        await _categoryBox.put(newId, newCat);
        oldIdToNewIdMap['${legacyCat.id}_${date.month}_${date.year}'] = newId;
      }
    }

    // Update all expenses to point to the newly cloned monthly categories
    for (var expense in allExpenses) {
      // If the expense uses a legacy category, redirect it to the cloned monthly one
      final isLegacyCategory = legacyCategories.any(
        (c) => c.id == expense.categoryId,
      );
      if (isLegacyCategory) {
        final newCategoryId =
            oldIdToNewIdMap['${expense.categoryId}_${expense.date.month}_${expense.date.year}'];
        if (newCategoryId != null) {
          final updatedExpense = ExpenseModel(
            id: expense.id,
            categoryId: newCategoryId,
            amount: expense.amount,
            description: expense.description,
            date: expense.date,
            accountId: expense.accountId,
            isFromSavings: expense.isFromSavings,
          );
          await _expenseBox.put(updatedExpense.id, updatedExpense);
        }
      }
    }

    // Clean up original legacy categories
    for (var legacyCat in legacyCategories) {
      await _categoryBox.delete(legacyCat.id);
    }

    // Migration complete
    await settingsBox.put('migration_legacy_categories', true);
  }

  // --- Categories ---
  @override
  Future<List<CategoryModel>> getCategories() async {
    return _categoryBox.values.toList();
  }

  @override
  Future<void> addCategory(CategoryModel category) async {
    await _categoryBox.put(category.id, category);
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    await _categoryBox.put(category.id, category);
  }

  @override
  Future<void> deleteCategory(String id) async {
    await _categoryBox.delete(id);
  }

  // --- Expenses ---
  @override
  Future<List<ExpenseModel>> getExpenses() async {
    return _expenseBox.values.toList();
  }

  @override
  Future<void> addExpense(ExpenseModel expense) async {
    await _expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> updateExpense(ExpenseModel expense) async {
    await _expenseBox.put(expense.id, expense);
  }

  @override
  Future<void> deleteExpense(String id) async {
    await _expenseBox.delete(id);
  }

  // --- Accounts ---
  @override
  Future<List<AccountModel>> getAccounts() async {
    return _accountBox.values.toList();
  }

  @override
  Future<void> addAccount(AccountModel account) async {
    await _accountBox.put(account.id, account);
  }

  @override
  Future<void> updateAccount(AccountModel account) async {
    await _accountBox.put(account.id, account);
  }

  @override
  Future<void> deleteAccount(String id) async {
    await _accountBox.delete(id);
  }

  // --- Incomes ---
  @override
  Future<List<IncomeModel>> getIncomes() async {
    return _incomeBox.values.toList();
  }

  @override
  Future<void> addIncome(IncomeModel income) async {
    await _incomeBox.put(income.id, income);
  }

  @override
  Future<void> updateIncome(IncomeModel income) async {
    await _incomeBox.put(income.id, income);
  }

  @override
  Future<void> deleteIncome(String id) async {
    await _incomeBox.delete(id);
  }

  // --- Savings ---
  @override
  Future<SavingsModel?> getSavings() async {
    if (_savingsBox.isEmpty) return null;
    return _savingsBox.get('main_savings');
  }

  @override
  Future<void> updateSavings(SavingsModel savings) async {
    await _savingsBox.put('main_savings', savings);
  }

  // --- Mileage ---
  @override
  Future<List<MileageEntryModel>> getMileageEntries() async {
    return _mileageBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addMileageEntry(MileageEntryModel entry) async {
    await _mileageBox.put(entry.id, entry);
  }

  @override
  Future<void> updateMileageEntry(MileageEntryModel entry) async {
    await _mileageBox.put(entry.id, entry);
  }

  @override
  Future<void> deleteMileageEntry(String id) async {
    await _mileageBox.delete(id);
  }

  // --- Transfers ---
  @override
  Future<List<TransferModel>> getTransfers() async {
    return _transferBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addTransfer(TransferModel transfer) async {
    await _transferBox.put(transfer.id, transfer);
  }

  @override
  Future<void> updateTransfer(TransferModel transfer) async {
    await _transferBox.put(transfer.id, transfer);
  }

  @override
  Future<void> deleteTransfer(String id) async {
    await _transferBox.delete(id);
  }

  // --- Goals ---
  @override
  Future<List<GoalModel>> getGoals() async {
    return _goalBox.values.toList();
  }

  @override
  Future<void> addGoal(GoalModel goal) async {
    await _goalBox.put(goal.id, goal);
  }

  @override
  Future<void> updateGoal(GoalModel goal) async {
    await _goalBox.put(goal.id, goal);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _goalBox.delete(id);
  }

  // --- Services ---
  @override
  Future<List<ServiceModel>> getServices() async {
    return _serviceBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addService(ServiceModel service) async {
    await _serviceBox.put(service.id, service);
  }

  @override
  Future<void> updateService(ServiceModel service) async {
    await _serviceBox.put(service.id, service);
  }

  @override
  Future<void> deleteService(String id) async {
    await _serviceBox.delete(id);
  }

  // --- Diet ---
  @override
  Future<DietProfileModel?> getDietProfile() async {
    if (_dietProfileBox.isEmpty) return null;
    return _dietProfileBox.get('profile');
  }

  @override
  Future<void> saveDietProfile(DietProfileModel profile) async {
    await _dietProfileBox.put('profile', profile);
  }

  @override
  Future<List<MealEntryModel>> getMealEntries() async {
    return _mealEntryBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addMealEntry(MealEntryModel entry) async {
    await _mealEntryBox.put(entry.id, entry);
  }

  @override
  Future<void> deleteMealEntry(String id) async {
    await _mealEntryBox.delete(id);
  }

  // --- EMI Tracker ---
  @override
  Future<List<EmiTrackerModel>> getEmis() async {
    return _emiTrackerBox.values.toList();
  }

  @override
  Future<void> addEmi(EmiTrackerModel emi) async {
    await _emiTrackerBox.put(emi.id, emi);
  }

  @override
  Future<void> updateEmi(EmiTrackerModel emi) async {
    await _emiTrackerBox.put(emi.id, emi);
  }

  @override
  Future<void> deleteEmi(String id) async {
    await _emiTrackerBox.delete(id);
  }

  // --- Borrow & Lend ---
  @override
  Future<List<BorrowLendModel>> getBorrowLends() async {
    return _borrowLendBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addBorrowLend(BorrowLendModel borrowLend) async {
    await _borrowLendBox.put(borrowLend.id, borrowLend);
  }

  @override
  Future<void> updateBorrowLend(BorrowLendModel borrowLend) async {
    await _borrowLendBox.put(borrowLend.id, borrowLend);
  }

  @override
  Future<void> deleteBorrowLend(String id) async {
    await _borrowLendBox.delete(id);
  }

  // --- Investments ---
  @override
  Future<List<InvestmentModel>> getInvestments() async {
    return _investmentBox.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  @override
  Future<void> addInvestment(InvestmentModel investment) async {
    await _investmentBox.put(investment.id, investment);
  }

  @override
  Future<void> updateInvestment(InvestmentModel investment) async {
    await _investmentBox.put(investment.id, investment);
  }

  @override
  Future<void> deleteInvestment(String id) async {
    await _investmentBox.delete(id);
  }
}
