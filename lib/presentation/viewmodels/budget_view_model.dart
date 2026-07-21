import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

class BudgetViewModel extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<CategoryEntity> _categories = [];
  List<CategoryEntity> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // Guards against concurrent seeding / reload loops
  bool _isLoadingInProgress = false;
  DateTime? _lastLoadedMonth;
  DateTime? get lastLoadedMonth => _lastLoadedMonth;

  BudgetViewModel(this._categoryRepository);

  Future<void> loadCategories(DateTime month) async {
    // Prevent concurrent overlapping loads for the same month
    if (_isLoadingInProgress) return;

    _isLoadingInProgress = true;
    _isLoading = true;
    // NOTE: Do NOT call notifyListeners() here to avoid triggering the
    // ProxyProvider update callback, which would call loadCategories() again.

    try {
      final allCategories = await _categoryRepository.getCategories();

      // Filter categories by month and year
      final monthCategories = allCategories.where((c) {
        if (c.month == null || c.year == null) return false;
        return c.month == month.month && c.year == month.year;
      }).toList();

      // Deduplicate by name (keep first, delete extras from DB)
      final uniqueCategoriesMap = <String, CategoryEntity>{};
      for (var cat in monthCategories) {
        final nameKey = cat.name.trim().toLowerCase();
        if (!uniqueCategoriesMap.containsKey(nameKey)) {
          uniqueCategoriesMap[nameKey] = cat;
        } else {
          await _categoryRepository.deleteCategory(cat.id);
        }
      }

      _categories = uniqueCategoriesMap.values.toList();

      // Seed defaults / copy from previous month only when completely empty
      if (_categories.isEmpty) {
        await _seedCategories(month, allCategories);
      }

      _lastLoadedMonth = month;
    } finally {
      _isLoading = false;
      _isLoadingInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _seedCategories(
    DateTime month,
    List<CategoryEntity> allCategories,
  ) async {
    final pastCategories = allCategories
        .where((c) => c.month != null && c.year != null)
        .toList();

    pastCategories.sort((a, b) {
      final dateA = DateTime(a.year!, a.month!);
      final dateB = DateTime(b.year!, b.month!);
      return dateB.compareTo(dateA);
    });

    List<CategoryEntity> sourceCategories;

    if (pastCategories.isNotEmpty) {
      final mostRecent = DateTime(
        pastCategories.first.year!,
        pastCategories.first.month!,
      );
      sourceCategories = pastCategories
          .where(
            (c) => c.month == mostRecent.month && c.year == mostRecent.year,
          )
          .toList();
    } else {
      sourceCategories = [
        const CategoryEntity(id: 'rent', name: 'Rent', monthlyBudget: 3000, isCustom: false),
        const CategoryEntity(id: 'food', name: 'Food', monthlyBudget: 7000, isCustom: false),
        const CategoryEntity(id: 'travel', name: 'Travel', monthlyBudget: 2000, isCustom: false),
        const CategoryEntity(id: 'petrol', name: 'Petrol', monthlyBudget: 3000, isCustom: false),
        const CategoryEntity(id: 'others', name: 'Others', monthlyBudget: 1000, isCustom: false),
      ];
    }

    // Re-check freshly from DB before writing — guards against concurrent seeding
    final freshDbCategories = await _categoryRepository.getCategories();
    final seededNames = freshDbCategories
        .where((c) => c.month == month.month && c.year == month.year)
        .map((c) => c.name.trim().toLowerCase())
        .toSet();

    final added = <CategoryEntity>[];
    for (var cat in sourceCategories) {
      final key = cat.name.trim().toLowerCase();
      if (!seededNames.contains(key)) {
        final newCat = CategoryEntity(
          id: '${cat.name.trim()}_${month.month}_${month.year}_${DateTime.now().millisecondsSinceEpoch}',
          name: cat.name.trim(),
          monthlyBudget: cat.monthlyBudget,
          isCustom: cat.isCustom,
          month: month.month,
          year: month.year,
        );
        await _categoryRepository.addCategory(newCat);
        seededNames.add(key); // prevent same-loop duplicates
        added.add(newCat);
      }
    }

    // Reload from DB to get authoritative final list
    final reloaded = await _categoryRepository.getCategories();
    _categories = reloaded.where((c) {
      if (c.month == null || c.year == null) return false;
      return c.month == month.month && c.year == month.year;
    }).toList();
  }

  Future<void> addCategory(String name, double budget, DateTime month) async {
    final cat = CategoryEntity(
      id: '${name.trim()}_${month.month}_${month.year}_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      monthlyBudget: budget,
      isCustom: true,
      month: month.month,
      year: month.year,
    );
    await _categoryRepository.addCategory(cat);
    _lastLoadedMonth = null; // force full reload
    await loadCategories(month);
  }

  Future<void> updateCategory(CategoryEntity category, DateTime month) async {
    await _categoryRepository.updateCategory(category);
    _lastLoadedMonth = null; // force full reload
    await loadCategories(month);
  }

  Future<void> deleteCategory(String id, DateTime month) async {
    await _categoryRepository.deleteCategory(id);
    _lastLoadedMonth = null; // force full reload
    await loadCategories(month);
  }
}
