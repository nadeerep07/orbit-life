import 'package:flutter/material.dart';
import '../../domain/entities/category_entity.dart';
import '../../domain/repositories/category_repository.dart';

class BudgetViewModel extends ChangeNotifier {
  final CategoryRepository _categoryRepository;

  List<CategoryEntity> _categories = [];
  List<CategoryEntity> get categories => _categories;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  BudgetViewModel(this._categoryRepository);

  Future<void> loadCategories(DateTime month) async {
    _isLoading = true;
    notifyListeners();

    final allCategories = await _categoryRepository.getCategories();

    // Filter categories by month and year
    _categories = allCategories.where((c) {
      if (c.month == null || c.year == null) return false;
      return c.month == month.month && c.year == month.year;
    }).toList();

    // Add defaults or copy from previous month if empty
    if (_categories.isEmpty) {
      // Find the most recent month we have categories for
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
        // Copy from the most recent month
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
        // Initial defaults
        sourceCategories = [
          const CategoryEntity(
            id: 'rent',
            name: 'Rent',
            monthlyBudget: 3000,
            isCustom: false,
          ),
          const CategoryEntity(
            id: 'food',
            name: 'Food',
            monthlyBudget: 7000,
            isCustom: false,
          ),
          const CategoryEntity(
            id: 'travel',
            name: 'Travel',
            monthlyBudget: 2000,
            isCustom: false,
          ),
          const CategoryEntity(
            id: 'petrol',
            name: 'Petrol',
            monthlyBudget: 3000,
            isCustom: false,
          ),
          const CategoryEntity(
            id: 'others',
            name: 'Others',
            monthlyBudget: 1000,
            isCustom: false,
          ),
        ];
      }

      final newCategories = <CategoryEntity>[];
      for (var cat in sourceCategories) {
        // Create a new instance for the new month with a new ID to avoid Hive primary key conflicts
        final newCat = CategoryEntity(
          id: '${cat.name}_${month.month}_${month.year}_${DateTime.now().millisecondsSinceEpoch}',
          name: cat.name,
          monthlyBudget: cat.monthlyBudget,
          isCustom: cat.isCustom,
          month: month.month,
          year: month.year,
        );
        await _categoryRepository.addCategory(newCat);
        newCategories.add(newCat);
      }
      _categories = newCategories;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> addCategory(String name, double budget, DateTime month) async {
    final cat = CategoryEntity(
      id: '${name}_${month.month}_${month.year}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      monthlyBudget: budget,
      isCustom: true,
      month: month.month,
      year: month.year,
    );
    await _categoryRepository.addCategory(cat);
    await loadCategories(month);
  }

  Future<void> updateCategory(CategoryEntity category, DateTime month) async {
    await _categoryRepository.updateCategory(category);
    await loadCategories(month);
  }

  Future<void> deleteCategory(String id, DateTime month) async {
    await _categoryRepository.deleteCategory(id);
    await loadCategories(month);
  }
}
