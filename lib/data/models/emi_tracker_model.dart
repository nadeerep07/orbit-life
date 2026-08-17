import 'package:hive/hive.dart';
import '../../domain/entities/emi_tracker_entity.dart';

part 'emi_tracker_model.g.dart';

@HiveType(typeId: 13)
class EmiTrackerModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String provider;

  @HiveField(3, defaultValue: 0.0)
  final double totalAmount;

  @HiveField(4, defaultValue: 0.0)
  final double monthlyEmi;

  @HiveField(5, defaultValue: 0)
  final int totalMonths;

  @HiveField(6, defaultValue: 0)
  final int paidMonths;

  @HiveField(7)
  final DateTime startDate;

  @HiveField(8)
  final String notes;

  @HiveField(9, defaultValue: false)
  final bool isPayLater;

  @HiveField(10)
  final DateTime? dueDate;

  @HiveField(11, defaultValue: false)
  final bool isPaid;

  @HiveField(12, defaultValue: false)
  final bool isReminderEnabled;

  @HiveField(13, defaultValue: 'cash')
  final String accountId;

  EmiTrackerModel({
    required this.id,
    required this.title,
    required this.provider,
    required this.totalAmount,
    this.monthlyEmi = 0,
    this.totalMonths = 0,
    this.paidMonths = 0,
    required this.startDate,
    this.notes = '',
    this.isPayLater = false,
    this.dueDate,
    this.isPaid = false,
    this.isReminderEnabled = false,
    this.accountId = 'cash',
  });

  factory EmiTrackerModel.fromEntity(EmiTrackerEntity entity) {
    return EmiTrackerModel(
      id: entity.id,
      title: entity.title,
      provider: entity.provider,
      totalAmount: entity.totalAmount,
      monthlyEmi: entity.monthlyEmi,
      totalMonths: entity.totalMonths,
      paidMonths: entity.paidMonths,
      startDate: entity.startDate,
      notes: entity.notes,
      isPayLater: entity.isPayLater,
      dueDate: entity.dueDate,
      isPaid: entity.isPaid,
      isReminderEnabled: entity.isReminderEnabled,
      accountId: entity.accountId,
    );
  }

  EmiTrackerEntity toEntity() {
    return EmiTrackerEntity(
      id: id,
      title: title,
      provider: provider,
      totalAmount: totalAmount,
      monthlyEmi: monthlyEmi,
      totalMonths: totalMonths,
      paidMonths: paidMonths,
      startDate: startDate,
      notes: notes,
      isPayLater: isPayLater,
      dueDate: dueDate,
      isPaid: isPaid,
      isReminderEnabled: isReminderEnabled,
      accountId: accountId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'provider': provider,
      'totalAmount': totalAmount,
      'monthlyEmi': monthlyEmi,
      'totalMonths': totalMonths,
      'paidMonths': paidMonths,
      'startDate': startDate.toIso8601String(),
      'notes': notes,
      'isPayLater': isPayLater,
      'dueDate': dueDate?.toIso8601String(),
      'isPaid': isPaid,
      'isReminderEnabled': isReminderEnabled,
      'accountId': accountId,
    };
  }

  factory EmiTrackerModel.fromJson(Map<String, dynamic> json) {
    return EmiTrackerModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? (json['loanName'] as String?) ?? (json['name'] as String?) ?? 'Loan',
      provider: (json['provider'] as String?) ?? 'Bank',
      totalAmount: ((json['totalAmount'] ?? 0) as num).toDouble(),
      monthlyEmi: ((json['monthlyEmi'] ?? json['amount'] ?? 0) as num).toDouble(),
      totalMonths: ((json['totalMonths'] ?? json['remainingMonths'] ?? json['months'] ?? 12) as num).toInt(),
      paidMonths: ((json['paidMonths'] ?? 0) as num).toInt(),
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate'] as String) : DateTime.now(),
      notes: (json['notes'] as String?) ?? '',
      isPayLater: (json['isPayLater'] as bool?) ?? false,
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      isPaid: (json['isPaid'] as bool?) ?? false,
      isReminderEnabled: (json['isReminderEnabled'] as bool?) ?? false,
      accountId: (json['accountId'] as String?) ?? 'cash',
    );
  }
}
