import 'package:hive/hive.dart';
import '../../domain/entities/category_entity.dart';

part 'category_model.g.dart';

@HiveType(typeId: 0)
class CategoryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final double monthlyBudget;

  @HiveField(3)
  final bool isCustom;

  @HiveField(4)
  final int? month;

  @HiveField(5)
  final int? year;

  CategoryModel({
    required this.id,
    required this.name,
    required this.monthlyBudget,
    this.isCustom = true,
    this.month,
    this.year,
  });

  factory CategoryModel.fromEntity(CategoryEntity entity) {
    return CategoryModel(
      id: entity.id,
      name: entity.name,
      monthlyBudget: entity.monthlyBudget,
      isCustom: entity.isCustom,
      month: entity.month,
      year: entity.year,
    );
  }

  CategoryEntity toEntity() {
    return CategoryEntity(
      id: id,
      name: name,
      monthlyBudget: monthlyBudget,
      isCustom: isCustom,
      month: month,
      year: year,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'monthlyBudget': monthlyBudget,
      'isCustom': isCustom,
      'month': month,
      'year': year,
    };
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      monthlyBudget: (json['monthlyBudget'] as num).toDouble(),
      isCustom: json['isCustom'] as bool? ?? true,
      month: json['month'] as int?,
      year: json['year'] as int?,
    );
  }
}
