// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_statement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardStatementModelAdapter
    extends TypeAdapter<CreditCardStatementModel> {
  @override
  final int typeId = 22;

  @override
  CreditCardStatementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCardStatementModel(
      id: fields[0] as String,
      month: fields[1] as int,
      year: fields[2] as int,
      statementDate: fields[3] as DateTime,
      dueDate: fields[4] as DateTime,
      openingOutstanding: fields[5] as double,
      newPurchases: fields[6] as double,
      payments: fields[7] as double,
      adjustments: fields[8] as double,
      cashbackEarned: fields[9] as double,
      closingOutstanding: fields[10] as double,
      minimumDue: fields[11] as double,
      paidAmount: fields[12] as double,
      status: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardStatementModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.month)
      ..writeByte(2)
      ..write(obj.year)
      ..writeByte(3)
      ..write(obj.statementDate)
      ..writeByte(4)
      ..write(obj.dueDate)
      ..writeByte(5)
      ..write(obj.openingOutstanding)
      ..writeByte(6)
      ..write(obj.newPurchases)
      ..writeByte(7)
      ..write(obj.payments)
      ..writeByte(8)
      ..write(obj.adjustments)
      ..writeByte(9)
      ..write(obj.cashbackEarned)
      ..writeByte(10)
      ..write(obj.closingOutstanding)
      ..writeByte(11)
      ..write(obj.minimumDue)
      ..writeByte(12)
      ..write(obj.paidAmount)
      ..writeByte(13)
      ..write(obj.status);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardStatementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
