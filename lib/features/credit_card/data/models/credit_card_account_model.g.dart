// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credit_card_account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CreditCardAccountModelAdapter
    extends TypeAdapter<CreditCardAccountModel> {
  @override
  final int typeId = 21;

  @override
  CreditCardAccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CreditCardAccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      creditLimit: fields[2] as double,
      availableCredit: fields[3] as double,
      usedCredit: fields[4] as double,
      cashbackPending: fields[5] as double?,
      cashbackAvailable: fields[6] as double?,
      lifetimeCashback: fields[7] as double?,
      statementDateDay: fields[8] as int,
      dueDateDay: fields[9] as int,
      initialCreditMigrated: fields[10] as bool,
      lastUpdated: fields[11] as DateTime,
      cashbackRedeemed: fields[12] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, CreditCardAccountModel obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.creditLimit)
      ..writeByte(3)
      ..write(obj.availableCredit)
      ..writeByte(4)
      ..write(obj.usedCredit)
      ..writeByte(5)
      ..write(obj.cashbackPending)
      ..writeByte(6)
      ..write(obj.cashbackAvailable)
      ..writeByte(7)
      ..write(obj.lifetimeCashback)
      ..writeByte(8)
      ..write(obj.statementDateDay)
      ..writeByte(9)
      ..write(obj.dueDateDay)
      ..writeByte(10)
      ..write(obj.initialCreditMigrated)
      ..writeByte(11)
      ..write(obj.lastUpdated)
      ..writeByte(12)
      ..write(obj.cashbackRedeemed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CreditCardAccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
