import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart' as uuid;

import 'manga_heading.dart';

class APIer {
  static String serverURl = "https://192.168.1.65:8080";
  static String serverMapping = "/public/manga";

  static http.Client _cli = new http.Client();

  static Future<List<IndexedMangaHeading>> fetchFavourites() async {
    final response = await _cli.get(Uri.parse(serverURl + serverMapping + "/favourites"));
    if (response.statusCode == HttpStatus.ok) {
      return await compute(doParseFavourites, response.body);
    } else {
      throw new Exception("Failed Status Code: " + response.statusCode.toString());
    }
  }

  static List<IndexedMangaHeading> doParseFavourites(String response) {
    return jsonDecode(response).cast<Map<String, dynamic>>().map<MangaHeading>((value) => IndexedMangaHeading.fromJSON(value)).toList();
  }

  static Future<List<MangaHeading>> fetchHome(int offset, [int limit = 10]) async {
    final response = await _cli.get(Uri.parse(serverURl + serverMapping + "/home?limit=" + limit.toString() + "&offset=" + offset.toString()));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception("Failed Status Code: " + response.statusCode.toString());
    }
    return jsonDecode(response.body).cast<Map<String, dynamic>>().map<MangaHeading>((value) => MangaHeading.fromJSON(value)).toList();
  }

  static Future<MangaHeading> fetchTest() async {
    final response = await _cli.get(Uri.parse(serverURl + serverMapping + "/thumbnail"));
    if (response.statusCode == HttpStatus.ok) {
      return MangaHeading.fromJSON(jsonDecode(response.body));
    } else {
      throw new Exception("Failed Status Code: " + response.statusCode.toString());
    }
  }

  static Future<MangaQueryResponse> fetchSearch(MangaQuery mangaQuery) async {
    final response = await _cli.post(Uri.parse(serverURl + serverMapping + "/search/"), headers: {"Content-type": "application/json"}, body: jsonEncode(mangaQuery));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception("Failed Status code: " + response.statusCode.toString());
    } else {
      // return compute(doParseSearch, response.body);
      return MangaQueryResponse.fromJSON(jsonDecode(response.body));
    }
  }

  static MangaQueryResponse doParseSearch(String response){
    return MangaQueryResponse.fromJSON(jsonDecode(response));
  }

  static Future<CompleteManga> fetchManga(String id) async {
    final response = await _cli.get(Uri.parse(serverURl + serverMapping + "/" + id));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception("Failed Status code: " + response.statusCode.toString());
    } else {
      // return compute(doParseManga, response.body);
      return CompleteManga.fromJSON(jsonDecode(response.body));
    }
  }

  static CompleteManga doParseManga(String response){
    return CompleteManga.fromJSON(jsonDecode(response));
  }

  static Future<ChapterContent> fetchChapter(String id) async {
    final response = await _cli.get(Uri.parse(serverURl + serverMapping + "/chapter/" + id));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception("Failed Status code: " + response.statusCode.toString());
    } else {
      return ChapterContent.fromJSON(jsonDecode(response.body));
      // return compute(doParseChapter, response.body);
    }
  }

  static ChapterContent doParseChapter(String response) {
    return ChapterContent.fromJSON(jsonDecode(response));
  }
}

class DBer {
  static LazyBox<MangaHeading> _fav;
  static int _index;

  static void initializeDatabase() async {
    await Hive.initFlutter();
    _fav = await Hive.openLazyBox<MangaHeading>("favourites");
    Hive.registerAdapter(MangaHeadingAdapter());
  }

  static Future<MangaHeading> fetchFavouriteAt(int index) {
    return _fav.get(index);
  }

  static int getFavouritesCount() {
    return _fav.length;
  }

  static void addFavourite(MangaHeading hd) {
    _fav.put(_index++, hd);
  }

