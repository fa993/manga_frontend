import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:reorderables/reorderables.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'api_objects.dart';
import 'visual_objects.dart';

void main() async {
  HttpOverrides.global = new DevHttpsOverrides();
  WidgetsFlutterBinding.ensureInitialized();
  DBer.initializeDatabase();
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key key}) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future<FirebaseApp> _init = Firebase.initializeApp();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _init,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          print(snapshot.error);
          return AppHome(
            fcmInit: false,
          );
        } else if (snapshot.connectionState == ConnectionState.done) {
          //TODO check if this works
          FirebaseMessaging.instance.requestPermission();
          return AppHome(
            fcmInit: true,
          );
        } else {
          return CenteredFixedCircle();
        }
      },
    );
  }
}

class MyRoute<T> extends Page<T> {
  final WidgetBuilder builder;

  const MyRoute({this.builder, String name, Key key})
      : super(key: key, name: name);

  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute(
      builder: this.builder,
      settings: this,
    );
  }
}

class AppHome extends StatefulWidget {
  final bool fcmInit;

  const AppHome({Key key, this.fcmInit}) : super(key: key);

  @override
  _AppHomeState createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  // This widget is the root of your application.

  @override
  void initState() {
    super.initState();
    DBer.initializeDatabase();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routeInformationParser: MangaRouteInformationParser(),
      routerDelegate: MangaRouteDelegate(widget.fcmInit),
      title: 'MangaVerse',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.yellow,
        unselectedWidgetColor: Colors.white,
        fontFamily: DefaultTextStyle.of(context).style.fontFamily,
        backgroundColor: Colors.black,
      ),
    );
  }
}

class LostPage extends StatelessWidget {
  const LostPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        color: Colors.black,
        child: Text(
          "404",
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

enum RouteType {
  HOME_ROUTE,
  SEARCH_ROUTE,
  MANGA_PAGE_ROUTE,
  READER_ROUTE,
  LOST_ROUTE,
  READER_DIRECT_ROUTE,
  MANGA_PAGE_DIRECT_ROUTE
}

class MangaRoutePath {
  RouteType routeType;
  bool includeDB;
  String mangaId;
  int index;
  int pgNum;

  MangaRoutePath(
      {this.routeType, this.mangaId, this.index, this.pgNum, this.includeDB});

  factory MangaRoutePath.home() {
    return new MangaRoutePath(
      routeType: RouteType.HOME_ROUTE,
    );
  }

  factory MangaRoutePath.search(bool includeDB) {
    return new MangaRoutePath(
      routeType: RouteType.SEARCH_ROUTE,
      includeDB: includeDB,
    );
  }

  factory MangaRoutePath.manga(String mangaId) {
    return new MangaRoutePath(
      routeType: RouteType.MANGA_PAGE_ROUTE,
      mangaId: mangaId,
    );
  }

  factory MangaRoutePath.mangaDirect(String mangaId) {
    return new MangaRoutePath(
      routeType: RouteType.MANGA_PAGE_DIRECT_ROUTE,
      mangaId: mangaId,
    );
  }

  factory MangaRoutePath.reader(String mangaId, int id, int pgNum) {
    return new MangaRoutePath(
      routeType: RouteType.READER_ROUTE,
      mangaId: mangaId,
      index: id,
      pgNum: pgNum,
    );
  }

  factory MangaRoutePath.readerDirect(String mangaId, int id, int pgNum) {
    return new MangaRoutePath(
      routeType: RouteType.READER_DIRECT_ROUTE,
      mangaId: mangaId,
      index: id,
      pgNum: pgNum,
    );
  }

  factory MangaRoutePath.lost() {
    return new MangaRoutePath(
      routeType: RouteType.LOST_ROUTE,
    );
  }
}

class MangaRouteInformationParser
    extends RouteInformationParser<MangaRoutePath> {
  @override
  Future<MangaRoutePath> parseRouteInformation(
      RouteInformation routeInformation) async {
    final uri = Uri.parse(routeInformation.location);
    Map<String, String> args = uri.queryParameters;
    MangaRoutePath ret = MangaRoutePath.lost();
    switch (uri.pathSegments.length) {
      case 0:
        ret = MangaRoutePath.home();
        break;
      case 1:
        if (uri.pathSegments[0] == "search") {
          ret = MangaRoutePath.search(bool.fromEnvironment(args['includeDB']));
        } else if (uri.pathSegments[0] == "manga" &&
            args.containsKey('mangaId')) {
          ret = MangaRoutePath.manga(args['mangaId']);
        } else if (uri.pathSegments[0] == "read" &&
            args.containsKey('mangaId') &&
            args.containsKey('index')) {
          ret = MangaRoutePath.reader(
              args['mangaId'], _toInt(args['index']), _toInt(args['page']));
        }
        break;
      case 2:
        if (uri.pathSegments[0] == 'direct') {
          if (uri.pathSegments[1] == "manga" && args.containsKey('mangaId')) {
            ret = MangaRoutePath.mangaDirect(args['mangaId']);
          } else if (uri.pathSegments[1] == "read" &&
              args.containsKey('mangaId') &&
              args.containsKey('index')) {
            ret = MangaRoutePath.readerDirect(
                args['mangaId'], _toInt(args['index']), _toInt(args['page']));
          }
        }
        break;
    }
    return SynchronousFuture(ret);
  }

  int _toInt(String s) {
    return s != null ? int.tryParse(s) : null;
  }

  @override
  RouteInformation restoreRouteInformation(MangaRoutePath configuration) {
    switch (configuration.routeType) {
      case RouteType.HOME_ROUTE:
        return RouteInformation(location: '/');
      case RouteType.SEARCH_ROUTE:
        return RouteInformation(
            location: '/search?includeDB=${configuration.includeDB}');
      case RouteType.MANGA_PAGE_DIRECT_ROUTE:
        return RouteInformation(
            location: '/direct/manga?mangaId=${configuration.index}');
      case RouteType.MANGA_PAGE_ROUTE:
        return RouteInformation(
            location: '/manga?mangaId=${configuration.index}');
      case RouteType.READER_DIRECT_ROUTE:
        int pg = configuration.pgNum;
        if (pg != null) {
          return RouteInformation(
              location:
                  '/direct/read?mangaId=${configuration.mangaId}&index=${configuration.index}&page=$pg');
        } else {
          return RouteInformation(
              location:
                  '/direct/read?mangaId=${configuration.mangaId}&index=${configuration.index}');
        }
        break;
      case RouteType.READER_ROUTE:
        int pg = configuration.pgNum;
        if (pg != null) {
          return RouteInformation(
              location:
                  '/read?mangaId=${configuration.mangaId}&index=${configuration.index}&page=$pg');
        } else {
          return RouteInformation(
              location:
                  '/read?mangaId=${configuration.mangaId}&index=${configuration.index}');
        }
        break;
      default:
        return RouteInformation(location: '/404');
    }
  }
}

class MangaRouteDelegate extends RouterDelegate<MangaRoutePath>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<MangaRoutePath> {
  final GlobalKey<NavigatorState> navigatorKey;

  final List<Page> pages = [];
  Page homePage;

  MangaRouteDelegate(bool f) : navigatorKey = GlobalKey<NavigatorState>() {
    homePage = MyRoute(
      key: ValueKey('HomePage'),
      builder: (context) => TextScaleFactorClamper(
        child: MyHomePage(
          onSearchPageClick: pushSearchPage,
          onMangaClick: pushMangaPage,
          pushDirectToManga: pushDirectlyToManga,
          pushDirectToReader: pushDirectlyToChapter,
          pushToLost: pushLostPage,
          fcmInit: f,
        ),
      ),
    );
  }

  void pushHomePage() {
    pages.clear();
    notifyListeners();
  }

  void pushLostPage() {
    pages.add(
      MyRoute(
        key: ValueKey('LostPage'),
        builder: (context) => LostPage(),
      ),
    );
    notifyListeners();
  }

  void pushMangaPage(String mangaId) {
    pages.add(
      MyRoute(
        builder: (context) => TextScaleFactorClamper(
          child: MangaPageWidget(
            mangaId: mangaId,
            onChapterClicked: pushReaderPage,
          ),
          key: ValueKey('MangaPage'),
        ),
      ),
    );
    notifyListeners();
  }

  void pushReaderPage(String mangaId, int index, int pgNum) {
    pages.add(
      MyRoute(
        builder: (context) => TextScaleFactorClamper(
          child: ReaderWidget(
            mangaId: mangaId,
            index: index,
            onPageTurned: pageTurnCallback,
            lastSave: pgNum,
          ),
          key: ValueKey('ReaderPage'),
        ),
      ),
    );
    notifyListeners();
  }

  void pushSearchPage(bool includeDB) {
    pages.add(
      MyRoute(
        builder: (context) => TextScaleFactorClamper(
          child: SearchPageWidget(
            includeDBResults: includeDB,
            onClickManga: pushMangaPage,
          ),
          key: ValueKey('SearchPage'),
        ),
      ),
    );
    notifyListeners();
  }

  void pageTurnCallback(int pgNum) {
    notifyListeners();
  }

  void pushDirectlyToManga(String mangaId) {
    pages.clear();
    pushMangaPage(mangaId);
  }

  void pushDirectlyToChapter(String mangaId, int index, int pgNum) {
    pages.clear();
    pages.add(
      MyRoute(
        builder: (context) => TextScaleFactorClamper(
          child: MangaPageWidget(
            mangaId: mangaId,
            onChapterClicked: pushReaderPage,
          ),
          key: ValueKey('MangaPage'),
        ),
      ),
    );
    pushReaderPage(mangaId, index, pgNum);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: List.unmodifiable([
        homePage,
        for (Page p in pages) p,
      ]),
      onPopPage: (route, result) {
        if (!route.didPop(result)) {
          return false;
        }
        pages.removeLast();
        notifyListeners();
        return true;
      },
    );
  }

  @override
  Future<void> setNewRoutePath(MangaRoutePath configuration) {
    switch (configuration.routeType) {
      case RouteType.HOME_ROUTE:
        pushHomePage();
        break;
      case RouteType.SEARCH_ROUTE:
        pushSearchPage(configuration.includeDB);
        break;
      case RouteType.MANGA_PAGE_ROUTE:
        pushMangaPage(configuration.mangaId);
        break;
      case RouteType.READER_ROUTE:
        pushReaderPage(
            configuration.mangaId, configuration.index, configuration.pgNum);
        break;
      case RouteType.MANGA_PAGE_DIRECT_ROUTE:
        pushDirectlyToManga(configuration.mangaId);
        break;
      case RouteType.READER_DIRECT_ROUTE:
        pushDirectlyToChapter(
            configuration.mangaId, configuration.index, configuration.pgNum);
        break;
      case RouteType.LOST_ROUTE:
      default:
        pushLostPage();
    }
    return SynchronousFuture(null);
  }
}

class TextScaleFactorClamper extends StatelessWidget {
  final Widget child;

