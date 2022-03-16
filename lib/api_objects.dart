import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart' as uuid;

class APIer {
  static String _serverURL = "https://lite.floricaninfosoft.com:9432";
  static String _serverMapping = "/public/manga";

  static http.Client _cli = new http.Client();

  static Random _rd = Random();

  static Future<T> _retryExponentialBackOff<T>(Future<T> Function() func,
          {int count = -1, int maxWaitTime = 64}) async =>
      await Future.delayed(
              Duration(
                  milliseconds:
                      count < 0 ? 0 : (_rd.nextDouble() * 1000).toInt(),
                  seconds: count < 0 ? 0 : min(maxWaitTime, pow(2, count))),
              func)
          .onError((error, stackTrace) => _retryExponentialBackOff(
                func,
                count: count + 1,
                maxWaitTime: maxWaitTime,
              ));

  static Future<List<SavedManga>> fetchFavourites() async =>
      _retryExponentialBackOff(_fetchFavourites);

  static Future<MangaQueryResponse> fetchSearch(MangaQuery mangaQuery) async =>
      _fetchSearch(mangaQuery);
      // _retryExponentialBackOff(() => _fetchSearch(mangaQuery));

  static Future<CompleteManga> fetchManga(String id) async =>
      _retryExponentialBackOff(() => _fetchManga(id));

  static Future<LinkedManga> fetchPartManga(String id) async =>
      _retryExponentialBackOff(() => _fetchPartManga(id));

  static Future<ChapterContent> fetchChapter(String id) async =>
      _retryExponentialBackOff(() => _fetchChapter(id));

  static Future<ChapterPosition> fetchChapterPageNumber(
          String mangaId, int sequenceNumber) async =>
      _retryExponentialBackOff(
          () => _fetchChapterPageNumber(mangaId, sequenceNumber));

  static Future<MangaQueryResponse> fetchHome(MangaQuery q) async =>
      _retryExponentialBackOff(() => _fetchHome(q));

  static Future<List<Genre>> fetchGenres() async =>
      _retryExponentialBackOff(_fetchGenres);

  //

  static Future<List<SavedManga>> _fetchFavourites() async {
    final response =
        await _cli.get(Uri.parse(_serverURL + _serverMapping + "/favourites"));
    if (response.statusCode == HttpStatus.ok) {
      return await compute(_doParseFavourites, response.body);
    } else {
      throw new Exception(
          "Failed Status Code: " + response.statusCode.toString());
    }
  }

  static List<SavedManga> _doParseFavourites(String response) {
    return jsonDecode(response)
        .cast<Map<String, dynamic>>()
        .map<MangaHeading>((value) => SavedManga.fromJSON(value))
        .toList();
  }

  static Future<MangaQueryResponse> _fetchSearch(MangaQuery mangaQuery) async {
    final response = await _cli.post(
        Uri.parse(_serverURL + _serverMapping + "/search/"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode(mangaQuery));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      // return compute(_doParseSearch, response.body);
      return MangaQueryResponse.fromJSON(jsonDecode(response.body));
    }
  }

  static MangaQueryResponse _doParseSearch(String response) {
    return MangaQueryResponse.fromJSON(jsonDecode(response));
  }

