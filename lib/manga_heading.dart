import 'package:hive/hive.dart';

import 'api_objects.dart';

part 'manga_heading.g.dart';

@HiveType(typeId: 0)
class MangaHeading extends HiveObject {

  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String coverURL;

  @HiveField(3)
  String description;

  @HiveField(4)
  String allgenres;

  MangaHeading();

  MangaHeading.all({this.id, this.name, this.coverURL, this.description, this.allgenres});

  factory MangaHeading.fromJSON(Map<String, dynamic> json) {
    return MangaHeading.all(
        id: json['id'],
        name: json['name'],
        coverURL: json['coverURL'],
        description: json['smallDescription'],
        allgenres: json['genres'],
    );
  }

  @override
  int get hashCode => this.id.hashCode;

  @override
  bool operator ==(other) => other is MangaHeading && (other.id == this.id);
}