  const TextScaleFactorClamper({Key key, this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final MediaQueryData data = MediaQuery.of(context);
    final double tScale = data.textScaleFactor.clamp(1.0, 1.5);
    return MediaQuery(
      data: data.copyWith(textScaleFactor: tScale),
      child: child,
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String title;
  final Function(bool) onSearchPageClick;
  final Function(String) onMangaClick;
  final Function(String) pushDirectToManga;
  final Function(String, int, int) pushDirectToReader;
  final Function pushToLost;
  final bool fcmInit;

  const MyHomePage({
    Key key,
    this.title,
    this.onSearchPageClick,
    this.onMangaClick,
    this.pushDirectToManga,
    this.pushDirectToReader,
    this.pushToLost,
    this.fcmInit,
  }) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectionIndex = 0;

  List<Widget> _actualNavs;

  StreamSubscription _streamSubscription;

  String _homeLabel = "Home";

  @override
  void initState() {
    super.initState();
    if (widget.fcmInit) {
      _setupFCM();
    }
    _actualNavs = <Widget>[
      new HomePageWidget(
        onSearchClicked: this.widget.onSearchPageClick,
        onMangaClicked: this.widget.onMangaClick,
      ),
      new FavouritesPageWidget(
        onSearchClicked: this.widget.onSearchPageClick,
        onMangaClicked: this.widget.onMangaClick,
      ),
      new ProfilePageWidget(),
    ];
  }

  @override
  void dispose() {
    super.dispose();
    _streamSubscription?.cancel();
  }

  Future<void> _setupFCM() async {
    RemoteMessage initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      setState(() {
        _homeLabel = "1";
      });
      _handleMessage(initialMessage);
    }
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);
  }

  Future<void> _handleMessage(RemoteMessage message) {
    if (message.data.containsKey('uri')) {
      setState(() {
        _homeLabel += "2";
      });
      tryParseUriHard(Uri.parse(message.data['uri']));
    }
    return SynchronousFuture(null);
  }

  void tryParseUriHard(Uri uri) {
    if (!mounted) {
      Future.doWhile(() => !mounted);
    }
    _parseUri(uri);
  }

  void _parseUri(Uri uri) {
    setState(() {
      _homeLabel += "3";
    });
    if (uri != null) {
      if (uri.pathSegments.length == 2 && uri.pathSegments[0] == 'direct') {
        Map<String, String> args = uri.queryParameters;
        if (uri.pathSegments[1] == "manga" && args.containsKey('mangaId')) {
          this.widget.pushDirectToManga.call(args['mangaId']);
          return;
        } else if (uri.pathSegments[1] == "read" &&
            args.containsKey('mangaId') &&
            args.containsKey('index')) {
          this.widget.pushDirectToReader.call(
              args['mangaId'], _toInt(args['index']), _toInt(args['page']));
          return;
        }
      }
      this.widget.pushToLost.call();
    }
  }

  int _toInt(String s) {
    return s != null ? int.tryParse(s) : null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: _actualNavs[_selectionIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(widget.fcmInit ? Icons.home : Icons.home_outlined),
              label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        currentIndex: _selectionIndex,
        selectedItemColor: Colors.lime,
        onTap: (t) {
          setState(() {
            _selectionIndex = t;
          });
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class HomePageWidget extends StatefulWidget {
  final Function(bool) onSearchClicked;
  final Function(String) onMangaClicked;

  const HomePageWidget({Key key, this.onSearchClicked, this.onMangaClicked})
      : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  Map<int, MangaHeading> _mnc = {};
  MangaQuery _query = MangaQuery();
  bool _loading = false;
  bool _finished = false;
  List<Genre> _genres = [];

  OverlayEntry _genreEntry;
  LayerLink _link;

  ScrollController _scGrid;

  @override
  void initState() {
    super.initState();
    _scGrid = ScrollController();
    _link = LayerLink();
    _scGrid.addListener(() {
      if (_scGrid.offset >= _scGrid.position.maxScrollExtent &&
          !_scGrid.position.outOfRange) {
        fetchManga(_mnc.length);
      }
    });
    fetchBegin();
    fetchGenres();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  void _onClickGenre(BuildContext context) {
    if (_genreEntry == null) {
      _genreEntry = OverlayEntry(
        builder: (context) {
          return Positioned(
            child: CompositedTransformFollower(
              link: _link,
              offset: Offset(0, 20),
              showWhenUnlinked: false,
              followerAnchor: Alignment.topCenter,
              targetAnchor: Alignment.bottomCenter,
              child: Material(
                color: Colors.yellow,
                child: _genres.length == 0
                    ? Text("Loading")
                    : ListView.separated(
                        padding: EdgeInsets.all(0.0),
                        itemBuilder: (context, index) => ListTile(
                          title: Text(
                              index == 0 ? "Clear" : _genres[index - 1].name),
                          onTap: () {
                            if (index == 0) {
                              _query.genres.clear();
                            } else {
                              _query.genres.contains(_genres[index - 1].id)
                                  ? _query.genres.remove(_genres[index - 1].id)
                                  : _query.genres.add(_genres[index - 1].id);
                            }
                            fetchBegin(true);
                            _genreEntry.markNeedsBuild();
                          },
                          selected: index == 0
                              ? false
                              : _query.genres.contains(_genres[index - 1].id),
                          tileColor: Colors.yellow,
                          selectedTileColor: Colors.green,
                        ),
                        separatorBuilder: (context, index) => const Divider(),
                        itemCount: _genres.length + 1,
                      ),
              ),
            ),
          );
        },
      );
      Overlay.of(context).insert(_genreEntry);
    } else {
      _genreEntry.remove();
      // _genreEntry.dispose(); TODO figure out if this is safe
      _genreEntry = null;
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (_genreEntry != null) {
      _genreEntry
        ..remove()
        ..dispose();
      _genreEntry = null;
    }
  }

  void fetchBegin([bool entry = false]) async {
    _loading = true;
    _finished = false;
    List<MangaHeading> hd = await doFetchManga(0, 20);
    int i = -1;
    if (_scGrid.hasClients) {
      _scGrid.jumpTo(0);
    }
    if (mounted) {
      setState(() {
        _mnc.clear();
        while (++i < hd.length) {
          _mnc[i] = hd[i];
        }
      });
    }
    if (entry) {
      _genreEntry?.markNeedsBuild();
    }
    _loading = false;
  }

  Future<List<MangaHeading>> doFetchManga(int offset, [int length]) async {
    _query.offset = offset;
    _query.limit = length;
    _query.renew();
    MangaQueryResponse res = await APIer.fetchHome(_query);
    if (res.headings.length < length) {
      _finished = true;
    }
    return res.headings;
  }

  void fetchManga(int offset, [int length = 10]) async {
    if (_loading) {
      return;
    }
    _loading = true;
    List<MangaHeading> hd = await doFetchManga(offset, length);
    if (mounted) {
      setState(() {
        int i = 0;
        while (i < hd.length) {
          _mnc[offset++] = hd[i++];
        }
      });
    }
    _loading = false;
  }

  void fetchGenres() async {
    List<Genre> gen = await APIer.fetchGenres();
    for (Genre g in gen) {
      g.name = g.name[0].toUpperCase() + g.name.substring(1).toLowerCase();
    }
    if (mounted) {
      setState(() {
        _genres = gen;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      controller: _scGrid,
      slivers: [
        SliverAppBar(
          title: Text("Home"),
          expandedHeight: 0.0,
          floating: true,
          snap: false,
          pinned: true,
          actions: [
            CompositedTransformTarget(
              link: _link,
              child: IconButton(
                icon: Icon(Icons.filter_alt_outlined),
                onPressed: () => _onClickGenre(context),
              ),
            ),
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                this.widget.onSearchClicked.call(false);
              },
            ),
          ],
        ),
        SliverPadding(
          padding: EdgeInsets.only(top: 16.0),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                if (index == _mnc.length) {
                  fetchManga(_mnc.length);
                  return CenteredFixedCircle();
                }
                return InkWell(
                  child: MangaCover(
                    name: _mnc[index].name,
                    coverURL: _mnc[index].coverURL,
                  ),
                  onTap: () {
                    this.widget.onMangaClicked.call(_mnc[index].id);
                    // Navigator.pushNamed(context, '/manga', arguments: APIer.fetchManga(e.id));
                  },
                );
              },
              childCount: _finished ? _mnc.length : _mnc.length + 1,
            ),
          ),
        ),
      ],
    );
  }
}

class FavouritesPageWidget extends StatefulWidget {
  final Function(bool) onSearchClicked;
  final Function(String) onMangaClicked;

  const FavouritesPageWidget(
      {Key key, this.onSearchClicked, this.onMangaClicked})
      : super(key: key);

  @override
  _FavouritesPageWidgetState createState() => _FavouritesPageWidgetState();
}

class _FavouritesPageWidgetState extends State<FavouritesPageWidget> {
  double boxSide;

  SavedMangaTable _table;

  updateDisplay() {
    if (this.mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    _table = DBer.getTable();
    _table.addListener(this.updateDisplay);
  }

  @override
  void dispose() {
    super.dispose();
    _table.doDispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    boxSide = (MediaQuery.of(this.context).size.width - 4 * 16) / 3;
  }

  void _move<T>(int from, int to, List<T> items) {
    T item = items.removeAt(from);
    items.insert(to, item);
  }

  List<Widget> parse(Iterable<SavedManga> all, List<Widget> renderedManga,
      List<SavedManga> savedManga) {
    if (all != null) {
      savedManga.addAll(all);
      savedManga.sort((a, b) => a.index - b.index);
      savedManga.forEach(
        (e) => renderedManga.add(
          InkWell(
            child: FavouriteManga(
              name: e.name,
              coverURL: e.coverURL,
              side: boxSide,
            ),
            onTap: () {
              this.widget.onMangaClicked.call(e.id);
              // Navigator.pushNamed(context, '/manga', arguments: APIer.fetchManga(e.id));
            },
          ),
        ),
      );
    }
    return renderedManga;
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> renderedManga = [];
    List<SavedManga> savedManga = [];
    if (_table == null) {
      return CenteredFixedCircle();
    } else {
      parse(_table.getList, renderedManga, savedManga);
      return Scaffold(
        appBar: AppBar(
          title: Text("Favourites"),
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                this.widget.onSearchClicked.call(true);
                // Navigator.pushNamed(context, '/search', arguments: true);
              },
            ),
          ],
        ),
        backgroundColor: Colors.black,
        body: Align(
          alignment: Alignment.topLeft,
          child: SingleChildScrollView(
            child: Container(
                padding: EdgeInsets.all(16.0),
                child: ReorderableWrap(
                    needsLongPressDraggable: false,
                    spacing: 16.0,
                    children: renderedManga,
                    maxMainAxisCount: 3,
                    minMainAxisCount: 3,
                    runSpacing: 16.0,
                    onReorder: (from, to) {
                      String id1 = savedManga[from].id;
                      String id2 = savedManga[to].id;
                      _move(from, to, savedManga);
                      _move(from, to, renderedManga);
                      DBer.reorder(id1, id2);
                    })),
          ),
        ),
      );
    }
  }
}

class SearchPageWidget extends StatefulWidget {
  final bool includeDBResults;
  final Function(String) onClickManga;

  const SearchPageWidget({Key key, this.includeDBResults, this.onClickManga})
      : super(key: key);

  @override
  _SearchPageWidgetState createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> {
  List<MangaHeading> _hdFromDB = [];
  Map<int, MangaHeading> _hdFromAPI = <int, MangaHeading>{};

  ScrollController _sc = new ScrollController();

  bool _isLoading = false;
  MangaQuery _mangaQuery;
  int _t = DateTime.now().millisecondsSinceEpoch;
  int _rateLimitFetchMore = 500;

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _mangaQuery = MangaQuery();
    _sc.addListener(() {
      if (_sc.offset >= _sc.position.maxScrollExtent &&
          !_sc.position.outOfRange) {
        fetchMore();
      }
    });
    fetchMore();
  }

  @override
  void dispose() {
    _sc.dispose();
    super.dispose();
  }

  void fetchFromDatabase() {
    DBer.fromQuery(_mangaQuery).then(
      (value) => setState(
        () {
          _hdFromDB = value.toList();
        },
      ),
    );
  }

  bool fetchMore([int limit = 10]) {
    if (!_isLoading ||
        DateTime.now().millisecondsSinceEpoch - _t > _rateLimitFetchMore) {
      _t = DateTime.now().millisecondsSinceEpoch;
      fetch(limit);
      return true;
    } else {
      return false;
    }
  }

  void fetch([int limit = 10]) {
    startedLoading();
    _mangaQuery.limit = limit;
    _mangaQuery.offset = _hdFromAPI.length;
    APIer.fetchSearch(_mangaQuery).then((value) {
      if (_mangaQuery == value.query) {
        if (value.headings.isEmpty || value.headings.length != limit) {
          _finished = true;
        }
        for (int i = 0, j = 0; i < value.headings.length; i++) {
          if (_hdFromDB.contains(value.headings[i])) {
            continue;
          }
          processHeading(value.headings[i]);
          _hdFromAPI.update(value.query.offset + j, (old) => value.headings[i],
              ifAbsent: () => value.headings[i]);
          j++;
        }
      }
      stoppedLoading();
    });
  }

  void fetchAgain() {
    _hdFromAPI.clear();
    _finished = false;
    if (this.widget.includeDBResults) {
      _hdFromDB.clear();
      fetchFromDatabase();
    }
    fetch();
  }

  void stoppedLoading() {
    setState(() {
      _isLoading = false;
    });
  }

  void startedLoading() {
    setState(() {
      _isLoading = true;
    });
  }

  void processHeading(MangaHeading hd) {
    int x = hd.description.length;
    if (x >= 255) {
      hd.description = hd.description.substring(0, 253) + "...";
    }
  }

  bool onDismiss(MangaHeading hd, DismissDirection dir) {
    if (dir == DismissDirection.startToEnd) {
      DBer.saveMangaHeading(hd);
      return true;
    } else if (dir == DismissDirection.endToStart) {
      DBer.removeManga(hd.id);
      return false;
    }
    throw new UnsupportedError("How did you even manage to do this?");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.black,
        body: NotificationListener<ScrollStartNotification>(
            onNotification: (x) {
              if (x.dragDetails == null) {}
              FocusScope.of(context).unfocus();
              return false;
            },
            child: CustomScrollView(
              controller: _sc,
              slivers: [
                SliverAppBar(
                  title: Container(
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Search text',
                        fillColor: Colors.white,
                        filled: true,
                      ),
                      onChanged: (text) {
                        _mangaQuery
                          ..renew()
                          ..name = text;
                        fetchAgain();
                      },
                      autofocus: true,
                    ),
                    margin: EdgeInsets.all(16.0),
                  ),
                  expandedHeight: 100.0,
                  floating: true,
                ),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (buildContext, index) {
                      if (index == _hdFromAPI.length + _hdFromDB.length) {
                        return CenteredFixedCircle();
                      } else {
                        MangaHeading hd1;
                        if (index < _hdFromDB.length) {
                          hd1 = _hdFromDB[index];
                        } else {
                          index -= _hdFromDB.length;
                          hd1 = _hdFromAPI[index];
                        }
                        return InkWell(
                          child: MangaThumbnail(
                            hd: hd1,
                            onDismiss: (d) => onDismiss(hd1, d),
                            isSaved: DBer.isSaved(hd1.id),
                          ),
                          onTap: () {
                            this.widget.onClickManga(hd1.id);
                            // this.widget.pushCallback.call('/manga', argument: APIer.fetchManga(hd1.id));
                            // Navigator.pushNamed(context, "/manga", arguments: APIer.fetchManga(hd1.id));
                          },
                        );
                      }
                    },
                    childCount: _finished
                        ? (_hdFromAPI.length + _hdFromDB.length)
                        : (_hdFromAPI.length + _hdFromDB.length + 1),
                  ),
                ),
              ],
            )));
  }
}

