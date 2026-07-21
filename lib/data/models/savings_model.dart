import 'package:hive/hive.dart';
import '../../domain/entities/savings_entity.dart';

part 'savings_model.g.dart';

@HiveType(typeId: 3)
class SavingsModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  double totalAdded;

  @HiveField(2)
  double totalDebited;

  SavingsModel({
    required this.id,
    this.totalAdded = 0.0,
    this.totalDebited = 0.0,
  });

  factory SavingsModel.fromEntity(SavingsEntity entity) {
    return SavingsModel(
      id: entity.id,
      totalAdded: entity.totalAdded,
      totalDebited: entity.totalDebited,
    );
  }

  SavingsEntity toEntity() {
    return SavingsEntity(
      id: id,
      totalAdded: totalAdded,
      totalDebited: totalDebited,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'totalAdded': totalAdded, 'totalDebited': totalDebited};
  }

  factory SavingsModel.fromJson(Map<String, dynamic> json) {
    return SavingsModel(
      id: json['id'] as String,
      totalAdded: (json['totalAdded'] as num).toDouble(),
      totalDebited: (json['totalDebited'] as num).toDouble(),
    );
  }
}
