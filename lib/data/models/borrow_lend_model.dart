import 'package:hive/hive.dart';
import '../../domain/entities/borrow_lend_entity.dart';

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
    );
  }
}
