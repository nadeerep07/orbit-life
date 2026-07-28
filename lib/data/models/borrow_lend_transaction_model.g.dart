// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'borrow_lend_transaction_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BorrowLendTransactionModelAdapter
    extends TypeAdapter<BorrowLendTransactionModel> {
  @override
  final int typeId = 16;

  @override
  BorrowLendTransactionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BorrowLendTransactionModel(
      id: fields[0] as String,
      amount: fields[1] as double,
      type: fields[2] as String,
      date: fields[3] as DateTime,
      accountId: fields[4] == null ? 'cash' : fields[4] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BorrowLendTransactionModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.accountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorrowLendTransactionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
