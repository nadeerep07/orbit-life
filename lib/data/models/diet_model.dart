import 'package:hive/hive.dart';
import '../../domain/entities/diet_entity.dart';

part 'diet_model.g.dart';

// -----------------------------------------------------------------
// DIET PROFILE MODEL (Hive Configs/Storage)
// -----------------------------------------------------------------
@HiveType(typeId: 11)
class DietProfileModel extends HiveObject {
  @HiveField(0)
  double weightKg;

  @HiveField(1)
  double heightCm;

  @HiveField(2)
  int age;

  @HiveField(3)
  String gender;

  @HiveField(4)
  String activityLevel;

  @HiveField(5)
  String goal;

  @HiveField(6)
  int dailyCalorieTarget;

  DietProfileModel({
    required this.weightKg,
    required this.heightCm,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dailyCalorieTarget,
  });

  factory DietProfileModel.fromEntity(DietProfileEntity entity) {
    return DietProfileModel(
      weightKg: entity.weightKg,
      heightCm: entity.heightCm,
      age: entity.age,
      gender: entity.gender,
      activityLevel: entity.activityLevel,
      goal: entity.goal,
      dailyCalorieTarget: entity.dailyCalorieTarget,
    );
  }

  DietProfileEntity toEntity() {
    return DietProfileEntity(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
      activityLevel: activityLevel,
      goal: goal,
      dailyCalorieTarget: dailyCalorieTarget,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weightKg': weightKg,
      'heightCm': heightCm,
      'age': age,
      'gender': gender,
      'activityLevel': activityLevel,
      'goal': goal,
      'dailyCalorieTarget': dailyCalorieTarget,
    };
  }

  factory DietProfileModel.fromJson(Map<String, dynamic> json) {
    return DietProfileModel(
      weightKg: (json['weightKg'] as num).toDouble(),
      heightCm: (json['heightCm'] as num).toDouble(),
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String,
      activityLevel: json['activityLevel'] as String,
      goal: json['goal'] as String,
      dailyCalorieTarget: (json['dailyCalorieTarget'] as num).toInt(),
    );
  }
}

// -----------------------------------------------------------------
// MEAL ENTRY MODEL
// -----------------------------------------------------------------
@HiveType(typeId: 12)
class MealEntryModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int calories;

  @HiveField(3)
  final double protein;

  @HiveField(4)
  final double carbs;

  @HiveField(5)
  final double fat;

  @HiveField(6)
  final DateTime date;

  @HiveField(7)
  final String mealType;

  MealEntryModel({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.date,
    required this.mealType,
  });

  factory MealEntryModel.fromEntity(MealEntryEntity entity) {
    return MealEntryModel(
      id: entity.id,
      name: entity.name,
      calories: entity.calories,
      protein: entity.protein,
      carbs: entity.carbs,
      fat: entity.fat,
      date: entity.date,
      mealType: entity.mealType,
    );
  }

  MealEntryEntity toEntity() {
    return MealEntryEntity(
      id: id,
      name: name,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      date: date,
      mealType: mealType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'date': date.toIso8601String(),
      'mealType': mealType,
    };
  }

  factory MealEntryModel.fromJson(Map<String, dynamic> json) {
    return MealEntryModel(
      id: json['id'] as String,
      name: json['name'] as String,
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      mealType: json['mealType'] as String,
    );
  }
}