  static void putFavourites(List<IndexedMangaHeading> hd) {
    hd.forEach((element) {
      _fav.put(element.index, element.heading);
    });
    _index = _fav.length;
  }

  static void switchOrder(int index1, int index2) async {
    MangaHeading h1 = await _fav.get(index1);
    MangaHeading h2 = await _fav.get(index2);
    _fav.put(index1, h2);
    _fav.put(index2, h1);
  }
}

// class Manga {
//
//   String _id;
//
//   String _linkedId;
//
//   String _name;
//
//   String _coverURL;
//
//   String _url;
//
//   MangaMetadata _metadata;
//   Source _source;
//
// }
//
// class MangaMetadata {
//
// }
//
// class Source {
//
// }

class IndexedMangaHeading {
  MangaHeading heading;

  int index;

  IndexedMangaHeading({this.index, this.heading});

  factory IndexedMangaHeading.fromJSON(Map<String, dynamic> json) {
    return IndexedMangaHeading(
      index: json.containsKey('index') ? json['index'] : -1,
      heading: MangaHeading.fromJSON(json['heading']),
    );
  }

  factory IndexedMangaHeading.fromAPI(Map<String, dynamic> json) {
    return IndexedMangaHeading(
      index: json.containsKey('index') ? json['index'] : -1,
      heading: MangaHeading.fromJSON(json),
    );
  }

  factory IndexedMangaHeading.fromHeading(int index, Map<String, dynamic> json) {
    return IndexedMangaHeading.fromAPI(json)..index = index;
  }
}

class MangaQuery {
  static final _uuid = uuid.Uuid();

  String id;
  String name;
  int offset;
  int limit;

  MangaQuery() {
    this.id = _uuid.v1();
  }

  MangaQuery.all({this.id, this.name, this.limit, this.offset});

  MangaQuery.copy(MangaQuery query) {
    this.id = _generateID();
    this.name = query.name;
    this.limit = query.limit;
    this.offset = query.offset;
  }

  static String _generateID() {
    return uuid.Uuid().v1();
  }

  factory MangaQuery.fromJSON(Map<String, dynamic> json) {
    return MangaQuery.all(
      id: json['id'],
      name: json['name'],
      limit: json['limit'],
      offset: json['offset'],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'limit': limit,
      'offset': offset,
    };
  }

  void renew() {
    this.id = _generateID();
  }

  @override
  bool operator ==(Object other) {
    return (other is MangaQuery) && other.id == this.id;
  }

  @override
  int get hashCode => this.id.hashCode;
}

class MangaQueryResponse {
  MangaQuery query;

  List<MangaHeading> headings;

  MangaQueryResponse();

  MangaQueryResponse.all({this.query, this.headings});

  factory MangaQueryResponse.fromJSON(Map<String, dynamic> json) {
    return MangaQueryResponse.all(
      query: MangaQuery.fromJSON(json['query']),
      headings: (json['manga'] as List).map((e) => MangaHeading.fromJSON(e)).toList(),
    );
  }
}

class HomePageRoot {
  String title;
  String designator;
  List<MangaHeading> data;
  List<HomePageRoot> children;

  HomePageRoot.all({this.title, this.designator, this.data, this.children});

  factory HomePageRoot.fromJSON(Map<String, dynamic> json) {
    return HomePageRoot.all(title: json['title'], designator: json['designator'], data: (json['data'] as List).map((e) => MangaHeading.fromJSON(e)).toList(), children: (json['children'] as List).map((e) => HomePageRoot.fromJSON(e)).toList());
  }
}

class Source {
  String id;
  String name;

  Source.all({this.id, this.name});

  factory Source.fromJSON(Map<String, dynamic> json) {
    return Source.all(id: json["id"], name: json["name"]);
  }
}

class Author {
  String id;
  String name;

  Author.all({this.id, this.name});

  factory Author.fromJSON(Map<String, dynamic> json) {
    return Author.all(id: json["id"], name: json["name"]);
  }
}