class ProfilePageWidget extends StatefulWidget {
  const ProfilePageWidget({Key key}) : super(key: key);

  @override
  _ProfilePageWidgetState createState() => _ProfilePageWidgetState();
}

class _ProfilePageWidgetState extends State<ProfilePageWidget> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}

class MangaPageWidget extends StatefulWidget {
  final String mangaId;
  final Function(String, int, int) onChapterClicked;

  const MangaPageWidget({Key key, this.mangaId, this.onChapterClicked})
      : super(key: key);

  @override
  _MangaPageWidgetState createState() => _MangaPageWidgetState();
}

class _MangaPageWidgetState extends State<MangaPageWidget> {
  ScrollController _sc;
  Future<CompleteManga> _mn;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _mn = APIer.fetchManga(this.widget.mangaId);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sc = ScrollController(
        initialScrollOffset: MediaQuery.of(context).size.height / 2);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _mn,
      builder: (context, snapshot) {
        CompleteManga com = snapshot.data;
        if (snapshot.hasData) {
          return Scaffold(
            backgroundColor: Colors.black,
            body: NestedScrollView(
              controller: _sc,
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverAppBar(
                    title: Text(com.title),
                    expandedHeight: MediaQuery.of(context).size.height,
                    pinned: true,
                    flexibleSpace: FlexibleSpaceBar(
                      titlePadding: EdgeInsets.all(16.0),
                      //TODO think about this because title text also becomes invisible
                      background: Container(
                        color: Colors.black,
                        child: CachedNetworkImage(
                          imageUrl: com.coverURL,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                ];
              },
              body: MangaPage(
                manga: com,
                onClickChapter: widget.onChapterClicked,
              ),
            ),
          );
        } else if (snapshot.hasError) {
          return LostPage();
        } else {
          return CenteredFixedCircle();
        }
      },
    );
  }
}

