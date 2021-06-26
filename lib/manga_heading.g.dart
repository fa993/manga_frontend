// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manga_heading.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MangaHeadingAdapter extends TypeAdapter<MangaHeading> {
  @override
  final int typeId = 0;

  @override
  MangaHeading read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return MangaHeading()
      ..id = fields[0] as String
      ..name = fields[1] as String
      ..coverURL = fields[2] as String
      ..description = fields[3] as String
      ..allgenres = fields[4] as String;
  }

  @override
  void write(BinaryWriter writer, MangaHeading obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.coverURL)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.allgenres);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MangaHeadingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