class Artist {
  String id;
  String name;

  Artist.all({this.id, this.name});

  factory Artist.fromJSON(Map<String, dynamic> json) {
    return Artist.all(id: json["id"], name: json["name"]);
  }
}

class Genre {
  String id;
  String name;

  Genre.all({this.id, this.name});

  factory Genre.fromJSON(Map<String, dynamic> json) {
    return Genre.all(id: json["id"], name: json["name"]);
  }
}

class ChapterData {
  String id;
  int sequenceNumber;
  String chapterName;
  String chapterNumber;
  DateTime updatedAt;

  ChapterData.all({this.id, this.sequenceNumber, this.chapterName, this.chapterNumber, this.updatedAt});

  factory ChapterData.fromJSON(Map<String, dynamic> json) {
    return ChapterData.all(id: json["id"], sequenceNumber: json["sequenceNumber"], chapterName: json["chapterName"], chapterNumber: json["chapterNumber"], updatedAt: json["updatedAt"]!= null ? DateTime.parse(json["updatedAt"]) : null);
  }
}

class LinkedManga {
  String id;
  String name;
  String coverURL;
  Source source;
  Map<int, ChapterData> chapters;

  LinkedManga.all({this.id, this.name, this.coverURL, this.source, this.chapters});

  factory LinkedManga.fromJSON(Map<String, dynamic> json) {
    Map<int, ChapterData> dts = {};
    (json["chapters"] as List).forEach((element) {
      ChapterData chp = ChapterData.fromJSON(element);
      dts.putIfAbsent(chp.sequenceNumber, () => chp);
    });
    return LinkedManga.all(
      id: json["id"],
      name: json["name"],
      coverURL: json["coverURL"],
      source: Source.fromJSON(json["source"]),
      chapters: dts,
    );
  }
}

class CompleteManga {
  String id;
  String title;
  String description;
  String linkedId;
  String coverURL;
  Source source;
  List<Author> authors;
  List<Artist> artists;
  List<Genre> genres;
  Map<int, ChapterData> chapters;
  String status;
  DateTime lastUpdated;
  List<LinkedManga> linkedMangas;

  CompleteManga.all({this.id, this.title, this.description, this.linkedId, this.coverURL, this.source, this.authors, this.artists, this.genres, this.chapters, this.status, this.lastUpdated, this.linkedMangas});

  factory CompleteManga.fromJSON(Map<String, dynamic> json) {
    Map<String, dynamic> main = json["main"];
    Map<int, ChapterData> dts = {};
    (main["chapters"] as List).forEach((element) {
      ChapterData dt = ChapterData.fromJSON(element);
      dts.putIfAbsent(dt.sequenceNumber, () => dt);
    });
    return CompleteManga.all(
      id: main["id"],
      title: main["name"],
      description: main["description"],
      linkedId: main["linkedId"],
      coverURL: main["coverURL"],
      source: Source.fromJSON(main["source"]),
      authors: (main["authors"] as List).map((e) => Author.fromJSON(e)).toList(),
      artists: (main["artists"] as List).map((e) => Artist.fromJSON(e)).toList(),
      genres: (main["genres"] as List).map((e) => Genre.fromJSON(e)).toList(),
      chapters: dts,
      status: main["status"],
      lastUpdated: main["lastUpdated"] != null ? DateTime.parse(main["lastUpdated"]) : null,
      linkedMangas: (json["related"] as List).map((e) => LinkedManga.fromJSON(e)).toList(),
    );
  }
}

class ChapterContent {

  List<String> urls;

  ChapterContent.all({this.urls});

  factory ChapterContent.fromJSON(List<dynamic> json) {
    return ChapterContent.all(urls: json.map((e) => e['url'].toString()).toList());
  }
}

class CompleteChapter {

  String id;
  ChapterContent content;
  Source source;

  CompleteChapter.all(this.id, this.content, this.source);
}