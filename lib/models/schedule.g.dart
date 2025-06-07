// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ScheduleAdapter extends TypeAdapter<Schedule> {
  @override
  final int typeId = 9;

  @override
  Schedule read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Schedule(
      id: fields[0] as int,
      name: fields[1] as String,
      description: fields[2] as String,
      scheduleType: fields[3] as ScheduleType,
      data: (fields[4] as List?)?.cast<Expense2>(),
      hour: fields[5] as int,
      minute: fields[6] as int,
      repeatOption: fields[7] as RepeatOption,
      customDays: (fields[8] as List?)?.cast<int>(),
      isActive: fields[9] as bool,
      lastTriggeredTime: fields[10] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Schedule obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.scheduleType)
      ..writeByte(4)
      ..write(obj.data)
      ..writeByte(5)
      ..write(obj.hour)
      ..writeByte(6)
      ..write(obj.minute)
      ..writeByte(7)
      ..write(obj.repeatOption)
      ..writeByte(8)
      ..write(obj.customDays)
      ..writeByte(9)
      ..write(obj.isActive)
      ..writeByte(10)
      ..write(obj.lastTriggeredTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ScheduleTypeAdapter extends TypeAdapter<ScheduleType> {
  @override
  final int typeId = 7;

  @override
  ScheduleType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ScheduleType.Reminder;
      case 1:
        return ScheduleType.AutoExpense;
      default:
        return ScheduleType.Reminder;
    }
  }

  @override
  void write(BinaryWriter writer, ScheduleType obj) {
    switch (obj) {
      case ScheduleType.Reminder:
        writer.writeByte(0);
        break;
      case ScheduleType.AutoExpense:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScheduleTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class RepeatOptionAdapter extends TypeAdapter<RepeatOption> {
  @override
  final int typeId = 8;

  @override
  RepeatOption read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return RepeatOption.Once;
      case 1:
        return RepeatOption.Everyday;
      case 2:
        return RepeatOption.Weekdays;
      case 3:
        return RepeatOption.Weekends;
      case 4:
        return RepeatOption.CustomDays;
      default:
        return RepeatOption.Once;
    }
  }

  @override
  void write(BinaryWriter writer, RepeatOption obj) {
    switch (obj) {
      case RepeatOption.Once:
        writer.writeByte(0);
        break;
      case RepeatOption.Everyday:
        writer.writeByte(1);
        break;
      case RepeatOption.Weekdays:
        writer.writeByte(2);
        break;
      case RepeatOption.Weekends:
        writer.writeByte(3);
        break;
      case RepeatOption.CustomDays:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepeatOptionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
