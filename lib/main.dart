import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'api_objects.dart';
import 'manga_heading.dart';
import 'visual_objects.dart';

void main() {
  HttpOverrides.global = new DevHttpsOverides();
  DBer.initializeDatabase();
  // MangaPageChapterButton.configureFunction((context, s, chaps, index) {
  //   Navigator.pushNamed(context, "/read",
  //       arguments: Chapters.all(
  //         chaps: chaps,
  //         s: s,
  //         currentIndex: index,
  //       ));
  // });
  MangaPageChapterPanel.onClick = (c, t) => Navigator.pushNamed(c, "/read", arguments: t);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
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
          backgroundColor: Colors.black),
      home: MyHomePage(title: 'Home'),
      onGenerateRoute: (settings) {
        if (settings.name == '/search') {
          return MaterialPageRoute(builder: (context) => SearchPageWidget());
        } else if (settings.name == '/manga') {
          return MaterialPageRoute(
              builder: (context) => MangaPageWidget(
                    current: settings.arguments as Future<CompleteManga>,
                  ));
        } else if (settings.name == '/read') {
          return MaterialPageRoute(
              builder: (context) => ReaderWidget(
                    current: settings.arguments as Chapters,
                  ));
        }
        return null;
      },
      // routes: <String, WidgetBuilder>{
      //   '/search': (context) => SearchPageWidget(),
      //   '/manga': (context) => MangaPageWidget(),
      //   '/read': (context) => ReaderWidget(),
      // },
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectionIndex = 0;

  List<Function> _navs = [
    () => new HomePageWidget(),
    () => new FavouritesPageWidget(),
    () => new ProfilePageWidget(),
  ];

  List<Widget> _actualNavs = <Widget>[];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < _navs.length; i++) {
      _actualNavs.add(SizedBox());
    }
    _actualNavs[_selectionIndex] = _navs.elementAt(_selectionIndex).call();
  }

  void _onTap(int newIndex) {
    setState(() {
      _selectionIndex = newIndex;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      body: IndexedStack(index: _selectionIndex, children: _actualNavs),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.black,
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorites"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
        currentIndex: _selectionIndex,
        selectedItemColor: Colors.lime,
        onTap: (t) => {
          setState(() {
            if (_actualNavs.elementAt(t) is SizedBox) {
              _actualNavs[t] = _navs.elementAt(t).call();
            }
            _selectionIndex = t;
          }),
        },
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class HomePageWidget extends StatefulWidget {
  const HomePageWidget({Key key}) : super(key: key);

  @override
  _HomePageWidgetState createState() => _HomePageWidgetState();
}

class _HomePageWidgetState extends State<HomePageWidget> {
  List<MangaHeading> _hd = <MangaHeading>[];
  ScrollController _sc = new ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
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

  bool fetchMore([int limit = 10]) {
    if (!_isLoading) {
      startedLoading();
      APIer.fetchHome(_hd.length, limit).then((value) {
        _hd.addAll(value);
        stoppedLoading();
      });
      return true;
    } else {
      return false;
    }
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

  Widget getMain(BuildContext context) {
    return CustomScrollView(
      controller: _sc,
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
                  Navigator.pushNamed(context, '/search');
                })
          ],
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (buildContext, index) {
              if (index == _hd.length) {
                return CenteredFixedCircle();
              } else {
                return Widgeter.getHomePanel(_hd.elementAt(index));
              }
            },
            childCount: _isLoading ? _hd.length + 1 : _hd.length,
          ),
        ),
        // SliverFillRemaining(
        //   hasScrollBody: false,
        //   child: Container(
        //     color: Colors.green,
        //   ),
        // )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.scheduleFrameCallback((timeStamp) {
      if (_sc.position.maxScrollExtent == 0) {
        print('Through callback');
        fetchMore();
      }
    });
    return getMain(context);
  }
}

class FavouritesPageWidget extends StatefulWidget {
  const FavouritesPageWidget({Key key}) : super(key: key);

  @override
  _FavouritesPageWidgetState createState() => _FavouritesPageWidgetState();
}

class _FavouritesPageWidgetState extends State<FavouritesPageWidget> {
  Map<int, MangaHeading> _hd;