  static Future<CompleteManga> _fetchManga(String id) async {
    final response =
        await _cli.get(Uri.parse(_serverURL + _serverMapping + "/" + id));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      // return compute(_doParseManga, response.body);
      return CompleteManga.fromJSON(jsonDecode(response.body));
    }
  }

  static CompleteManga _doParseManga(String response) {
    return CompleteManga.fromJSON(jsonDecode(response));
  }

  static Future<LinkedManga> _fetchPartManga(String id) async {
    final response =
        await _cli.get(Uri.parse(_serverURL + _serverMapping + "/part/" + id));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      // return compute(doParseManga, response.body);
      return LinkedManga.fromJSON(jsonDecode(response.body));
    }
  }

  static Future<ChapterContent> _fetchChapter(String id) async {
    final response = await _cli
        .get(Uri.parse(_serverURL + _serverMapping + "/chapter/" + id));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      return ChapterContent.fromJSON(jsonDecode(response.body));
    }
  }

  static Future<ChapterContent> fetchChapterOpt(String id) async {
    final response = await _cli
        .get(Uri.parse(_serverURL + _serverMapping + "/chapter/" + id));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      return SchedulerBinding.instance.scheduleTask(() {
        return _doParseChapter(response.body);
      }, Priority.animation);
    }
  }

  static ChapterContent _doParseChapter(String response) {
    return ChapterContent.fromJSON(jsonDecode(response));
  }

  static Future<ChapterPosition> _fetchChapterPageNumber(
      String mangaId, int sequenceNumber) async {
    final response = await _cli.get(Uri.parse(_serverURL +
        _serverMapping +
        "/chapter/position/" +
        mangaId +
        "/" +
        sequenceNumber.toString()));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      return ChapterPosition.fromJSON(jsonDecode(response.body));
    }
  }

  static Future<MangaQueryResponse> _fetchHome(MangaQuery q) async {
    final response = await _cli.post(
        Uri.parse(_serverURL + _serverMapping + "/home/"),
        headers: {"Content-type": "application/json"},
        body: jsonEncode(q));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      return MangaQueryResponse.fromJSON(jsonDecode(response.body));
    }
  }

  static Future<List<Genre>> _fetchGenres() async {
    final response =
        await _cli.get(Uri.parse(_serverURL + _serverMapping + "/genres/"));
    if (response.statusCode != HttpStatus.ok) {
      throw new Exception(
          "Failed Status code: " + response.statusCode.toString());
    } else {
      return (jsonDecode(response.body) as List)
          .map((e) => Genre.fromJSON(e))
          .toList();
    }
  }
}

class DBer {
  static const _databaseName = "manga.db";
  static const _mangaPreferencesTableName = "manga_pref";
  static const _savedMangaTableName = "saved_manga";
  static const _chapterTableName = "read_chapter";

  static bool _initialized = false;

  static SavedMangaTable _permanentModel;
  static List<SavedManga> _savedMangaModel;
  static ValueNotifier<LastReadChapter> _notifierForChapter;

  static Database _mangaDB;

  static Future<void> initializeDatabase() async {
    if (!_initialized) {
      _mangaDB = await openDatabase(
        join(await getDatabasesPath(), _databaseName),
        onCreate: (db, version) async {
          await db.execute(
              'CREATE TABLE $_savedMangaTableName(saved_manga_id TEXT, name STRING, coverURL TEXT, all_genres TEXT, description TEXT, manga_index INTEGER, PRIMARY KEY(saved_manga_id))');
          await db.execute(
              'CREATE TABLE $_chapterTableName(manga_id TEXT, linked_id TEXT, chapter_id TEXT, chapter_read_time INTEGER, chapter_page INTEGER, PRIMARY KEY(chapter_id))');
          await db.execute(
              'CREATE TABLE $_mangaPreferencesTableName(manga_id TEXT, scroll_style INTEGER, PRIMARY KEY(manga_id))');
        },
        onUpgrade: (db, vo, vn) async {
          await db.execute('DROP TABLE IF EXISTS $_savedMangaTableName');
          await db.execute(
              'CREATE TABLE $_savedMangaTableName(saved_manga_id TEXT, name STRING, coverURL TEXT, all_genres TEXT, description TEXT, manga_index INTEGER, PRIMARY KEY(saved_manga_id))');
          await db.execute('DROP TABLE IF EXISTS $_chapterTableName');
          await db.execute(
              'CREATE TABLE $_chapterTableName(manga_id TEXT, linked_id TEXT, chapter_id TEXT, chapter_read_time INTEGER, chapter_page INTEGER, PRIMARY KEY(chapter_id))');
          await db.execute('DROP TABLE IF EXISTS $_mangaPreferencesTableName');
          await db.execute(
              'CREATE TABLE $_mangaPreferencesTableName(manga_id TEXT, scroll_style INTEGER, PRIMARY KEY(manga_id))');
        },
        onDowngrade: (db, vo, vn) async {
          await db.execute('DROP TABLE IF EXISTS $_savedMangaTableName');
          await db.execute(
              'CREATE TABLE $_savedMangaTableName(saved_manga_id TEXT, name STRING, coverURL TEXT, all_genres TEXT, description TEXT, manga_index INTEGER, PRIMARY KEY(saved_manga_id))');
          await db.execute('DROP TABLE IF EXISTS $_chapterTableName');
          await db.execute(
              'CREATE TABLE $_chapterTableName(manga_id TEXT, linked_id TEXT, chapter_id TEXT, chapter_read_time INTEGER, chapter_page INTEGER, PRIMARY KEY(chapter_id))');
          await db.execute('DROP TABLE IF EXISTS $_mangaPreferencesTableName');
          await db.execute(
              'CREATE TABLE $_mangaPreferencesTableName(manga_id TEXT, scroll_style INTEGER, PRIMARY KEY(manga_id))');
        },
        version: 13,
      );
      _initialized = true;
    }
    _savedMangaModel = (await DBer.getAllSavedMangaAsync()).toList();
    _permanentModel = SavedMangaTable.fromList(_savedMangaModel);
  }

