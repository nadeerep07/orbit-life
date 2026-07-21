import 'package:hive/hive.dart';
import '../../domain/entities/service_entity.dart';

part 'service_model.g.dart';

@HiveType(typeId: 10)
class ServiceModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final DateTime date;

  @HiveField(3)
  final int mileageAtService;

  @HiveField(4)
  final double cost;

  @HiveField(5)
  final String notes;

  @HiveField(6)
  final DateTime? nextServiceDate;

  @HiveField(7)
  final int? nextServiceMileage;

  ServiceModel({
    required this.id,
    required this.title,
    required this.date,
    required this.mileageAtService,
    required this.cost,
    required this.notes,
    this.nextServiceDate,
    this.nextServiceMileage,
  });

  factory ServiceModel.fromEntity(ServiceEntity entity) {
    return ServiceModel(
      id: entity.id,
      title: entity.title,
      date: entity.date,
      mileageAtService: entity.mileageAtService,
      cost: entity.cost,
      notes: entity.notes,
      nextServiceDate: entity.nextServiceDate,
      nextServiceMileage: entity.nextServiceMileage,
    );
  }

  ServiceEntity toEntity() {
    return ServiceEntity(
      id: id,
      title: title,
      date: date,
      mileageAtService: mileageAtService,
      cost: cost,
      notes: notes,
      nextServiceDate: nextServiceDate,
      nextServiceMileage: nextServiceMileage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'date': date.toIso8601String(),
      'mileageAtService': mileageAtService,
      'cost': cost,
      'notes': notes,
      'nextServiceDate': nextServiceDate?.toIso8601String(),
      'nextServiceMileage': nextServiceMileage,
    };
  }

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(
      id: json['id'] as String,
      title: json['title'] as String,
      date: DateTime.parse(json['date'] as String),
      mileageAtService: (json['mileageAtService'] as num).toInt(),
      cost: (json['cost'] as num).toDouble(),
      notes: json['notes'] as String? ?? '',
      nextServiceDate: json['nextServiceDate'] != null ? DateTime.parse(json['nextServiceDate'] as String) : null,
      nextServiceMileage: (json['nextServiceMileage'] as num?)?.toInt(),
    );
  }
}
