// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense2.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class Expense2Adapter extends TypeAdapter<Expense2> {
  @override
  final int typeId = 2;

  @override
  Expense2 read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Expense2(
      id: fields[0] as int,
      name: fields[1] as String,
      price: fields[2] as double,
      expenseType: fields[3] as ExpenseType,
      date: fields[4] as DateTime,
      created: fields[5] as DateTime,
      updated: fields[6] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, Expense2 obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.price)
      ..writeByte(3)
      ..write(obj.expenseType)
      ..writeByte(4)
      ..write(obj.date)
      ..writeByte(5)
      ..write(obj.created)
      ..writeByte(6)
      ..write(obj.updated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Expense2Adapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
