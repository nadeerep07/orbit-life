// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'borrow_lend_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class BorrowLendModelAdapter extends TypeAdapter<BorrowLendModel> {
  @override
  final int typeId = 14;

  @override
  BorrowLendModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return BorrowLendModel(
      id: fields[0] as String,
      personName: fields[1] as String,
      phoneNumber: fields[2] as String,
      amount: fields[3] as double,
      type: fields[4] as String,
      date: fields[5] as DateTime,
      dueDate: fields[6] as DateTime?,
      note: fields[7] as String,
      status: fields[8] as String,
      accountId: fields[9] as String,
    );
  }

  @override
  void write(BinaryWriter writer, BorrowLendModel obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.personName)
      ..writeByte(2)
      ..write(obj.phoneNumber)
      ..writeByte(3)
      ..write(obj.amount)
      ..writeByte(4)
      ..write(obj.type)
      ..writeByte(5)
      ..write(obj.date)
      ..writeByte(6)
      ..write(obj.dueDate)
      ..writeByte(7)
      ..write(obj.note)
      ..writeByte(8)
      ..write(obj.status)
      ..writeByte(9)
      ..write(obj.accountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BorrowLendModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
