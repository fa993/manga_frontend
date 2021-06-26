import 'dart:collection';
import 'dart:io';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fullscreen/fullscreen.dart';

import 'api_objects.dart';
import 'manga_heading.dart';
import 'visual_objects.dart';

void main() {
  HttpOverrides.global = new DevHttpsOverides();
  DBer.initializeDatabase();
  MangaPageChapterButton.configureFunction((context, t, s) {
    Navigator.pushNamed(context, "/read", arguments: APIer.fetchChapter(t).then((value) => CompleteChapter.all(t, value, s)));
  });
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
      routes: <String, WidgetBuilder>{
        '/search': (context) => SearchPageWidget(),
        '/manga': (context) => MangaPageWidget(),
        '/read': (context) => ReaderWidget(),
      },
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
                return Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator()));
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
                        return Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator()));
                      } else {
                        return InkWell(
                          child: MangaThumbnail(
                            hd: _hd[index],
                          ),
                          onTap: () {
                            Navigator.pushNamed(context, '/manga', arguments: APIer.fetchManga(_hd[index].id));
                          },
                        );
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
  const MangaPageWidget({Key key}) : super(key: key);

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
  }

  @override
  Widget build(BuildContext context) {
    if (_mn == null) {
      Future<CompleteManga> thisOne = (ModalRoute.of(context).settings.arguments) as Future<CompleteManga>;
      thisOne.then(
        (value) => setState(() {
          _mn = value;
        }),
      );
    }
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
      return SizedBox(
        width: 30,
        height: 30,
        child: Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator())),
      );
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
                      background: CachedNetworkImage(
                        imageUrl: _mn.coverURL,
                        fit: BoxFit.cover,
                      )),
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
  const ReaderWidget({Key key}) : super(key: key);

  @override
  _ReaderWidgetState createState() => _ReaderWidgetState();
}

class _ReaderWidgetState extends State<ReaderWidget> {
  CompleteChapter _chap;
  int _pageNumber = 0;
  TransformationController _controller = TransformationController();

  @override
  Widget build(BuildContext context) {
    Future<CompleteChapter> thisOne = (ModalRoute.of(context).settings.arguments) as Future<CompleteChapter>;
    thisOne.then((value) => setState(() {
          _chap = value;
        }));
    if (_chap != null) {
      // for(int i = 0; i < _chap.urls.length; i++){
      //   _screen.add(SizedBox());
      // }
      // _screen[0] = Widgeter.chapterImage(_chap.urls[0]);
      // for (int i = 0; i < _chap.urls.length; i++) {
      //   _screen.add(ChapterPage(url: _chap.urls[i]));
      // }
      return Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
              onTap: () {
                // loadAndReplace(_pageNumber + 1);
                increment(1);
              },
              onHorizontalDragEnd: (t) {
                if (t.velocity.pixelsPerSecond.dx > 0) {
                  increment(-1);
                } else {
                  increment(1);
                }
              },
              child: InteractiveViewer(
                transformationController: _controller,
                  child: ChapterPage(
                url: _chap.content.urls[_pageNumber],
                s: _chap.source,
              ))));
    } else {
      return Center(
          child: SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(),
      ));
    }
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

  void nextPage(int nextIndex) {
    if (nextIndex > -1 && nextIndex < _chap.content.urls.length && nextIndex != _pageNumber) {
      setState(() {
        _pageNumber = nextIndex;
      });
      _controller.value = Matrix4.identity();
    }
  }

  void increment(int inc) {
    nextPage(_pageNumber + inc);
  }
}

class DevHttpsOverides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return super.createHttpClient(context)..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}
