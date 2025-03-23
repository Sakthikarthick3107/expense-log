// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'upi.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UpiLogAdapter extends TypeAdapter<UpiLog> {
  @override
  final int typeId = 5;

  @override
  UpiLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UpiLog(
      message: fields[0] as String,
      timestamp: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UpiLog obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.message)
      ..writeByte(1)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UpiLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
