import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:battery_plus/battery_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:reorderables/reorderables.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'api_objects.dart';
import 'visual_objects.dart';

void main() async {
  HttpOverrides.global = new DevHttpsOverides();
  MangaPageChapterPanel.onClick = (c, t, f) {
    if (t.chaps[t.currentIndex] != null) {
      // Navigator.pushNamed(c, "/read", arguments: ReadArguments.all(t, DBer.getLastReadPage(t.chaps[t.currentIndex].id)));
      f.call('/read', argument: ReadArguments.all(t, DBer.getLastReadPage(t.chaps[t.currentIndex].id)));
    }
  };
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
          return CenteredFixedCircle();
        } else if (snapshot.connectionState == ConnectionState.done) {
          //TODO check if this works
          FirebaseMessaging.instance.requestPermission();
          return AppHome();
        } else {
          return CenteredFixedCircle();
        }
      },
    );
  }
}

class MyRoute<T> extends Page<T> {
  final WidgetBuilder builder;

  const MyRoute({this.builder, String name, Key key}) : super(key: key, name: name);

  @override
  Route<T> createRoute(BuildContext context) {
    return MaterialPageRoute(
      builder: this.builder,
      settings: this,
    );
  }
}

class AppHome extends StatefulWidget {
  const AppHome({Key key}) : super(key: key);

  @override
  _AppHomeState createState() => _AppHomeState();
}

