// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'emi_tracker_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EmiTrackerModelAdapter extends TypeAdapter<EmiTrackerModel> {
  @override
  final int typeId = 13;

  @override
  EmiTrackerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return EmiTrackerModel(
      id: fields[0] as String,
      title: fields[1] as String,
      provider: fields[2] as String,
      totalAmount: fields[3] == null ? 0.0 : fields[3] as double,
      monthlyEmi: fields[4] == null ? 0.0 : fields[4] as double,
      totalMonths: fields[5] == null ? 0 : fields[5] as int,
      paidMonths: fields[6] == null ? 0 : fields[6] as int,
      startDate: fields[7] as DateTime,
      notes: fields[8] as String,
      isPayLater: fields[9] == null ? false : fields[9] as bool,
      dueDate: fields[10] as DateTime?,
      isPaid: fields[11] == null ? false : fields[11] as bool,
      isReminderEnabled: fields[12] == null ? false : fields[12] as bool,
      accountId: fields[13] == null ? 'cash' : fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, EmiTrackerModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.provider)
      ..writeByte(3)
      ..write(obj.totalAmount)
      ..writeByte(4)
      ..write(obj.monthlyEmi)
      ..writeByte(5)
      ..write(obj.totalMonths)
      ..writeByte(6)
      ..write(obj.paidMonths)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.notes)
      ..writeByte(9)
      ..write(obj.isPayLater)
      ..writeByte(10)
      ..write(obj.dueDate)
      ..writeByte(11)
      ..write(obj.isPaid)
      ..writeByte(12)
      ..write(obj.isReminderEnabled)
      ..writeByte(13)
      ..write(obj.accountId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EmiTrackerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
