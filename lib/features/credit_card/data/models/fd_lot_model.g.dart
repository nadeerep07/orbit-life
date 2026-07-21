// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fd_lot_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class FdLotModelAdapter extends TypeAdapter<FdLotModel> {
  @override
  final int typeId = 20;

  @override
  FdLotModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return FdLotModel(
      id: fields[0] as String,
      principal: fields[1] as double,
      currentValue: fields[2] as double,
      depositDate: fields[3] as DateTime,
      maturityDate: fields[4] as DateTime,
      lockUntil: fields[5] as DateTime,
      interestRate: fields[6] as double,
      status: fields[7] as String,
      autoRenew: fields[8] as bool,
      renewHistory: (fields[9] as List).cast<DateTime>(),
      remarks: fields[10] as String,
    );
  }

  @override
  void write(BinaryWriter writer, FdLotModel obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.principal)
      ..writeByte(2)
      ..write(obj.currentValue)
      ..writeByte(3)
      ..write(obj.depositDate)
      ..writeByte(4)
      ..write(obj.maturityDate)
      ..writeByte(5)
      ..write(obj.lockUntil)
      ..writeByte(6)
      ..write(obj.interestRate)
      ..writeByte(7)
      ..write(obj.status)
      ..writeByte(8)
      ..write(obj.autoRenew)
      ..writeByte(9)
      ..write(obj.renewHistory)
      ..writeByte(10)
      ..write(obj.remarks);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FdLotModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