class _AppHomeState extends State<AppHome> {
  final List<Page> pages = [];
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    pages.add(MyRoute(
      builder: (context) => MyHomePage(
        pushCallback: pushCallback,
      ),
      key: const Key("HomePage"),
    ));
  }

  bool _onPopPage(Route<dynamic> route, dynamic result) {
    pages.remove(route.settings);
    return route.didPop(result);
  }

  void pushCallback(String routeName, {dynamic argument}) {
    final Uri path = Uri.parse(routeName);
    for (String segment in path.pathSegments) {
      if (segment == 'search') {
        pages.add(MyRoute(
          builder: (context) => SearchPageWidget(
            includeDBResults: argument as bool,
            pushCallback: pushCallback,
          ),
          key: const Key("SearchPage"),
        ));
      } else if (segment == 'manga') {
        pages.add(MyRoute(
          builder: (context) => MangaPageWidget(
            current: argument as Future<CompleteManga>,
            pushCallback: pushCallback,
          ),
          key: const Key("MangaPage"),
        ));
      } else if (segment == 'read') {
        ReadArguments arg = argument as ReadArguments;
        pages.add(MyRoute(
          builder: (context) => ReaderWidget(
            current: arg.t,
            lastSave: arg.page,
            pushCallback: pushCallback,
          ),
          key: const Key("ReadPage"),
        ));
      } else {
        pages.add(MyRoute(
          builder: (context) => LostPage(),
          key: const Key("LostPage"),
        ));
        break;
      }
    }
    setState(() {});
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
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
      home: WillPopScope(
        onWillPop: () async => !await _navigatorKey.currentState.maybePop(),
        child: Navigator(
          key: _navigatorKey,
          pages: List.unmodifiable(pages),
          onPopPage: _onPopPage,
        ),
      ),
      // home: MyHomePage(),
      // onGenerateRoute: (settings) {
      //   if (settings.name == '/search') {
      //     return MaterialPageRoute(
      //       builder: (context) => SearchPageWidget(
      //         includeDBResults: settings.arguments as bool,
      //       ),
      //     );
      //   } else if (settings.name == '/manga') {
      //     return MaterialPageRoute(
      //       builder: (context) => MangaPageWidget(
      //         current: settings.arguments as Future<CompleteManga>,
      //       ),
      //     );
      //   } else if (settings.name == '/read') {
      //     ReadArguments arg = settings.arguments as ReadArguments;
      //     return MaterialPageRoute(
      //       builder: (context) => ReaderWidget(
      //         current: arg.t,
      //         lastSave: arg.page,
      //       ),
      //     );
      //   }
      //   return null;
      // },
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

// enum RouteType { HOME_ROUTE, SEARCH_ROUTE, MANGA_PAGE_ROUTE, READER_ROUTE, LOST_ROUTE }
//
// class MangaRoutePath {
//   RouteType routeType;
//   String id;
//   ReadArguments rd;
//   Future<CompleteManga> current;
//
//   MangaRoutePath({this.routeType, this.id, this.rd, this.current});
//
//   factory MangaRoutePath.home() {
//     return new MangaRoutePath(
//       routeType: RouteType.HOME_ROUTE,
//     );
//   }
//
//   factory MangaRoutePath.search() {
//     return new MangaRoutePath(
//       routeType: RouteType.SEARCH_ROUTE,
//     );
//   }
//
//   factory MangaRoutePath.manga(Future<CompleteManga> current) {
//     return new MangaRoutePath(
//       routeType: RouteType.MANGA_PAGE_ROUTE,
//       current: current,
//     );
//   }
//
//   factory MangaRoutePath.reader(ReadArguments rd) {
//     return new MangaRoutePath(
//       routeType: RouteType.READER_ROUTE,
//       rd: rd,
//     );
//   }
//
//   factory MangaRoutePath.lost() {
//     return new MangaRoutePath(
//       routeType: RouteType.LOST_ROUTE,
//     );
//   }
// }
//
//
// class MangaRouteInformationParser extends RouteInformationParser<MangaRoutePath> {
//   @override
//   Future<MangaRoutePath> parseRouteInformation(RouteInformation routeInformation) async {
//     final uri = Uri.parse(routeInformation.location);
//     switch (uri.pathSegments.length) {
//       case 0:
//         return MangaRoutePath.home();
//       case 1:
//         return uri.pathSegments[0] == "search" ? MangaRoutePath.search() : MangaRoutePath.manga(null);
//       case 2:
//         return MangaRoutePath.reader(null);
//       default:
//         return MangaRoutePath.lost();
//     }
//   }
//
//   @override
//   RouteInformation restoreRouteInformation(MangaRoutePath configuration) {
//     return null;
//   }
// }

class MyHomePage extends StatefulWidget {
  final String title;
  final Function pushCallback;

  const MyHomePage({Key key, this.title, this.pushCallback}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectionIndex = 0;

  List<Widget> _actualNavs;

  @override
  void initState() {
    super.initState();
    _actualNavs = <Widget>[
      new HomePageWidget(
        pushCallback: this.widget.pushCallback,
      ),
      new FavouritesPageWidget(
        pushCallback: this.widget.pushCallback,
      ),
      new ProfilePageWidget(),
    ];
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
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
  final Function pushCallback;

  const HomePageWidget({Key key, this.pushCallback}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          title: Text("Home"),
          expandedHeight: 0.0,
          floating: true,
          snap: false,
          pinned: true,
          actions: [
            IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                this.widget.pushCallback.call('/search', argument: false);
                // Navigator.pushNamed(context, '/search', arguments: false);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class FavouritesPageWidget extends StatefulWidget {
  final Function pushCallback;

  const FavouritesPageWidget({Key key, this.pushCallback}) : super(key: key);

  @override
  _FavouritesPageWidgetState createState() => _FavouritesPageWidgetState();
}

class _FavouritesPageWidgetState extends State<FavouritesPageWidget> {
  final ValueNotifier<int> _notifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    DBer.registerNotifierForFavourites(_notifier);
    DBer.initializeDatabase().then((value) {
      _notifier.value += 1;
    });
  }

  void _move<T>(int from, int to, List<T> items) {
    T item = items.removeAt(from);
    items.insert(to, item);
  }

  List<Widget> parse(Iterable<SavedManga> all, List<Widget> renderedManga, List<SavedManga> savedManga) {
    if (all != null) {
      savedManga.addAll(all);
      savedManga.forEach(
        (e) => renderedManga.add(
          InkWell(
            child: FavouriteManga(
              name: e.name,
              coverURL: e.coverURL,
            ),
            onTap: () {
              this.widget.pushCallback.call('/manga', argument: APIer.fetchManga(e.id));
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Favourites"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              this.widget.pushCallback.call('/search', argument: true);
              // Navigator.pushNamed(context, '/search', arguments: true);
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            padding: EdgeInsets.all(16.0),
            child: ValueListenableBuilder<int>(
              valueListenable: _notifier,
              builder: (context, junk, child) {
                return FutureBuilder(
                  future: DBer.getAllSavedMangaAsync(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      List<Widget> renderedManga = [];
                      List<SavedManga> savedManga = [];
                      parse(snapshot.data, renderedManga, savedManga);
                      return ReorderableWrap(
                        needsLongPressDraggable: false,
                        spacing: 16.0,
                        children: renderedManga,
                        onReorder: (from, to) {
                          String id1 = savedManga[from].id;
                          String id2 = savedManga[to].id;
                          _move(from, to, savedManga);
                          _move(from, to, renderedManga);
                          DBer.reorder(id1, id2);
                        },
                      );
                    } else {
                      return CenteredFixedCircle();
                    }
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class SearchPageWidget extends StatefulWidget {
  final bool includeDBResults;
  final Function pushCallback;

  const SearchPageWidget({Key key, this.includeDBResults, this.pushCallback}) : super(key: key);

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
  int _rateLimitFetchMore = 100;

  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _mangaQuery = MangaQuery();
    _sc.addListener(() {
      if (_sc.offset >= _sc.position.maxScrollExtent && !_sc.position.outOfRange) {
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
    if (!_isLoading || DateTime.now().millisecondsSinceEpoch - _t > _rateLimitFetchMore) {
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
        if (value.headings.isEmpty) {
          _finished = true;
        }
        for (int i = 0, j = 0; i < value.headings.length; i++) {
          if (_hdFromDB.contains(value.headings[i])) {
            continue;
          }
          processHeading(value.headings[i]);
          _hdFromAPI.update(value.query.offset + j, (old) => value.headings[i], ifAbsent: () => value.headings[i]);
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
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      if (_sc.position.maxScrollExtent == 0 && _mangaQuery.name != null && _mangaQuery.name.isNotEmpty && !_finished) {
        print('Through callback');
        fetchMore();
      }
    });
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
                            this.widget.pushCallback.call('/manga', argument: APIer.fetchManga(hd1.id));
                            // Navigator.pushNamed(context, "/manga", arguments: APIer.fetchManga(hd1.id));
                          },
                        );
                      }
                    },
                    childCount: _finished ? (_hdFromAPI.length + _hdFromDB.length) : (_hdFromAPI.length + _hdFromDB.length + 1),
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
  final Future<CompleteManga> current;
  final Function pushCallback;

  const MangaPageWidget({Key key, this.current, this.pushCallback}) : super(key: key);

  @override
  _MangaPageWidgetState createState() => _MangaPageWidgetState();
}

class _MangaPageWidgetState extends State<MangaPageWidget> {
  ScrollController _sc = new ScrollController();
  CompleteManga _mn;
  bool _err = false;
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    this.widget.current.then((value) => setState(() => _mn = value));
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (_sc.hasClients && !_scrolled) {
        _sc.jumpTo(min(MediaQuery.of(context).size.height / 2, _sc.position.maxScrollExtent));
        _scrolled = true;
      }
    });
    if (_err) {
      return Scaffold(
          backgroundColor: Colors.black,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text("Error"),
              )
            ],
          ));
    } else if (_mn == null) {
      return SizedBox(width: 30, height: 30, child: CenteredFixedCircle());
    } else {
      return Scaffold(
        backgroundColor: Colors.black,
        body: NestedScrollView(
          controller: _sc,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                title: Text(_mn.title),
                expandedHeight: MediaQuery.of(context).size.height,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.all(16.0),
                  //TODO think about this because title text also becomes invisible
                  background: Container(
                    color: Colors.black,
                    child: CachedNetworkImage(
                      imageUrl: _mn.coverURL,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
            ];
          },
          body: MangaPage(
            manga: _mn,
            pushCallback: widget.pushCallback,
          ),
        ),
      );
    }
  }
}

class ReaderWidget extends StatefulWidget {
  // final double settingsWidth = 100;
  static final double settingsHeight = 100;
  static final int maxCacheCount = 1;

  final Chapters current;
  final Future<int> lastSave;
  final Function pushCallback;

  const ReaderWidget({Key key, this.current, this.lastSave, this.pushCallback}) : super(key: key);

  @override
  _ReaderWidgetState createState() => _ReaderWidgetState();
}

class _ReaderWidgetState extends State<ReaderWidget> with SingleTickerProviderStateMixin {
  static const int _LEFT_TO_RIGHT = 0;
  static const int _RIGHT_TO_LEFT = 1;
  static const int _UP_TO_DOWN = 2;

  static final DateFormat _formatter = DateFormat.jm();
  static final Battery _battery = Battery();

  static const int thresholdForWheelPopOut = 30;
  static const double wheelRadius = 80.0;

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

  OverlayEntry _settings;
  LayerLink _link;

  OverlayEntry _wheel;
  Offset _center;

  int _displayMode = _RIGHT_TO_LEFT;

  int _upperBoundIndex = -1;

  int _currPage;
  int _currChapLength;
  Stream _info;

  bool disposed = false;

  @override
  void initState() {
    super.initState();
    _link = LayerLink();
    _timer = RestartableTimer(Duration(seconds: 2), collapseTopBar);
    _info = infoStream(_battery);
    _animationControllerForAppBar = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    setup();
  }

  void setup() async {
    ChapterPosition position = await APIer.fetchChapterPageNumber(this.widget.current.mangaId, this.widget.current.chaps[this.widget.current.currentIndex].sequenceNumber);
    int displayMode = await DBer.getPreferredScrollStyle(this.widget.current.mangaId);
    if(displayMode != null) {
      _displayMode = displayMode;
    } else {
      DBer.updatePreferredScrollStyle(this.widget.current.mangaId, _displayMode);
    }
    int pgNum = position.index;
    _upperBoundIndex = position.length;
    int currNum = await this.widget.lastSave;
    _currentChapterId = this.widget.current.chaps[this.widget.current.currentIndex].id;
    if (currNum == null) {
      currNum = 0;
    }
    _formalIndexAtStartOfCurrentChapter = (pgNum);
    _formalIndexForList = _formalIndexAtStartOfCurrentChapter + currNum;
    PageController pageController = PageController(initialPage: _formalIndexAtStartOfCurrentChapter + currNum, keepPage: false);
    ItemScrollController scrollController = ItemScrollController();
    ItemPositionsListener scrollListener = ItemPositionsListener.create();
    _synchronizer = new ScrollSynchronizer();
    _synchronizer.attachPageControllerToAll([_LEFT_TO_RIGHT, _RIGHT_TO_LEFT], pageController);
    _synchronizer.attachListController(_UP_TO_DOWN, scrollController, scrollListener);

    _synchronizer.listen((t) {
      _listen(t.getIndex());
    });

    assembleProper(_formalIndexAtStartOfCurrentChapter, currNum);
  }

  Stream<InfoPanelData> infoStream(Battery b) async* {
    while (this.mounted) {
      int x = await b.batteryLevel;
      String s = _formatter.format(DateTime.now());
      yield InfoPanelData(x.toString(), s);
    }
  }

  void _listen(int index) {
    int chapStart = findChapStart(index);
    int chapIndex = chapStart > -1 ? _chapStartsToChapIndex[chapStart] : -1;
    if (chapIndex < 0) {
      return;
    }
    if (_currentChapterId != widget.current.chaps[chapIndex].id) {
      _currentChapterId = widget.current.chaps[chapIndex].id;
      DBer.readChapter(widget.current.mangaId, _currentChapterId, index - chapStart);
    }
    DBer.updateChapterPage(_currentChapterId, index - chapStart);
    int plusOne = chapIndex + 1;
    int minusOne = chapIndex - 1;
    if (plusOne < this.widget.current.chaps.length && !_chapIndexToChapter.containsKey(plusOne) && _requestedNextChapterLoadIndex != plusOne) {
      _requestedNextChapterLoadIndex = plusOne;
      populateChapter(plusOne).then((value) {
        int fps = chapStart + _chapIndexToChapter[chapIndex].content.urls.length;
        setState(() {
          addProper(_chapStarts, fps);
          _chapStartsToChapIndex.putIfAbsent(fps, () => plusOne);
        });
      });
    }
    if (minusOne > -1 && !_chapIndexToChapter.containsKey(minusOne) && _requestedPreviousChapterLoadIndex != minusOne) {
      _requestedPreviousChapterLoadIndex = minusOne;
      populateChapter(minusOne).then((value) {
        int fps = chapStart - value.content.urls.length;
        setState(() {
          addProper(_chapStarts, fps);
          _chapStartsToChapIndex.putIfAbsent(fps, () => minusOne);
        });
      });
    }
    int nCurr = index - chapStart + 1;
    int nLen = _chapIndexToChapter[chapIndex].content.urls.length;
    if (nCurr != _currPage) {
      setState(() => _currPage = nCurr);
    }
    if (nLen != _currChapLength) {
      setState(() => _currChapLength = nLen);
    }
  }

  Future<CompleteChapter> getChapter(int index) {
    if (index >= this.widget.current.chaps.length) {
      throw new Exception("index out of bounds");
    } else if (index < 0) {
      throw new Exception("index out of bounds");
    }
    ChapterData dt = this.widget.current.chaps[index];
    return APIer.fetchChapter(dt.id).then((value) => CompleteChapter.all(dt.id, value, dt, this.widget.current.s));
  }

  void assembleProper(int formalPageStart, int currPage) async {
    int x = this.widget.current.currentIndex;
    CompleteChapter current = await populateChapter(x);
    setState(() {
      addProper(_chapStarts, formalPageStart);
      _chapStartsToChapIndex.putIfAbsent(formalPageStart, () => x);
      _currPage = currPage + 1;
      _currChapLength = current.content.urls.length;
    });
    DBer.readChapter(widget.current.mangaId, widget.current.chaps[widget.current.currentIndex].id, currPage);
    int plusOne = this.widget.current.currentIndex + 1;
    if (plusOne < this.widget.current.chaps.length) {
      _requestedNextChapterLoadIndex = plusOne;
      await populateChapter(plusOne);
      int fps = formalPageStart + current.content.urls.length;
      setState(() {
        addProper(_chapStarts, fps);
        _chapStartsToChapIndex.putIfAbsent(fps, () => plusOne);
      });
    }
    int minusOne = this.widget.current.currentIndex - 1;
    if (minusOne > -1) {
      _requestedPreviousChapterLoadIndex = minusOne;
      CompleteChapter prevOne = await populateChapter(minusOne);
      int fps = formalPageStart - prevOne.content.urls.length;
      setState(() {
        addProper(_chapStarts, fps);
        _chapStartsToChapIndex.putIfAbsent(fps, () => minusOne);
      });
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
    int x = _chapStarts.lastIndexWhere((element) => formalPageNumber >= element);
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
    double newAngle = atan(deets.delta.dy - _center.dy / deets.delta.dx - _center.dx);
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
          offset: Offset(0, 20),
          child: ReaderPageSettingsPanel(
            onLeftToRight: () {
              IndexedScrollController old;
              if ((old = _synchronizer.get(_displayMode)) is! PageScrollController) {
                PageController controller = PageController(initialPage: old.getIndex(), keepPage: false);
                _synchronizer.get(_LEFT_TO_RIGHT).setUnderlyingController(controller);
              }
              DBer.updatePreferredScrollStyle(widget.current.mangaId, _LEFT_TO_RIGHT);
              setState(() => _displayMode = _LEFT_TO_RIGHT);
            },
            onRightToLeft: () {
              IndexedScrollController old;
              if ((old = _synchronizer.get(_displayMode)) is! PageScrollController) {
                PageController controller = PageController(initialPage: old.getIndex(), keepPage: false);
                _synchronizer.get(_RIGHT_TO_LEFT).setUnderlyingController(controller);
              }
              DBer.updatePreferredScrollStyle(widget.current.mangaId, _RIGHT_TO_LEFT);
              setState(() => _displayMode = _RIGHT_TO_LEFT);
            },
            onUpToDown: () {
              _formalIndexForList = _synchronizer.get(_displayMode).getIndex();
              DBer.updatePreferredScrollStyle(widget.current.mangaId, _UP_TO_DOWN);
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
              child: IconButton(icon: Icon(Icons.settings), onPressed: () => onPressSettings(context)),
            )
          ],
        ),
        controller: _animationControllerForAppBar,
        visible: _visible,
      ),
      body: GestureDetector(
        onTap: () => toggleTopBar(),
        //TODO in v2
        // onLongPressStart: (t) => toggleScrollWheel(t),
        child: Stack(
          children: [
            _displayMode == _UP_TO_DOWN
                ? ScrollablePositionedList.builder(
                    initialScrollIndex: _formalIndexForList,
                    itemPositionsListener: _synchronizer.get(_displayMode).getUnderlyingListener() as ItemPositionsListener,
                    itemScrollController: _synchronizer.get(_displayMode).getUnderlyingController() as ItemScrollController,
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
                            child: ChapterPage(
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
                    controller: _synchronizer.get(_displayMode).getUnderlyingController() as PageController,
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
                              child: SingleChildScrollView(
                                child: ChapterPage(
                                  url: chp.content.urls[pgNum],
                                  s: chp.source,
                                  width: MediaQuery.of(context).size.width,
                                ),
                              ),
                            ),
                          );
                        }
                      }
                      return w;
                    },
                  ),
            Positioned(
              bottom: 0,
              right: 0,
              child: StreamBuilder(
                stream: _info,
                initialData: InfoPanelData("?", "?"),
                builder: (context, snapshot) {
                  InfoPanelData data = snapshot.data as InfoPanelData;
                  return ReaderPageInfoPanel(
                    pageInfo: _currPage == null || _currChapLength == null ? "?/?" : _currPage.toString() + "/" + _currChapLength.toString(),
                    dateString: data.time,
                    batteryString: "Battery: " + data.batteryLevel + "%",
                  );
                },
              ),
            ),
          ],
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

  void attachListController(int marker, ItemScrollController controller, ItemPositionsListener listener) {
    ListScrollController con = ListScrollController(controller, listener);
    _storage[marker] = con;
    _controllers.add(con);
  }

  IndexedScrollController get(int marker) {
    return _storage[marker];
  }

  void listen(Function(IndexedScrollController) listener) {
    this._controllers.forEach((value) => value.listen(() => listener.call(value)));
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

  RestartableTimer(this._duration, this._callback) : _timer = Timer(_duration, _callback);

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
    return Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator()));
  }
}

class ReadArguments {
  Chapters t;
  Future<int> page;

  ReadArguments.all(this.t, this.page);
}

class InfoPanelData {
  String batteryLevel;
  String time;

  InfoPanelData(this.batteryLevel, this.time);
}

class DevHttpsOverides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
