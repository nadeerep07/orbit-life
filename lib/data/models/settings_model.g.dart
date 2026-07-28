// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettingsModelAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 18;

  @override
  SettingsModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettingsModel(
      currencyCode: fields[0] as String,
      currencySymbol: fields[1] as String,
      monthlyBudgetLimit: fields[2] as double,
      categoryBudgets: (fields[3] as Map).cast<String, double>(),
      savingsGoal: fields[4] as double,
      emergencyFundGoal: fields[5] as double,
      enableNotifications: fields[6] as bool,
      backupFrequency: fields[7] as String,
      enableAutoAllocation: fields[8] as bool?,
      financialMode: fields[9] as String?,
      customModePriorities: (fields[10] as List?)?.cast<String>(),
      dailyLimitRollover: fields[11] as bool?,
      enableBiometrics: fields[12] as bool?,
      securityPin: fields[13] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.currencyCode)
      ..writeByte(1)
      ..write(obj.currencySymbol)
      ..writeByte(2)
      ..write(obj.monthlyBudgetLimit)
      ..writeByte(3)
      ..write(obj.categoryBudgets)
      ..writeByte(4)
      ..write(obj.savingsGoal)
      ..writeByte(5)
      ..write(obj.emergencyFundGoal)
      ..writeByte(6)
      ..write(obj.enableNotifications)
      ..writeByte(7)
      ..write(obj.backupFrequency)
      ..writeByte(8)
      ..write(obj.enableAutoAllocation)
      ..writeByte(9)
      ..write(obj.financialMode)
      ..writeByte(10)
      ..write(obj.customModePriorities)
      ..writeByte(11)
      ..write(obj.dailyLimitRollover)
      ..writeByte(12)
      ..write(obj.enableBiometrics)
      ..writeByte(13)
      ..write(obj.securityPin);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettingsModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