class ReaderWidget extends StatefulWidget {
  // final double settingsWidth = 100;
  static final double settingsHeight = 100;
  static final int maxCacheCount = 1;

  final String mangaId;
  final int index;
  final int lastSave;
  final Function(int) onPageTurned;

  const ReaderWidget(
      {Key key, this.mangaId, this.index, this.lastSave, this.onPageTurned})
      : super(key: key);

  @override
  _ReaderWidgetState createState() => _ReaderWidgetState();
}

class _ReaderWidgetState extends State<ReaderWidget>
    with SingleTickerProviderStateMixin {
  static const int _LEFT_TO_RIGHT = 0;
  static const int _RIGHT_TO_LEFT = 1;
  static const int _UP_TO_DOWN = 2;

  // static final DateFormat _formatter = DateFormat.jm();
  static final Battery _battery = Battery();

  static const int thresholdForWheelPopOut = 30;
  static const double wheelRadius = 80.0;

  Chapters _current;

  bool _visible = false;
  RestartableTimer _timer;
  AnimationController _animationControllerForAppBar;

  double _currentWheelRotation = 0;

  ScrollSynchronizer _synchronizer;

  int _formalIndexAtStartOfCurrentChapter = 0;
  int _formalIndexForList = 0;
  int _requestedNextChapterLoadIndex = -1;
  int _requestedPreviousChapterLoadIndex = -1;
  Map<int, CompleteChapter> _chapIndexToChapter = {};
  Map<int, int> _chapStartsToChapIndex = {};
  List<int> _chapStarts = [];

  String _currentChapterId;
  int _currIndex;

  OverlayEntry _settings;
  LayerLink _link;

  OverlayEntry _wheel;
  Offset _center;

  int _displayMode = _RIGHT_TO_LEFT;

  int _upperBoundIndex = -1;

  // int _currPage;
  // int _currChapLength;
  // Stream<ReaderInfo> _datStream;

  ValueListenable<CompleteReaderInfo> _listenableInfo;

  CompleteReaderInfo _info;

  bool disposed = false;

  @override
  void initState() {
    super.initState();
    _current = Memory.remember(this.widget.mangaId, this.widget.index);
    _link = LayerLink();
    _timer = RestartableTimer(Duration(seconds: 2), collapseTopBar);
    // _datStream = infoStream(_battery);
    Stream<DateTime> datStream =
        Stream.periodic(Duration(milliseconds: 500), (n) => DateTime.now());
    _info = CompleteReaderInfo(datStream, batStream(_battery), null, null);
    _animationControllerForAppBar = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    setup();
  }

  void setup() async {
    if (_current == null || _current.chaps[_current.currentIndex] == null) {
      LinkedManga part = await APIer.fetchPartManga(this.widget.mangaId);
      _current = Chapters.all(
          mangaId: part.id,
          linkedId: part.linkedId,
          chaps: part.chapters,
          s: part.source,
          currentIndex: this.widget.index);
      Memory.retainLinked(part);
    }
    ChapterPosition position = await APIer.fetchChapterPageNumber(
        _current.mangaId, _current.chaps[_current.currentIndex].sequenceNumber);
    int displayMode = await DBer.getPreferredScrollStyle(_current.mangaId);
    if (displayMode != null) {
      _displayMode = displayMode;
    } else {
      DBer.updatePreferredScrollStyle(_current.mangaId, _displayMode);
    }
    int pgNum = position.index;
    _upperBoundIndex = position.length;
    _currentChapterId = _current.chaps[_current.currentIndex].id;
    int currNum;
    if (this.widget.lastSave == null) {
      currNum = await DBer.getLastReadPage(_currentChapterId);
      if (currNum == null) {
        currNum = 0;
      }
    } else {
      currNum = this.widget.lastSave;
    }
    _currIndex = currNum;
    DBer.readChapter(_current.mangaId, _current.linkedId,
        _current.chaps[_current.currentIndex].id, currNum);
    _formalIndexAtStartOfCurrentChapter = (pgNum);
    _formalIndexForList = _formalIndexAtStartOfCurrentChapter + currNum;
    PageController pageController = PageController(
        initialPage: _formalIndexAtStartOfCurrentChapter + currNum,
        keepPage: false);
    ItemScrollController scrollController = ItemScrollController();
    ItemPositionsListener scrollListener = ItemPositionsListener.create();
    _synchronizer = new ScrollSynchronizer();
    _synchronizer.attachPageControllerToAll(
        [_LEFT_TO_RIGHT, _RIGHT_TO_LEFT], pageController);
    _synchronizer.attachListController(
        _UP_TO_DOWN, scrollController, scrollListener);

    _synchronizer.listen((t) {
      _listen(t.getIndex());
    });

    assembleProper(_formalIndexAtStartOfCurrentChapter, currNum);
  }

  Stream<ReaderInfo> infoStream(Battery b) async* {
    while (this.mounted) {
      yield ReaderInfo(DateTime.now(), await b.batteryLevel);
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  Stream<int> batStream(Battery b) async* {
    while (this.mounted) {
      yield await b.batteryLevel;
      await Future.delayed(Duration(milliseconds: 500));
    }
  }

  void _listen(int index) {
    int chapStart = findChapStart(index);
    int chapIndex = chapStart > -1 ? _chapStartsToChapIndex[chapStart] : -1;
    if (chapIndex < 0) {
      return;
    }
    int nCurr = index - chapStart + 1;
    int nIn = nCurr - 1;
    if (_currentChapterId != _current.chaps[chapIndex].id) {
      _currentChapterId = _current.chaps[chapIndex].id;
      DBer.readChapter(
          _current.mangaId, _current.linkedId, _currentChapterId, nIn);
    }
    if (nIn != _currIndex) {
      _currIndex = nIn;
      DBer.updateChapterPage(_currentChapterId, nIn);
      this.widget.onPageTurned.call(nCurr);
    }
    int plusOne = chapIndex + 1;
    int minusOne = chapIndex - 1;
    if (plusOne < _current.chaps.length &&
        !_chapIndexToChapter.containsKey(plusOne) &&
        _requestedNextChapterLoadIndex != plusOne) {
      _requestedNextChapterLoadIndex = plusOne;
      populateChapter(plusOne).then((value) {
        int fps =
            chapStart + _chapIndexToChapter[chapIndex].content.urls.length;
        addProper(_chapStarts, fps);
        _chapStartsToChapIndex.putIfAbsent(fps, () => plusOne);
      });
    }
    if (minusOne > -1 &&
        !_chapIndexToChapter.containsKey(minusOne) &&
        _requestedPreviousChapterLoadIndex != minusOne) {
      _requestedPreviousChapterLoadIndex = minusOne;
      populateChapter(minusOne).then((value) {
        int fps = chapStart - value.content.urls.length;
        addProper(_chapStarts, fps);
        _chapStartsToChapIndex.putIfAbsent(fps, () => minusOne);
      });
    }
    int nLen = _chapIndexToChapter[chapIndex].content.urls.length;
    if (nCurr != _info.chapPage) {
      _info.chapPage = nCurr;
    }
    if (nLen != _info.chapLen) {
      _info.chapLen = nLen;
    }
  }

  Future<CompleteChapter> getChapter(int index) {
    if (index >= _current.chaps.length) {
      throw new Exception("index out of bounds");
    } else if (index < 0) {
      throw new Exception("index out of bounds");
    }
    ChapterData dt = _current.chaps[index];
    return APIer.fetchChapter(dt.id)
        .then((value) => CompleteChapter.all(dt.id, value, dt, _current.s));
  }

  void assembleProper(int formalPageStart, int currPage) async {
    int x = _current.currentIndex;
    CompleteChapter current = await populateChapter(x);
    addProper(_chapStarts, formalPageStart);
    _chapStartsToChapIndex.putIfAbsent(formalPageStart, () => x);
    _info.chapPage = currPage + 1;
    _info.chapLen = current.content.urls.length;
    int plusOne = _current.currentIndex + 1;
    if (plusOne < _current.chaps.length) {
      _requestedNextChapterLoadIndex = plusOne;
      await populateChapter(plusOne);
      int fps = formalPageStart + current.content.urls.length;

      addProper(_chapStarts, fps);
      _chapStartsToChapIndex.putIfAbsent(fps, () => plusOne);
    }
    int minusOne = _current.currentIndex - 1;
    if (minusOne > -1) {
      _requestedPreviousChapterLoadIndex = minusOne;
      CompleteChapter prevOne = await populateChapter(minusOne);
      int fps = formalPageStart - prevOne.content.urls.length;

      addProper(_chapStarts, fps);
      _chapStartsToChapIndex.putIfAbsent(fps, () => minusOne);
    }
  }

  Future<CompleteChapter> populateChapter(int index) {
    return getChapter(index).then((value) {
      _chapIndexToChapter.update(index, (v) => value, ifAbsent: () => value);
      return value;
    });
  }

  int findChapIndex(int formalPageNumber) {
    int x = findChapStart(formalPageNumber);
    return x < 0 ? -1 : _chapStartsToChapIndex[x];
  }

  int findChapStart(int formalPageNumber) {
    int x =
        _chapStarts.lastIndexWhere((element) => formalPageNumber >= element);
    return x < 0 ? -1 : _chapStarts[x];
  }

  void addProper(List<int> sortedList, int add) {
    int min = 0;
    int max = sortedList.length;
    while (min < max) {
      final int mid = min + ((max - min) >> 1);
      final int element = sortedList[mid];
      final int comp = element.compareTo(add);
      if (comp == 0) {
        return;
      }
      if (comp < 0) {
        min = mid + 1;
      } else {
        max = mid;
      }
    }
    sortedList.insert(min, add);
  }

  void toggleScrollWheel(LongPressStartDetails deets) {
    if (_wheel == null) {
      bool b1;
      double width = MediaQuery.of(context).size.width;
      if (deets.localPosition.dx <= thresholdForWheelPopOut) {
        b1 = true;
        _center = Offset(0, wheelRadius);
      } else if (deets.localPosition.dx >= width - thresholdForWheelPopOut) {
        b1 = false;
        _center = Offset(wheelRadius, wheelRadius);
      } else {
        return;
      }
      initWheel(b1, deets.localPosition.dy);
      Overlay.of(context).insert(_wheel);
    } else {
      collapseWheel();
    }
  }

  collapseWheel() {
    _wheel.remove();
    _wheel = null;
  }

  initWheel(bool isLeft, double top) {
    _wheel = OverlayEntry(builder: (context) {
      return Positioned(
        width: wheelRadius,
        height: wheelRadius * 2,
        left: isLeft ? 0 : null,
        right: isLeft ? null : 0,
        top: top - wheelRadius,
        child: GestureDetector(
          onPanUpdate: handleWheelScrollUpdate,
          // onPanEnd: ,
          child: CustomPaint(
            painter: SideWheel(
              currentRotationAngle: _currentWheelRotation,
              startFromLeft: isLeft,
              center: _center,
              radius: wheelRadius,
            ),
            // size: Size(wheelRadius, wheelRadius * 2),
          ),
        ),
      );
    });
  }

  void handleWheelScrollUpdate(DragUpdateDetails deets) {
    double newAngle =
        atan(deets.delta.dy - _center.dy / deets.delta.dx - _center.dx);
    setState(() {
      _currentWheelRotation = radiansToDegrees(newAngle + pi);
    });
  }

  double radiansToDegrees(double radians) {
    return radians * 180 / pi;
  }

  void toggleTopBar() {
    if (_wheel != null) {
      collapseWheel();
      return;
    }
    _timer.cancel();
    if (!_visible) {
      expandTopBar();
      _timer.reset();
    } else {
      collapseTopBar();
    }
  }

  void expandTopBar() {
    setState(() {
      _visible = true;
    });
  }

  void collapseTopBar() {
    if (_settings != null) {
      _settings.remove();
      _settings = null;
    }
    setState(() {
      _visible = false;
    });
  }

  void onPressSettings(BuildContext context) {
    _timer.reset();
    if (_settings == null) {
      initSettings();
      Overlay.of(context).insert(_settings);
    } else {
      _settings.remove();
      _settings = null;
    }
  }

  void initSettings() {
    _settings = OverlayEntry(builder: (context) {
      return Positioned(
        height: ReaderWidget.settingsHeight,
        child: CompositedTransformFollower(
          link: _link,
          followerAnchor: Alignment.topRight,
          targetAnchor: Alignment.bottomRight,
          showWhenUnlinked: false,
          offset: Offset(0, 20),
          child: ReaderPageSettingsPanel(
            onLeftToRight: () {
              IndexedScrollController old;
              if ((old = _synchronizer.get(_displayMode))
                  is! PageScrollController) {
                PageController controller = PageController(
                    initialPage: old.getIndex(), keepPage: false);
                _synchronizer
                    .get(_LEFT_TO_RIGHT)
                    .setUnderlyingController(controller);
              }
              DBer.updatePreferredScrollStyle(_current.mangaId, _LEFT_TO_RIGHT);
              setState(() => _displayMode = _LEFT_TO_RIGHT);
            },
            onRightToLeft: () {
              IndexedScrollController old;
              if ((old = _synchronizer.get(_displayMode))
                  is! PageScrollController) {
                PageController controller = PageController(
                    initialPage: old.getIndex(), keepPage: false);
                _synchronizer
                    .get(_RIGHT_TO_LEFT)
                    .setUnderlyingController(controller);
              }
              DBer.updatePreferredScrollStyle(_current.mangaId, _RIGHT_TO_LEFT);
              setState(() => _displayMode = _RIGHT_TO_LEFT);
            },
            onUpToDown: () {
              _formalIndexForList = _synchronizer.get(_displayMode).getIndex();
              DBer.updatePreferredScrollStyle(_current.mangaId, _UP_TO_DOWN);
              setState(() => _displayMode = _UP_TO_DOWN);
            },
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    this.disposed = true;
    _timer.cancel();
    if (_settings != null) {
      _settings.remove();
      Future.delayed(Duration(milliseconds: 100), () => _settings.dispose());
    }
    if (_wheel != null) {
      _wheel.remove();
      Future.delayed(Duration(milliseconds: 100), () => _wheel.dispose());
    }
    _synchronizer.dispose();
    _animationControllerForAppBar.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = "";
    if (_synchronizer == null) {
      return CenteredFixedCircle();
    }
    IndexedScrollController con = _synchronizer.get(_displayMode);
    if (con.isInUse()) {
      int chapIndex = findChapIndex(con.getIndex());
      if (chapIndex > -1) {
        CompleteChapter chp1 = _chapIndexToChapter[chapIndex];
        displayName = chp1.dt.chapterNumber;
      }
    }
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: ReaderAppBar(
        child: AppBar(
          title: Text(displayName),
          centerTitle: true,
          actions: [
            CompositedTransformTarget(
              link: _link,
              child: IconButton(
                  icon: Icon(Icons.settings),
                  onPressed: () => onPressSettings(context)),
            )
          ],
        ),
        controller: _animationControllerForAppBar,
        visible: _visible,
      ),
      body: ChangeNotifierProvider.value(
        value: _info,
        child: GestureDetector(
          onTap: () => toggleTopBar(),
          //TODO in v2
          // onLongPressStart: (t) => toggleScrollWheel(t),
          child: Stack(
            children: [
              _displayMode == _UP_TO_DOWN
                  ? ScrollablePositionedList.builder(
                      initialScrollIndex: _formalIndexForList,
                      itemPositionsListener: _synchronizer
                          .get(_displayMode)
                          .getUnderlyingListener() as ItemPositionsListener,
                      itemScrollController: _synchronizer
                          .get(_displayMode)
                          .getUnderlyingController() as ItemScrollController,
                      initialAlignment: 0,
                      itemCount: _upperBoundIndex,
                      itemBuilder: (context, index) {
                        int x1 = findChapStart(index);
                        Widget w;
                        if (x1 < 0) {
                          w = CenteredFixedCircle();
                        } else {
                          int pgNum = index - x1;
                          int chapNum = _chapStartsToChapIndex[x1];
                          CompleteChapter chp = _chapIndexToChapter[chapNum];
                          if (pgNum >= chp.content.urls.length) {
                            w = CenteredFixedCircle();
                          } else {
                            w = InteractiveViewer(
                              child: ChapterPageForVertical(
                                url: chp.content.urls[pgNum],
                                s: chp.source,
                                width: MediaQuery.of(context).size.width,
                              ),
                            );
                          }
                        }
                        return w;
                      },
                    )
                  : PageView.builder(
                      allowImplicitScrolling: true,
                      controller: _synchronizer
                          .get(_displayMode)
                          .getUnderlyingController() as PageController,
                      reverse: _displayMode == _RIGHT_TO_LEFT,
                      itemCount: _upperBoundIndex,
                      itemBuilder: (context, index) {
                        Widget w;
                        int x1 = findChapStart(index);
                        if (x1 < 0) {
                          w = CenteredFixedCircle();
                        } else {
                          int pgNum = index - x1;
                          int chapNum = _chapStartsToChapIndex[x1];
                          CompleteChapter chp = _chapIndexToChapter[chapNum];
                          if (pgNum >= chp.content.urls.length) {
                            w = CenteredFixedCircle();
                          } else {
                            w = Center(
                              child: InteractiveViewer(
                                child: ChapterPageForHorizontal(
                                  url: chp.content.urls[pgNum],
                                  s: chp.source,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          }
                        }
                        return SafeArea(child: w);
                      },
                    ),
              Positioned(
                  bottom: 0,
                  right: 0,
                  child: SafeArea(
                      child: Consumer<CompleteReaderInfo>(
                    builder: (context, info, child) =>
                        ReaderPageInfoPanel(info),
                  ))),
            ],
          ),
        ),
      ),
    );
  }
}

class ScrollSynchronizer {
  Map<int, IndexedScrollController> _storage = LinkedHashMap();
  List<IndexedScrollController> _controllers = [];

  void attachPageController(int marker, PageController controller) {
    PageScrollController con = PageScrollController(controller);
    _storage[marker] = con;
    _controllers.add(con);
  }

  void attachPageControllerToAll(List<int> markers, PageController controller) {
    PageScrollController con = PageScrollController(controller);
    markers.forEach((element) => _storage[element] = con);
    _controllers.add(con);
  }

  void attachListController(int marker, ItemScrollController controller,
      ItemPositionsListener listener) {
    ListScrollController con = ListScrollController(controller, listener);
    _storage[marker] = con;
    _controllers.add(con);
  }

  IndexedScrollController get(int marker) {
    return _storage[marker];
  }

  void listen(Function(IndexedScrollController) listener) {
    this
        ._controllers
        .forEach((value) => value.listen(() => listener.call(value)));
  }

  void dispose() {
    this._controllers.forEach((value) => value.dispose());
  }
}

abstract class IndexedScrollController {
  int getIndex();

  jumpTo(int index);

  void listen(Function listener);

  Object getUnderlyingController();

  Object getUnderlyingListener();

  void setUnderlyingController(Object controller);

  bool isInUse();

  void dispose();
}

class PageScrollController extends IndexedScrollController {
  PageController _controller;

  Set<Function> _listeners = HashSet();

  PageScrollController(this._controller);

  @override
  int getIndex() {
    return this._controller.page.toInt();
  }

  @override
  PageController getUnderlyingController() {
    return this._controller;
  }

  @override
  ItemPositionsListener getUnderlyingListener() {
    throw UnsupportedError("Doesn't make sense");
  }

  @override
  void setUnderlyingController(Object controller) {
    this._controller.dispose();
    this._controller = controller as PageController;
    _listeners.forEach((element) => this._controller.addListener(element));
  }

  @override
  jumpTo(int index) {
    this._controller.jumpToPage(index);
  }

  @override
  bool isInUse() {
    return this._controller.hasClients;
  }

  @override
  void listen(Function listener) {
    if (!_listeners.contains(listener)) {
      _listeners.add(listener);
      this._controller.addListener(listener);
    }
  }

  @override
  void dispose() {
    this._controller.dispose();
  }
}

class ListScrollController extends IndexedScrollController {
  ItemScrollController _controller;
  ItemPositionsListener _listener;

  ListScrollController(this._controller, this._listener);

  @override
  int getIndex() {
    return this._listener.itemPositions.value.first.index;
  }

  @override
  ItemScrollController getUnderlyingController() {
    return this._controller;
  }

  @override
  ItemPositionsListener getUnderlyingListener() {
    return this._listener;
  }

  @override
  void setUnderlyingController(Object controller) {
    throw UnsupportedError("This is ugly");
  }

  @override
  bool isInUse() {
    return this._controller.isAttached;
  }

  @override
  jumpTo(int index) {
    this._controller.jumpTo(index: index, alignment: 0);
  }

  @override
  void listen(Function listener) {
    this._listener.itemPositions.addListener(listener);
  }

  @override
  void dispose() {
    //do nothing
  }
}

class RestartableTimer {
  Timer _timer;

  final Duration _duration;

  final ZoneCallback _callback;

  RestartableTimer(this._duration, this._callback)
      : _timer = Timer(_duration, _callback);

  void reset() {
    _timer.cancel();
    _timer = Timer(_duration, _callback);
  }

  void cancel() {
    _timer.cancel();
  }
}

class CenteredFixedCircle extends StatelessWidget {
  const CenteredFixedCircle({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: SizedBox(
            width: 30, height: 30, child: CircularProgressIndicator()));
  }
}

class InfoPanelData {
  String batteryLevel;
  String time;

  InfoPanelData(this.batteryLevel, this.time);
}

class DevHttpsOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
