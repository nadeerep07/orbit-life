import 'package:hive/hive.dart';
import '../../domain/entities/borrow_lend_entity.dart';
import 'borrow_lend_transaction_model.dart';
part 'borrow_lend_model.g.dart';

@HiveType(typeId: 14)
class BorrowLendModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String personName;

  @HiveField(2)
  final String phoneNumber;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String type;

  @HiveField(5)
  final DateTime date;

  @HiveField(6)
  final DateTime? dueDate;

  @HiveField(7)
  final String note;

  @HiveField(8)
  final String status;

  @HiveField(9)
  final String accountId;

  @HiveField(10, defaultValue: [])
  final List<BorrowLendTransactionModel> transactions;

  BorrowLendModel({
    required this.id,
    required this.personName,
    required this.phoneNumber,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.note = '',
    required this.status,
    required this.accountId,
    this.transactions = const [],
  });

  factory BorrowLendModel.fromEntity(BorrowLendEntity entity) {
    return BorrowLendModel(
      id: entity.id,
      personName: entity.personName,
      phoneNumber: entity.phoneNumber,
      amount: entity.amount,
      type: entity.type,
      date: entity.date,
      dueDate: entity.dueDate,
      note: entity.note,
      status: entity.status,
      accountId: entity.accountId,
      transactions: entity.transactions
          .map((t) => BorrowLendTransactionModel.fromEntity(t))
          .toList(),
    );
  }

  BorrowLendEntity toEntity() {
    return BorrowLendEntity(
      id: id,
      personName: personName,
      phoneNumber: phoneNumber,
      amount: amount,
      type: type,
      date: date,
      dueDate: dueDate,
      note: note,
      status: status,
      accountId: accountId,
      transactions: transactions.map((t) => t.toEntity()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'personName': personName,
      'phoneNumber': phoneNumber,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
      'note': note,
      'status': status,
      'accountId': accountId,
      'transactions': transactions.map((t) => t.toJson()).toList(),
    };
  }

  factory BorrowLendModel.fromJson(Map<String, dynamic> json) {
    return BorrowLendModel(
      id: (json['id'] as String?) ?? '',
      personName: (json['personName'] as String?) ?? (json['to'] as String?) ?? 'Friend',
      phoneNumber: (json['phoneNumber'] as String?) ?? (json['contact'] as String?) ?? '',
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      type: (json['type'] as String?) ?? 'lend',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate'] as String) : null,
      note: (json['note'] as String?) ?? (json['notes'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      accountId: (json['accountId'] as String?) ?? 'cash',
      transactions: json['transactions'] != null
          ? (json['transactions'] as List)
              .map((t) => BorrowLendTransactionModel.fromJson(Map<String, dynamic>.from(t)))
              .toList()
          : [],
    );
  }
}
