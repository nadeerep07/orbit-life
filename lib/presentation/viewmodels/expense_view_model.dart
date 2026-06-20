import 'package:flutter/material.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../../domain/repositories/transaction_repository.dart';

class ExpenseViewModel extends ChangeNotifier {
  final ExpenseRepository _expenseRepository;
  final TransactionRepository _transactionRepository;

  List<ExpenseEntity> _expenses = [];
  List<ExpenseEntity> get expenses => _expenses;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  ExpenseViewModel(this._expenseRepository, this._transactionRepository);

  Future<void> loadExpenses() async {
    _isLoading = true;
    notifyListeners();

    _expenses = await _expenseRepository.getExpenses();
    _expenses.sort((a, b) => b.date.compareTo(a.date));

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addExpense(ExpenseEntity expense) async {
    await _expenseRepository.addExpense(expense);

    final tx = TransactionEntity(
      id: expense.id,
      amount: expense.amount,
      type: TransactionType.expense,
      accountId: expense.accountId,
      categoryOrSource: 'Expense',
      date: expense.date,
      description: expense.description,
      referenceId: expense.id,
    );
    await _transactionRepository.addTransaction(tx);

    await loadExpenses();
  }

  Future<void> updateExpense(ExpenseEntity expense) async {
    await _expenseRepository.updateExpense(expense);

    final tx = TransactionEntity(
      id: expense.id,
      amount: expense.amount,
      type: TransactionType.expense,
      accountId: expense.accountId,
      categoryOrSource: 'Expense',
      date: expense.date,
      description: expense.description,
      referenceId: expense.id,
    );
    await _transactionRepository.updateTransaction(tx);

    await loadExpenses();
  }

  Future<void> deleteExpense(String id) async {
    await _expenseRepository.deleteExpense(id);
    await _transactionRepository.deleteTransaction(id);
    await loadExpenses();
  }

  List<ExpenseEntity> getExpensesForMonth(DateTime month) {
    return _expenses.where((e) => e.date.year == month.year && e.date.month == month.month).toList();
  }

  double getTotalSpentForCategoryInMonth(String categoryId, DateTime month) {
    final monthExpenses = getExpensesForMonth(month);
    return monthExpenses
        .where((e) => e.categoryId == categoryId)
        .fold(0.0, (sum, item) => sum + item.amount);
  }

  double getTotalSpentInMonth(DateTime month) {
    return getExpensesForMonth(month).fold(0.0, (sum, item) => sum + item.amount);
  }
}