  static void registerNotifierForChapter(
      ValueNotifier<LastReadChapter> notifier) {
    if (_notifierForChapter != null) {
      _notifierForChapter.dispose();
    }
    _notifierForChapter = notifier;
  }

  static Future<Iterable<MangaHeading>> fromQuery(MangaQuery query) {
    return _mangaDB
        .query(
          _savedMangaTableName,
          columns: [
            'saved_manga_id',
            'name',
            'coverURL',
            'all_genres',
            'description'
          ],
          where: 'name LIKE ?',
          whereArgs: ['%${query.name}%'],
        )
        .then(
          (value) => value.map(
            (e) => MangaHeading.all(
              id: e['saved_manga_id'],
              name: e['name'],
              allGenres: e['all_genres'],
              description: e['description'],
              coverURL: e['coverURL'],
            ),
          ),
        );
  }

  static Future<Iterable<SavedManga>> getAllSavedMangaAsync() async {
    if (_mangaDB != null) {
      return _mangaDB
          .query(
        _savedMangaTableName,
        columns: ['saved_manga_id', 'manga_index', 'coverURL', 'name'],
        orderBy: 'manga_index ASC',
      )
          .then(
        (value) {
          return value.map(
            (e) => SavedManga.all(
                index: e['manga_index'],
                id: e['saved_manga_id'],
                coverURL: e['coverURL'],
                name: e['name']),
          );
        },
      );
    } else {
      return Iterable.empty();
    }
  }

  static void saveMangaHeading(MangaHeading mg) async {
    return saveManga(mg.id, mg.name, mg.coverURL, mg.description, mg.allGenres);
  }

  static Future<void> saveManga(String id, String name, String coverURL,
      String description, String allGenres) async {
    await _mangaDB.transaction((txn) async {
      int index = Sqflite.firstIntValue(await txn
          .rawQuery('SELECT max(manga_index) from $_savedMangaTableName'));
      if (index != null) {
        index += 1;
      } else {
        index = 0;
      }
      SavedManga m = SavedManga.all(
        id: id,
        name: name,
        coverURL: coverURL,
        index: index,
        description: description,
        allGenres: allGenres,
      );
      if (_permanentModel != null) {
        _permanentModel.addManga(m);
      }
      await txn.insert(
        _savedMangaTableName,
        m.toMap(),
        conflictAlgorithm: ConflictAlgorithm.rollback,
      );
    });
    return null;
  }

  static Future<void> removeManga(String id) async {
    await _mangaDB.delete(
      _savedMangaTableName,
      where: 'saved_manga_id = ?',
      whereArgs: [id],
    );
    if (_permanentModel != null) {
      _permanentModel.removeManga(id);
    }
    return null;
  }

  static Future<bool> isSaved(String id) async {
    return Sqflite.firstIntValue(await _mangaDB.rawQuery(
          'SELECT EXISTS(SELECT 1 from $_savedMangaTableName WHERE saved_manga_id = ?)',
          [id],
        )) ==
        1;
  }

  static void reorder(String id1, String id2) {
    //TODO
    _mangaDB.transaction((txn) async {
      //TODO test this
      int index1 = Sqflite.firstIntValue(await txn.query(_savedMangaTableName,
          where: "saved_manga_id = ? ",
          whereArgs: [id1],
          columns: ['manga_index']));
      int index2 = Sqflite.firstIntValue(await txn.query(_savedMangaTableName,
          where: "saved_manga_id = ? ",
          whereArgs: [id2],
          columns: ['manga_index']));
      if (index2 < index1) {
        await txn.rawUpdate(
            'UPDATE $_savedMangaTableName set manga_index = manga_index + 1 where manga_index >= ? AND manga_index < ?',
            [index2, index1]);
      } else {
        //index2 > index1
        await txn.rawUpdate(
            'UPDATE $_savedMangaTableName set manga_index = manga_index - 1 where manga_index > ? AND manga_index <= ?',
            [index1, index2]);
      }
      await txn.rawUpdate(
          'UPDATE $_savedMangaTableName set manga_index = ? where saved_manga_id = ?',
          [index2, id1]);
      if (_permanentModel != null) {
        _permanentModel.reorder(id1, id2);
      }
    });
  }

