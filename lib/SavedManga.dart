import 'package:hive/hive.dart';

part 'SavedManga.g.dart';

@HiveType(typeId: 0)
class SavedManga extends HiveObject{
  
  @HiveField(0)
  String id;

  @HiveField(1)
  int index;

  @HiveField(2)
  String coverURL;

  @HiveField(3)
  String name;

  SavedManga();

  SavedManga.all({this.id, this.index, this.coverURL, this.name});

  @override
  bool operator ==(Object other) => identical(this, other) || other is SavedManga && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
