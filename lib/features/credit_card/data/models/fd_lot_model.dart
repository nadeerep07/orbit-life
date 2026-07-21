import 'package:hive/hive.dart';
import '../../domain/entities/fd_lot_entity.dart';

part 'fd_lot_model.g.dart';

@HiveType(typeId: 20)
class FdLotModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final double principal;

  @HiveField(2)
  double currentValue;

  @HiveField(3)
  final DateTime depositDate;

  @HiveField(4)
  final DateTime maturityDate;

  @HiveField(5)
  final DateTime lockUntil;

  @HiveField(6)
  final double interestRate;

  @HiveField(7)
  String status;

  @HiveField(8)
  bool autoRenew;

  @HiveField(9)
  List<DateTime> renewHistory;

  @HiveField(10)
  String remarks;

  FdLotModel({
    required this.id,
    required this.principal,
    required this.currentValue,
    required this.depositDate,
    required this.maturityDate,
    required this.lockUntil,
    this.interestRate = 6.0,
    required this.status,
    this.autoRenew = true,
    this.renewHistory = const [],
    this.remarks = '',
  });

  factory FdLotModel.fromEntity(FdLotEntity entity) {
    return FdLotModel(
      id: entity.id,
      principal: entity.principal,
      currentValue: entity.currentValue,
      depositDate: entity.depositDate,
      maturityDate: entity.maturityDate,
      lockUntil: entity.lockUntil,
      interestRate: entity.interestRate,
      status: entity.status.name,
      autoRenew: entity.autoRenew,
      renewHistory: entity.renewHistory,
      remarks: entity.remarks,
    );
  }

  FdLotEntity toEntity() {
    final parsedStatus = FdStatus.values.firstWhere(
      (e) => e.name == status,
      orElse: () => FdStatus.active,
    );
    return FdLotEntity(
      id: id,
      principal: principal,
      currentValue: currentValue,
      depositDate: depositDate,
      maturityDate: maturityDate,
      lockUntil: lockUntil,
      interestRate: interestRate,
      status: parsedStatus,
      autoRenew: autoRenew,
      renewHistory: renewHistory,
      remarks: remarks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'principal': principal,
      'currentValue': currentValue,
      'depositDate': depositDate.toIso8601String(),
      'maturityDate': maturityDate.toIso8601String(),
      'lockUntil': lockUntil.toIso8601String(),
      'interestRate': interestRate,
      'status': status,
      'autoRenew': autoRenew,
      'renewHistory': renewHistory.map((d) => d.toIso8601String()).toList(),
      'remarks': remarks,
    };
  }

  factory FdLotModel.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic d) {
      if (d is String) return DateTime.parse(d);
      if (d is DateTime) return d;
      try {
        return (d as dynamic).toDate();
      } catch (_) {}
      return DateTime.now();
    }
    return FdLotModel(
      id: json['id'] as String,
      principal: (json['principal'] as num).toDouble(),
      currentValue: (json['currentValue'] as num).toDouble(),
      depositDate: parseDate(json['depositDate']),
      maturityDate: parseDate(json['maturityDate']),
      lockUntil: parseDate(json['lockUntil']),
      interestRate: json['interestRate'] != null ? (json['interestRate'] as num).toDouble() : 6.0,
      status: json['status'] as String,
      autoRenew: (json['autoRenew'] as bool?) ?? true,
      renewHistory: json['renewHistory'] != null
          ? (json['renewHistory'] as List).map((d) => parseDate(d)).toList()
          : [],
      remarks: (json['remarks'] as String?) ?? '',
    );
  }
}