  @override
  void initState() {
    super.initState();
    setState(() {
      _hd = HashMap();
      // APIer.fetchFavourites().then((value) => DBer.putFavourites(value));
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          snap: false,
          pinned: true,
          floating: true,
          expandedHeight: 200.0,
          title: Text("Favourites"),
        ),
        SliverGrid(
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            childAspectRatio: 4,
            crossAxisSpacing: 10.0,
            mainAxisExtent: 10.0,
            maxCrossAxisExtent: 250,
          ),
          delegate: SliverChildBuilderDelegate(
            (buildContext, int index) {
              if (_hd.containsKey(index)) {
                return MangaThumbnail(
                  hd: _hd[index],
                );
              } else {
                return FutureBuilder(
                  future: DBer.fetchFavouriteAt(index),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      _hd.putIfAbsent(index, snapshot.data);
                      return MangaThumbnail(
                        hd: snapshot.data,
                      );
                    } else if (snapshot.hasError) {
                      return Widgeter.errorThumbnail();
                    }
                    return SizedBox();
                  },
                );
              }
            },
            childCount: DBer.getFavouritesCount(),
          ),
        ),
      ],
    );
    // return FutureBuilder(
    //   future: _hd,
    //   builder: (context, snapshot) {
    //     if (snapshot.hasData) {
    //       return Widgeter.getThumbnail(snapshot.data);
    //     } else if (snapshot.hasError) {
    //       return Widgeter.errorThumbnail();
    //     }
    //     return CircularProgressIndicator();
    //   },
    // );
  }
}

class SearchPageWidget extends StatefulWidget {
  const SearchPageWidget({Key key}) : super(key: key);

  @override
  _SearchPageWidgetState createState() => _SearchPageWidgetState();
}

class _SearchPageWidgetState extends State<SearchPageWidget> {
  Map<int, MangaHeading> _hd = <int, MangaHeading>{};
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
    _mangaQuery.offset = _hd.length;
    APIer.fetchSearch(_mangaQuery).then((value) {
      if (_mangaQuery == value.query) {
        if (value.headings.isEmpty) {
          _finished = true;
        }
        for (int i = 0; i < value.headings.length; i++) {
          processHeading(value.headings[i]);
          _hd.update(value.query.offset + i, (old) => value.headings[i], ifAbsent: () => value.headings[i]);
        }
      }
      stoppedLoading();
    });
  }

  void fetchAgain() {
    _hd.clear();
    _finished = false;
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
    if (x < 255) {
    } else {
      hd.description = hd.description.substring(0, 253) + "...";
    }
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
                      if (index == _hd.length) {
                        return CenteredFixedCircle();
                      } else {
                        return InkWell(
                          child: MangaThumbnail(
                            hd: _hd[index],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, "/manga", arguments: APIer.fetchManga(_hd[index].id));
                          },
                        );
                      }
                    },
                    childCount: _finished ? _hd.length : _hd.length + 1,
                  ),
                ),
                // SliverFillRemaining(
                //   hasScrollBody: false,
                //   child: Container(
                //     color: Colors.green,
                //   ),
                // )
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

  const MangaPageWidget({Key key, this.current}) : super(key: key);

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
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: MangaPage(
              manga: _mn,
            ),
          )
          // body: CustomScrollView(
          //   controller: _sc,
          //   slivers: [
          //     SliverAppBar(
          //       title: Text(_mn.title),
          //       expandedHeight: MediaQuery.of(context).size.height,
          //       pinned: true,
          //       flexibleSpace: FlexibleSpaceBar(
          //           titlePadding: EdgeInsets.all(16.0),
          //           background: CachedNetworkImage(
          //             imageUrl: _mn.coverURL,
          //             fit: BoxFit.cover,
          //           )),
          //     ),
          //     MangaPage(
          //       manga: _mn,
          //     ),
          //     // Widgeter.getMangaPage(_mn, _expanded, setExpanded, (t) {
          //     //   Navigator.pushNamed(context, "/read", arguments: APIer.fetchChapter(t.id));
          //     // })
          //   ],
          // ),
          );
    }
  }
}

class ReaderWidget extends StatefulWidget {
  // final double settingsWidth = 100;
  final double settingsHeight = 100;

  final Chapters current;
  final int maxCacheCount = 1;

  const ReaderWidget({Key key, this.current}) : super(key: key);

  @override
  _ReaderWidgetState createState() => _ReaderWidgetState();
}

class _ReaderWidgetState extends State<ReaderWidget> with SingleTickerProviderStateMixin {
  static const int LEFT_TO_RIGHT = 0;
  static const int RIGHT_TO_LEFT = 1;
  static const int UP_TO_DOWN = 2;

  TransformationController _transformationController = TransformationController();
  bool _visible = false;
  RestartableTimer _timer;
  AnimationController _animationController;
  PageController _pageController;
  ItemScrollController _scrollController;
  ItemPositionsListener _scrollListener;
  int _formalIndexAtStartOfCurrentChapter = 0;
  int _formalIndexForList = 0;
  int _requestedNextChapterLoadIndex = -1;
  int _requestedPreviousChapterLoadIndex = -1;
  Map<int, CompleteChapter> _chapIndexToChapter = {};
  Map<int, int> _chapStartsToChapIndex = {};
  List<int> _chapStarts = [];
  OverlayEntry _settings;
  LayerLink _link;

