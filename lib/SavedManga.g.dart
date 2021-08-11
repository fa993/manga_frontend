// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SavedManga.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SavedMangaAdapter extends TypeAdapter<SavedManga> {
  @override
  final int typeId = 0;

  @override
  SavedManga read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SavedManga()
      ..id = fields[0] as String
      ..index = fields[1] as int
      ..coverURL = fields[2] as String
      ..name = fields[3] as String;
  }

  @override
  void write(BinaryWriter writer, SavedManga obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.index)
      ..writeByte(2)
      ..write(obj.coverURL)
      ..writeByte(3)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedMangaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