  static void readChapter(
      String mangaId, String linkedId, String chapterId, int pgNum) async {
    await _mangaDB.insert(
      _chapterTableName,
      ReadChapter.all(
        mangaId: mangaId,
        linkedId: linkedId,
        chapterId: chapterId,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        pageNumber: pgNum,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    if (_notifierForChapter != null) {
      _notifierForChapter.value =
          LastReadChapter(mangaId: mangaId, chapterId: chapterId);
    }
  }

  static void updateChapterPage(String chapterId, int pgNum) async {
    await _mangaDB.update(
      _chapterTableName,
      ReadChapter.all(
        pageNumber: pgNum,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      ).toMap(),
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
  }

  static void updatePreferredScrollStyle(String mangaId, int display) async {
    await _mangaDB.insert(
      _mangaPreferencesTableName,
      MangaPreference.all(
        mangaId: mangaId,
        displayStyle: display,
      ).toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String> getMostRecentReadChapter(String mangaId) async {
    List<Map<String, Object>> rows = await _mangaDB.query(
      _chapterTableName,
      columns: ['chapter_id'],
      orderBy: 'chapter_read_time DESC',
      where: 'manga_id = ?',
      whereArgs: [mangaId],
      limit: 1,
    );
    return rows.single.values.first;
  }

  static Future<LastReadChapter> getMostRecentReadChapterByLinkedId(
      String linkedId) async {
    List<Map<String, Object>> rows = await _mangaDB.query(
      _chapterTableName,
      columns: ['manga_id', 'chapter_id'],
      orderBy: 'chapter_read_time DESC',
      where: 'linked_id = ?',
      whereArgs: [linkedId],
      limit: 1,
    );
    Iterable x = rows.single.values;
    return LastReadChapter(mangaId: x.elementAt(0), chapterId: x.elementAt(1));
  }

  static Future<int> getLastReadPage(String chapterId) async {
    List<Map<String, Object>> rows = await _mangaDB.query(
      _chapterTableName,
      columns: ['chapter_page'],
      where: 'chapter_id = ?',
      whereArgs: [chapterId],
    );
    return Sqflite.firstIntValue(rows);
  }

  static Future<int> getPreferredScrollStyle(String mangaId) async {
    List<Map<String, Object>> rows = await _mangaDB.query(
      _mangaPreferencesTableName,
      columns: ['scroll_style'],
      where: 'manga_id = ?',
      whereArgs: [mangaId],
    );
    return Sqflite.firstIntValue(rows);
  }

  static SavedMangaTable getTable() {
    return _permanentModel.createNotifier();
  }
}

class Memory {
  static int _maxMemoryCap = 40;

  static Map<String, Chapters> _manga = {};

  static List<String> _sequence = [];

  static String _message;

  static void retain(CompleteManga mg) {
    _manga[mg.id] = Chapters.all(
        mangaId: mg.id,
        linkedId: mg.linkedId,
        chaps: mg.chapters,
        currentIndex: -1,
        s: mg.source);
    _sequence.add(mg.id);
    while (_sequence.length > _maxMemoryCap) {
      _manga.remove(_sequence.removeAt(0));
    }
    mg.linkedMangas.forEach((element) {
      retainLinked(element);
    });
  }

  static void retainLinked(LinkedManga mg) {
    _manga[mg.id] = Chapters.all(
        mangaId: mg.id,
        linkedId: mg.linkedId,
        chaps: mg.chapters,
        currentIndex: -1,
        s: mg.source);
    _sequence.add(mg.id);
    while (_sequence.length > _maxMemoryCap) {
      _manga.remove(_sequence.removeAt(0));
    }
  }

  static Chapters remember(String mangaId, int index) {
    Chapters mg = _manga[mangaId];
    if (mg != null) {
      return Chapters.all(
        s: mg.s,
        currentIndex: index,
        mangaId: mangaId,
        linkedId: mg.linkedId,
        chaps: mg.chaps,
      );
    } else {
      return null;
    }
  }

  static void rememberQuick(String message) {
    _message = message;
  }

  static String retainQuick() {
    return _message;
  }
}

class MangaPreference {
  String mangaId;
  int displayStyle;

  MangaPreference.all({this.mangaId, this.displayStyle});

  Map<String, dynamic> toMap() {
    return {
      'manga_id': mangaId,
      'scroll_style': displayStyle,
    };
  }
}

class ReadChapter {
  String chapterId;
  int timestamp;
  String mangaId;
  String linkedId;
  int pageNumber;

  ReadChapter.all(
      {this.chapterId,
      this.timestamp,
      this.mangaId,
      this.linkedId,
      this.pageNumber});

  Map<String, dynamic> toMap() {
    return {
      if (mangaId != null) 'manga_id': mangaId,
      if (linkedId != null) 'linked_id': linkedId,
      if (chapterId != null) 'chapter_id': chapterId,
      if (timestamp != null) 'chapter_read_time': timestamp,
      if (pageNumber != null) 'chapter_page': pageNumber,
    };
  }
}

class SavedManga extends MangaHeading {
  int index;

  SavedManga();

  SavedManga.all(
      {this.index,
      String id,
      String name,
      String coverURL,
      String description,
      String allGenres})
      : super.all(
          id: id,
          name: name,
          coverURL: coverURL,
          description: description,
          allGenres: allGenres,
        );

  factory SavedManga.fromJSON(Map<String, dynamic> json) {
    return SavedManga.all(
      index: json['manga_index'],
      name: json['name'],
      id: json['id'],
      allGenres: json['genres'],
      description: json['description'],
      coverURL: json['coverURL'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'saved_manga_id': this.id,
      'name': this.name,
      'coverURL': this.coverURL,
      'description': this.description,
      'all_genres': this.allGenres,
      'manga_index': this.index,
    };
  }

  @override
  bool operator ==(Object other) => other is SavedManga && id == other.id;

  @override
  int get hashCode => this.id.hashCode;
}

class SavedMangaTable extends ChangeNotifier {
  static final _uuid = uuid.Uuid();

  String _id;

  List<SavedManga> _list;
  bool _disposed = false;
  SavedMangaTable _parent;
  List<SavedMangaTable> _childs = [];

  SavedMangaTable() {
    this._id = _uuid.v1();
  }

  SavedMangaTable.fromList(List<SavedManga> m) {
    this._list = m;
  }

  SavedMangaTable.fromIterable(Iterable<SavedManga> m) {
    this._list = m.toList();
  }

  addManga(SavedManga m) {
    if (this._list != null) {
      this._list.add(m);
      doNotifyListeners();
    }
  }

  removeManga(String id) {
    if (this._list != null) {
      this._list.removeWhere((element) => element.id == id);
      doNotifyListeners();
    }
  }

  reorder(String id1, String id2) {
    if (this._list != null) {
      SavedManga m = this._list.firstWhere((element) => element.id == id1);
      SavedManga m2 = this._list.firstWhere((element) => element.id == id2);
      int tmp = m.index;
      m.index = m2.index;
      m2.index = tmp;
    }
  }

  List<SavedManga> get getList {
    return this._list;
  }

  void doDispose() {
    this._disposed = true;
    if (this._parent != null) {
      this._parent._childs.remove(this);
    }
    this.dispose();
  }

  bool get isDisposed {
    return this._disposed;
  }

  SavedMangaTable createNotifier() {
    SavedMangaTable tb = SavedMangaTable.fromList(this._list);
    this._childs.add(tb);
    tb._parent = this;
    return tb;
  }

  void doNotifyListeners() {
    this._childs.forEach((t) {
      if (!t.isDisposed) {
        t.notifyListeners();
      }
    });
    this.notifyListeners();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedMangaTable &&
          runtimeType == other.runtimeType &&
          _id == other._id;

  @override
  int get hashCode => _id.hashCode;
}

class MangaHeading {
  String id;

  String name;

  String coverURL;

  String description;

  String allGenres;

  MangaHeading();

  MangaHeading.all(
      {this.id, this.name, this.coverURL, this.description, this.allGenres});

  factory MangaHeading.fromJSON(Map<String, dynamic> json) {
    return MangaHeading.all(
      id: json['id'],
      name: json['name'],
      coverURL: json['coverURL'],
      description: json['smallDescription'],
      allGenres: json['genres'],
    );
  }

  @override
  int get hashCode => this.id.hashCode;

  @override
  bool operator ==(other) => other is MangaHeading && (other.id == this.id);
}

class MangaQuery {
  static final _uuid = uuid.Uuid();

  String id;
  String name;
  int offset;
  int limit;
  List<String> genres;

  MangaQuery() {
    this.id = _generateID();
    this.genres = [];
  }

  MangaQuery.all({this.id, this.name, this.limit, this.offset, this.genres});

  MangaQuery.copy(MangaQuery query) {
    this.id = _generateID();
    this.name = query.name;
    this.limit = query.limit;
    this.offset = query.offset;
    this.genres = query.genres;
  }

  static String _generateID() {
    return _uuid.v1();
  }

  factory MangaQuery.fromJSON(Map<String, dynamic> json) {
    return MangaQuery.all(
      id: json['id'],
      name: json['name'],
      limit: json['limit'],
      offset: json['offset'],
      genres: (json['genreIds'] as List).map((e) => e.toString()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'limit': limit,
      'offset': offset,
      'genreIds': genres,
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
      headings: (json['headings'] as List)
          .map((e) => MangaHeading.fromJSON(e))
          .toList(),
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
    return HomePageRoot.all(
        title: json['title'],
        designator: json['designator'],
        data: (json['data'] as List)
            .map((e) => MangaHeading.fromJSON(e))
            .toList(),
        children: (json['children'] as List)
            .map((e) => HomePageRoot.fromJSON(e))
            .toList());
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
  int watchTime;

  ChapterData.all(
      {this.id,
      this.sequenceNumber,
      this.chapterName,
      this.chapterNumber,
      this.updatedAt,
      this.watchTime});

  factory ChapterData.fromJSON(Map<String, dynamic> json) {
    return ChapterData.all(
      id: json["id"],
      sequenceNumber: json["sequenceNumber"],
      chapterName: json["chapterName"],
      chapterNumber: json["chapterNumber"],
      updatedAt:
          json["updatedAt"] != null ? DateTime.parse(json["updatedAt"]) : null,
      watchTime: json["watchTime"],
    );
  }
}

class LinkedManga {
  String id;
  String linkedId;
  String name;
  String coverURL;
  Source source;
  Map<int, ChapterData> chapters;

  LinkedManga.all(
      {this.id,
      this.linkedId,
      this.name,
      this.coverURL,
      this.source,
      this.chapters});

  factory LinkedManga.fromJSON(Map<String, dynamic> json) {
    Map<int, ChapterData> dts = {};
    (json["chapters"] as List).forEach((element) {
      ChapterData chp = ChapterData.fromJSON(element);
      dts.putIfAbsent(chp.sequenceNumber, () => chp);
    });
    return LinkedManga.all(
      id: json["id"],
      linkedId: json["linkedId"],
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

  CompleteManga.all(
      {this.id,
      this.title,
      this.description,
      this.linkedId,
      this.coverURL,
      this.source,
      this.authors,
      this.artists,
      this.genres,
      this.chapters,
      this.status,
      this.lastUpdated,
      this.linkedMangas});

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
      authors:
          (main["authors"] as List).map((e) => Author.fromJSON(e)).toList(),
      artists:
          (main["artists"] as List).map((e) => Artist.fromJSON(e)).toList(),
      genres: (main["genres"] as List).map((e) => Genre.fromJSON(e)).toList(),
      chapters: dts,
      status: main["status"],
      lastUpdated: main["lastUpdated"] != null
          ? DateTime.parse(main["lastUpdated"])
          : null,
      linkedMangas: (json["related"] as List)
          .map((e) => LinkedManga.fromJSON(e))
          .toList(),
    );
  }
}

class ChapterContent {
  List<String> urls;

  ChapterContent.all({this.urls});

  factory ChapterContent.fromJSON(List<dynamic> json) {
    return ChapterContent.all(
        urls: json.map((e) => e['url'].toString()).toList());
  }
}

class CompleteChapter {
  String id;
  ChapterContent content;
  ChapterData dt;
  Source source;

  CompleteChapter.all(this.id, this.content, this.dt, this.source);
}

class Chapters {
  String mangaId;
  String linkedId;
  Map<int, ChapterData> chaps;
  Source s;
  int currentIndex;

  Chapters.all(
      {this.mangaId, this.linkedId, this.chaps, this.s, this.currentIndex});
}

class ChapterPosition {
  int index;
  int length;

  ChapterPosition.all({this.index, this.length});

  factory ChapterPosition.fromJSON(Map<String, dynamic> json) {
    return ChapterPosition.all(
      index: json['index'],
      length: json['length'],
    );
  }
}

class LastReadChapter {
  final String mangaId;
  final String chapterId;

  const LastReadChapter({this.mangaId, this.chapterId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LastReadChapter &&
          runtimeType == other.runtimeType &&
          mangaId == other.mangaId &&
          chapterId == other.chapterId;

  @override
  int get hashCode => mangaId.hashCode ^ chapterId.hashCode;
}
