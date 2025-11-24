// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'watch_point_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class WatchPointModelAdapter extends TypeAdapter<WatchPointModel> {
  @override
  final int typeId = 6;

  @override
  WatchPointModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WatchPointModel(
      id: fields[0] as String,
      name: fields[1] as String,
      address: fields[2] as String,
      latitude: fields[3] as double,
      longitude: fields[4] as double,
      description: fields[5] as String?,
      nearestCity: fields[6] as String?,
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, WatchPointModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.address)
      ..writeByte(3)
      ..write(obj.latitude)
      ..writeByte(4)
      ..write(obj.longitude)
      ..writeByte(5)
      ..write(obj.description)
      ..writeByte(6)
      ..write(obj.nearestCity)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WatchPointModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