  // bool _reverse = false;
  // bool _scrollDirectionHorizontal = true;
  // bool _continuousScroll = false;
  int _displayMode = RIGHT_TO_LEFT;
  int _upperBoundIndex = -1;

  @override
  void initState() {
    super.initState();
    _link = LayerLink();
    _timer = RestartableTimer(Duration(seconds: 2), collapseTopBar);
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );
    APIer.fetchChapterPageNumber(this.widget.current.mangaId, this.widget.current.chaps[this.widget.current.currentIndex].sequenceNumber).then((value) {
      _formalIndexAtStartOfCurrentChapter = (value);
      _formalIndexForList = _formalIndexAtStartOfCurrentChapter;
      _pageController = PageController(initialPage: _formalIndexAtStartOfCurrentChapter, keepPage: false);
      _pageController.addListener(() {
        int index = _pageController.page.toInt();
        _listen(index);
      });
      _scrollController = ItemScrollController();
      _scrollListener = ItemPositionsListener.create();
      _scrollListener.itemPositions.addListener(() {
        int index = _scrollListener.itemPositions.value.first.index;
        _listen(index);
      });
      assembleProper(_formalIndexAtStartOfCurrentChapter);
    });
  }

  void _listen(int index) {
    int chapIndex = findChapIndex(index);
    if (chapIndex < 0) {
      return;
    }
    int plusOne = chapIndex + 1;
    int minusOne = chapIndex - 1;
    if (plusOne < this.widget.current.chaps.length && !_chapIndexToChapter.containsKey(plusOne) && _requestedNextChapterLoadIndex != plusOne) {
      _requestedNextChapterLoadIndex = plusOne;
      populateChapter(plusOne).then((value) {
        int fps = findChapStart(index) + _chapIndexToChapter[chapIndex].content.urls.length;
        setState(() {
          addProper(_chapStarts, fps);
          _chapStartsToChapIndex.putIfAbsent(fps, () => plusOne);
        });
      });
    }
    if (minusOne > -1 && !_chapIndexToChapter.containsKey(minusOne) && _requestedPreviousChapterLoadIndex != minusOne) {
      _requestedPreviousChapterLoadIndex = minusOne;
      populateChapter(minusOne).then((value) {
        int fps = findChapStart(index) - value.content.urls.length;
        setState(() {
          addProper(_chapStarts, fps);
          _chapStartsToChapIndex.putIfAbsent(fps, () => minusOne);
        });
      });
    }
    if (plusOne == this.widget.current.chaps.length) {
      _upperBoundIndex = findChapStart(index) + _chapIndexToChapter[chapIndex].content.urls.length;
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

  // void assemble() {
  //   getChapter(this._currentChapterInList).then((value) {
  //     setState(() {
  //       _recentChaps.add(value);
  //       _currentChapterIndex = 0;
  //     });
  //   }).whenComplete(() {
  //     _requestedNextChapterLoadIndex = _currentChapterInList + 1;
  //     _requestedPreviousChapterLoadIndex = _currentChapterInList - 1;
  //     getNextChapter();
  //     getPreviousChapter();
  //   });
  // }

  void assembleProper(int formalPageStart) {
    int x = this.widget.current.currentIndex;
    populateChapter(x).then((value) {
      setState(() {
        addProper(_chapStarts, formalPageStart);
        _chapStartsToChapIndex.putIfAbsent(formalPageStart, () => x);
      });
      return value;
    }).then((value) {
      int plusOne = this.widget.current.currentIndex + 1;
      if (plusOne < this.widget.current.chaps.length) {
        _requestedNextChapterLoadIndex = plusOne;
        populateChapter(plusOne).then((v1) {
          int fps = formalPageStart + value.content.urls.length;
          setState(() {
            addProper(_chapStarts, fps);
            _chapStartsToChapIndex.putIfAbsent(fps, () => plusOne);
          });
        });
      }
    });
    int minusOne = this.widget.current.currentIndex - 1;
    if (minusOne > -1) {
      _requestedPreviousChapterLoadIndex = minusOne;
      populateChapter(minusOne).then((value) {
        int fps = formalPageStart - value.content.urls.length;
        setState(() {
          addProper(_chapStarts, fps);
          _chapStartsToChapIndex.putIfAbsent(fps, () => minusOne);
        });
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

  void toggleTopBar() {
    _timer.cancel();
    if (!_visible) {
      expandTopBar();
      _timer.reset();
    } else {
      if (_settings != null) {
        _settings.remove();
        _settings = null;
      }
      collapseTopBar();
    }
  }

  void expandTopBar() {
    setState(() {
      _visible = true;
    });
  }

  void collapseTopBar() {
    setState(() {
      _visible = false;
    });
  }

  void onPressSettings(BuildContext context) {
    _timer.cancel();
    if (_settings == null) {
      initSettings(_settings);
      Overlay.of(context).insert(_settings);
    } else {
      _settings.remove();
      _settings = null;
      _timer.reset();
    }
  }

  void initSettings(OverlayEntry settings) {
    _settings = OverlayEntry(builder: (context) {
      return Positioned(
        height: this.widget.settingsHeight,
        child: CompositedTransformFollower(
          link: _link,
          followerAnchor: Alignment.topRight,
          targetAnchor: Alignment.bottomRight,
          offset: Offset(0, 20),
          child: ReaderPageSettingsPanel(
            onLeftToRight: () {
              if (_displayMode == UP_TO_DOWN) {
                _pageController = PageController(initialPage: _scrollListener.itemPositions.value.first.index, keepPage: false);
                _pageController.addListener(() {
                  int index = _pageController.page.toInt();
                  _listen(index);
                });
              }
              setState(() => _displayMode = LEFT_TO_RIGHT);
            },
            onRightToLeft: () {
              if (_displayMode == UP_TO_DOWN) {
                _pageController = PageController(initialPage: _scrollListener.itemPositions.value.first.index, keepPage: false);
                _pageController.addListener(() {
                  int index = _pageController.page.toInt();
                  _listen(index);
                });
              }
              setState(() => _displayMode = RIGHT_TO_LEFT);
            },
            onUpToDown: () {
              _formalIndexForList = _pageController.page.toInt();
              setState(() => _displayMode = UP_TO_DOWN);
            },
          ),
        ),
      );
    });
  }

  @override
  void dispose() {
    super.dispose();
    _timer.cancel();
    if (_settings != null) {
      _settings.remove();
      Future.delayed(Duration(milliseconds: 100), () => _settings.dispose());
    }
    _transformationController.dispose();
    _animationController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String displayName = "";
    if (_pageController == null) {
      return CenteredFixedCircle();
    }
    if (_pageController.hasClients) {
      int indexP = _pageController.page.toInt();
      int chapIndex = findChapIndex(indexP);
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
          controller: _animationController,
          visible: _visible,
        ),
        body: GestureDetector(
          onTapDown: (t) => toggleTopBar(),
          child: _displayMode == UP_TO_DOWN
              ? ScrollablePositionedList.builder(
                  initialScrollIndex: _formalIndexForList,
                  itemPositionsListener: _scrollListener,
                  itemScrollController: _scrollController,
                  initialAlignment: 0,
                  //TODO point of failure
                  itemCount: _upperBoundIndex == -1 ? 100000 : _upperBoundIndex,

                  itemBuilder: (context, index) {
                    int x1 = findChapStart(index);
                    if (x1 < 0) {
                      return CenteredFixedCircle();
                    } else {
                      int pgNum = index - x1;
                      int chapNum = _chapStartsToChapIndex[x1];
                      CompleteChapter chp = _chapIndexToChapter[chapNum];
                      if (pgNum >= chp.content.urls.length) {
                        return CenteredFixedCircle();
                      } else {
                        return InteractiveViewer(
                          child: ChapterPage(
                            url: chp.content.urls[pgNum],
                            s: chp.source,
                            width: MediaQuery.of(context).size.width,
                          ),
                        );
                      }
                    }
                  },
                )
              : PageView.custom(
                  allowImplicitScrolling: true,
                  controller: _pageController,
                  reverse: _displayMode == RIGHT_TO_LEFT,
                  childrenDelegate: SliverChildBuilderDelegate((context, index) {
                    if (index == _upperBoundIndex) {
                      return null;
                    }
                    int x1 = findChapStart(index);
                    if (x1 < 0) {
                      return CenteredFixedCircle();
                    } else {
                      int pgNum = index - x1;
                      int chapNum = _chapStartsToChapIndex[x1];
                      CompleteChapter chp = _chapIndexToChapter[chapNum];
                      if (pgNum >= chp.content.urls.length) {
                        return CenteredFixedCircle();
                      } else {
                        return Center(
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
                  })),
        ));
  }

// void loadAndReplace(int nextIndex) {
//   if (nextIndex >= _screen.length) {
//     return;
//   }
//   if (_screen[nextIndex] is SizedBox) {
//     _screen[nextIndex] = ChapterPage(url: _chap.urls[nextIndex]);
//   }
//   setState(() {
//     _pageNumber = nextIndex;
//   });
// }

// void nextPage(int nextIndex) {
//   if (_currentChapterIndex > -1 && nextIndex > -1 && nextIndex < _recentChaps.elementAt(_currentChapterIndex).content.urls.length && nextIndex != _pageNumber) {
//     setState(() {
//       _pageNumber = nextIndex;
//     });
//     _controller.value = Matrix4.identity();
//   }
// }
//
// void increment(int inc) {
//   nextPage(_pageNumber + inc);
// }
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

class DevHttpsOverides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
