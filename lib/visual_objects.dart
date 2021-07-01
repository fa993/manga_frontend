import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:manga_frontend/api_objects.dart';
import 'package:transparent_image/transparent_image.dart';

import 'manga_heading.dart';
import 'dart:math';

class Widgeter {
  static double imgHeight = 200;
  static double imgWidth = 128.6;
  static double gapSpace = 16.0;
  static double edgeSpace = 16.0;
  static double descriptionFontSize = 12.0;
  static double genreFontSize = 14.0;
  static double nameFontSize = 16.0;
  static String fontFamily = "monospace";
  static double mangaPageGenresFontSize = 20.0;
  static double mangaPageDescriptionFontSize = 16.0;
  static double mangaPageChapterPanelHeight = 40.0 + 16.0 + 16.0;
  static double mangaPageChapterPanelExpansionButtonHeight = 14.0;
  static int mangaPageChapterGridChildCount = 5;
  static double mangaPageChapterButtonWidth = 60.0;
  static double mangaPageChapterButtonHeight = 50.0;
  static double mangaPageChapterGridSpacingWidth = 10.0;
  static double mangaPageChapterGridSpacingHeight = 10.0;

  static Image img = Image.memory(
    kTransparentImage,
    height: imgHeight,
    width: imgWidth,
    alignment: Alignment.centerLeft,
  );

  // static Widget getThumbnail(MangaHeading hd) {
  //   return Container(
  //       margin: EdgeInsets.all(edgeSpace),
  //       padding: EdgeInsets.all(edgeSpace),
  //       foregroundDecoration: BoxDecoration(border: Border.all(color: Colors.green)),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         mainAxisSize: MainAxisSize.min,
  //         children: [
  //           Flexible(
  //               fit: FlexFit.loose,
  //               child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
  //                 CachedNetworkImage(
  //                   imageUrl: hd.coverURL,
  //                   height: imgHeight,
  //                   width: imgWidth,
  //                   alignment: Alignment.centerLeft,
  //                   placeholder: (context, url) => img,
  //                 ),
  //                 SizedBox(
  //                   width: gapSpace,
  //                 ),
  //                 Flexible(
  //                     child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
  //                   Container(
  //                       height: imgHeight - gapSpace,
  //                       child: Text(
  //                         hd.description,
  //                         style: TextStyle(
  //                           color: Colors.white,
  //                           fontSize: descriptionFontSize,
  //                           fontFamily: fontFamily,
  //                           decoration: TextDecoration.none,
  //                         ),
  //                         maxLines: 12,
  //                         overflow: TextOverflow.fade,
  //                       )),
  //                   Text(
  //                     hd.allgenres,
  //                     style: TextStyle(
  //                       color: Colors.white,
  //                       fontSize: genreFontSize,
  //                       fontFamily: fontFamily,
  //                       decoration: TextDecoration.none,
  //                     ),
  //                     softWrap: true,
  //                     overflow: TextOverflow.ellipsis,
  //                     maxLines: 1,
  //                   )
  //                 ])),
  //               ])),
  //           SizedBox(height: gapSpace),
  //           Text(
  //             hd.name,
  //             style: TextStyle(
  //               color: Colors.white,
  //               fontSize: nameFontSize,
  //               fontFamily: fontFamily,
  //               decoration: TextDecoration.none,
  //             ),
  //             overflow: TextOverflow.ellipsis,
  //           ),
  //         ],
  //       ));
  // }

  static Widget errorThumbnail() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: Image.memory(kTransparentImage),
        ),
        Text("Error"),
      ],
    );
  }

  // static Widget getHeading(String heading) {
  //   return Container(
  //     child: Text(
  //       heading,
  //       style: TextStyle(
  //         fontSize: 16.0,
  //         color: Colors.black,
  //       ),
  //     ),
  //     alignment: Alignment.centerLeft,
  //     margin: EdgeInsets.fromLTRB(25, 25, 0, 0),
  //   );
  // }

  static Widget getHomePanel(MangaHeading hd) {
    return Container(
      child: Text("Home: " + hd.name),
    );
  }

// static Widget errorHomePanel() {
//   return Container(
//     child: Text("Internal App Error"),
//   );
// }
//
// static SliverList getMangaPage(CompleteManga mg, int expanded, void Function(int) setExpanded, Function(ChapterData) onPress) {
//   return SliverList(
//     delegate: SliverChildBuilderDelegate((context, index) {
//       if (index.isOdd) {
//         return SizedBox(
//           height: 30,
//         );
//       }
//       if (index > 6) {
//         return composeLinkedChapterPanels(context, mg.linkedMangas[((index - 6) / 2).floor() - 1].source, mg.linkedMangas[((index - 6) / 2).floor() - 1].chapters, expanded, setExpanded, index, onPress);
//       }
//       switch (index) {
//         case 0:
//           return composeGenres(mg.genres);
//         case 2:
//           return composeDescription(mg.description);
//         case 4:
//           return composeButtonPanel();
//         case 6:
//           return composeMainChapterPanel(context, mg.source, mg.chapters, expanded, setExpanded, 0, onPress);
//         default:
//           return SizedBox(
//             height: 30,
//           );
//       }
//     }, childCount: 8 + mg.linkedMangas.length * 2),
//   );
// }
//
// static Widget composeGenres(List<Genre> genres) {
//   return Container(
//       alignment: Alignment.center,
//       child: Text(
//         genres.map((e) => e.name[0].toUpperCase() + e.name.substring(1)).reduce((value, element) => value += ", " + element),
//         style: TextStyle(color: Colors.white, fontFamily: fontFamily, fontSize: mangaPageGenresFontSize),
//       ));
// }
//
// static Widget composeDescription(String description) {
//   return Text(
//     description,
//     style: TextStyle(color: Colors.white, fontFamily: fontFamily, fontSize: mangaPageDescriptionFontSize),
//   );
// }
//
// static Widget composeButtonPanel() {
//   return SizedBox(
//     height: 30,
//   );
// }
//
// static Widget composeMainChapterPanel(BuildContext context, Source s, Map<int, ChapterData> mData, int expanded, void Function(int) setExpanded, int index, Function(ChapterData) onPress) {
//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Container(
//         alignment: Alignment.centerLeft,
//         child: TextButton(
//           child: Text(
//             s.name,
//             style: TextStyle(fontFamily: fontFamily, color: Colors.green, fontSize: mangaPageChapterPanelExpansionButtonHeight),
//           ),
//           onPressed: () {
//             if (expanded == index) {
//               expanded = -1;
//             } else {
//               expanded = index;
//             }
//             setExpanded.call(expanded);
//           },
//         ),
//       ),
//       expanded == index ? _chapterGrid(context, mData, onPress) : _chapterList(mData, onPress),
//     ],
//   );
// }
//
// static Widget composeLinkedChapterPanels(BuildContext context, Source s, Map<int, ChapterData> mData, int expanded, void Function(int) setExpanded, int index, Function(ChapterData) onPress) {
//   return Column(
//     mainAxisSize: MainAxisSize.min,
//     crossAxisAlignment: CrossAxisAlignment.start,
//     children: [
//       Container(
//         alignment: Alignment.centerLeft,
//         child: TextButton(
//           child: Text(
//             s.name,
//             style: TextStyle(fontFamily: fontFamily, color: Colors.green, fontSize: mangaPageChapterPanelExpansionButtonHeight),
//           ),
//           onPressed: () {
//             if (expanded == index) {
//               expanded = -1;
//             } else {
//               expanded = index;
//             }
//             setExpanded.call(expanded);
//           },
//         ),
//       ),
//       expanded == index ? _chapterGrid(context, mData, onPress) : _chapterList(mData, onPress),
//     ],
//   );
// }
//
// static Widget _chapterList(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return Container(
//     height: mangaPageChapterButtonHeight,
//     child: _chapterListView(mData, onPress),
//   );
// }
//
// static Widget _chapterGrid(BuildContext context, Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return ConstrainedBox(
//     constraints: BoxConstraints(
//       maxHeight: MediaQuery.of(context).size.height / 2,
//     ),
//     // height: min(MediaQuery.of(context).size.height / 2, mangaPageChapterButtonHeight * (mData.length / (MediaQuery.of(context).size.width / (mangaPageChapterButtonWidth + mangaPageChapterGridSpacingWidth)).floor()).ceil()),
//     child: _chapterGridView(mData, onPress),
//   );
// }
//
// static ListView _chapterListView(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return ListView.separated(
//     itemBuilder: _chapterItemBuilder(mData, onPress),
//     scrollDirection: Axis.horizontal,
//     itemCount: mData.length,
//     separatorBuilder: (context, index) {
//       return SizedBox(
//         width: mangaPageChapterGridSpacingWidth,
//       );
//     },
//   );
// }
//
// static GridView _chapterGridView(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return GridView.builder(
//     gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
//       maxCrossAxisExtent: mangaPageChapterButtonWidth,
//       mainAxisExtent: mangaPageChapterButtonHeight,
//       mainAxisSpacing: mangaPageChapterGridSpacingHeight,
//       crossAxisSpacing: mangaPageChapterGridSpacingWidth,
//     ),
//     itemBuilder: _chapterItemBuilder(mData, onPress),
//     itemCount: mData.length,
//     padding: EdgeInsets.all(0.0),
//     shrinkWrap: true,
//   );
// }
//
// static Function _chapterItemBuilder(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return (context, index) {
//     return _chapterWidget(mData[index], onPress);
//   };
// }
//
// static Widget _chapterWidget(ChapterData chp, Function(ChapterData) onPress) {
//   return Container(
//     child: OutlinedButton(
//       style: ButtonStyle(side: MaterialStateProperty.all(BorderSide(color: Colors.white))),
//       child: Text(
//         chp.chapterNumber == null || chp.chapterNumber.isEmpty ? chp.chapterName : chp.chapterNumber,
//         softWrap: true,
//         maxLines: 1,
//         overflow: TextOverflow.ellipsis,
//         style: TextStyle(color: Colors.white, fontFamily: fontFamily),
//       ),
//       onPressed: () {
//         onPress.call(chp);
//       },
//     ),
//   );
// }
//
// static Widget chapterImage(String url) {
//   return InteractiveViewer(
//       child: Center(
//           child: CachedNetworkImage(
//     // httpHeaders: {"Referer": "https://manganelo.com/"},
//     imageUrl: url,
//     placeholder: (context, x) {
//       return Center(child: SizedBox(width: 30, height: 30, child: CircularProgressIndicator()));
//     },
//   )));
// }
//
// static Widget _chapterListGrid(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return Container(
//     height: mangaPageChapterButtonHeight,
//     child: _chapterListGridView(mData, onPress),
//   );
// }
//
// static Widget _chapterListGridView(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return GridView.builder(
//     scrollDirection: Axis.horizontal,
//     gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
//       mainAxisExtent: mangaPageChapterButtonWidth,
//       mainAxisSpacing: mangaPageChapterGridSpacingWidth,
//       crossAxisSpacing: mangaPageChapterGridSpacingHeight,
//       crossAxisCount: 1,
//       // childAspectRatio: mangaPageChapterButtonHeight / mangaPageChapterButtonWidth
//     ),
//     itemBuilder: _chapterItemBuilder(mData, onPress),
//     itemCount: mData.length,
//     padding: EdgeInsets.all(0.0),
//     shrinkWrap: true,
//   );
// }
//
// static Widget _chapterTable(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   return Table(children: _chapterTableRow(mData, onPress));
// }
//
// static List<TableRow> _chapterTableRow(Map<int, ChapterData> mData, Function(ChapterData) onPress) {
//   int num = 5;
//   int x = (mData.length / num).ceil();
//   List<TableRow> ret = [];
//   List<Widget> childs = [];
//   for (int i = 1; i <= mData.length; i++) {
//     childs.add(_chapterWidget(mData[i - 1], onPress));
//     if (i % num == 0) {
//       ret.add(TableRow(
//         children: childs,
//       ));
//       childs = [];
//     }
//   }
//   if (childs.isNotEmpty) {
//     int f = childs.length;
//     for (int i = f; i < num; i++) {
//       childs.add(SizedBox());
//     }
//     ret.add(TableRow(
//       children: childs,
//     ));
//   }
//   return ret;
// }
}

class MangaThumbnail extends StatelessWidget {
  final MangaHeading hd;

  const MangaThumbnail({Key key, this.hd}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
        key: ObjectKey(hd.id),
        confirmDismiss: (d) {
          return Future.value(false);
        },
        child: Container(
            margin: EdgeInsets.all(Widgeter.edgeSpace),
            padding: EdgeInsets.all(Widgeter.edgeSpace),
            foregroundDecoration: BoxDecoration(border: Border.all(color: Colors.green)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                    fit: FlexFit.loose,
                    child: Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CachedNetworkImage(
                        imageUrl: hd.coverURL,
                        height: Widgeter.imgHeight,
                        width: Widgeter.imgWidth,
                        alignment: Alignment.centerLeft,
                        placeholder: (context, url) => Widgeter.img,
                      ),
                      SizedBox(
                        width: Widgeter.gapSpace,
                      ),
                      Flexible(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Container(
                            height: Widgeter.imgHeight - Widgeter.gapSpace,
                            child: Text(
                              hd.description,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: Widgeter.descriptionFontSize,
                                fontFamily: Widgeter.fontFamily,
                                decoration: TextDecoration.none,
                              ),
                              maxLines: 12,
                              overflow: TextOverflow.fade,
                            )),
                        Text(
                          hd.allgenres,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: Widgeter.genreFontSize,
                            fontFamily: Widgeter.fontFamily,
                            decoration: TextDecoration.none,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        )
                      ])),
                    ])),
                SizedBox(height: Widgeter.gapSpace),
                Text(
                  hd.name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: Widgeter.nameFontSize,
                    fontFamily: Widgeter.fontFamily,
                    decoration: TextDecoration.none,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )));
  }
}

class MangaPageDescription extends StatelessWidget {
  static double mangaPageDescriptionFontSize = 16.0;

  final String description;

  const MangaPageDescription({Key key, this.description}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      description,
      style: TextStyle(color: Colors.white, fontFamily: Widgeter.fontFamily, fontSize: mangaPageDescriptionFontSize),
    );
  }
}

class MangaPageGenres extends StatelessWidget {
  static double mangaPageGenresFontSize = 20.0;

  final List<Genre> genres;

  const MangaPageGenres({Key key, this.genres}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
        alignment: Alignment.center,
        child: Text(
          genres.map((e) => e.name[0].toUpperCase() + e.name.substring(1)).reduce((value, element) => value += ", " + element),
          style: TextStyle(color: Colors.white, fontFamily: Widgeter.fontFamily, fontSize: mangaPageGenresFontSize),
        ));
  }
}

class MangaPageButtonPanel extends StatelessWidget {
  const MangaPageButtonPanel({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    //TODO finish this after favourites system is in place
    return SizedBox(
      height: 30,
    );
  }
}

class MangaPageChapterPanel extends StatefulWidget {
  final Map<int, ChapterData> chaps;
  final Source s;
  final int expandedIndex;

  const MangaPageChapterPanel({Key key, this.chaps, this.s, this.expandedIndex}) : super(key: key);

  @override
  _MangaPageChapterPanelState createState() => _MangaPageChapterPanelState();
}

class _MangaPageChapterPanelState extends State<MangaPageChapterPanel> {
  static double mangaPageChapterPanelExpansionButtonHeight = 14.0;

  static int _expandedIndex = -1;

  // double _gridHeight = 0;

  void switchDisplayMode() {
    setState(() {
      if (this.widget.expandedIndex == _expandedIndex) {
        _expandedIndex = -1;
      } else {
        _expandedIndex = this.widget.expandedIndex;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _expandedIndex = -1;
    // _gridHeight = min(
    //     MediaQuery.of(context).size.height / 2,
    //     Widgeter.mangaPageChapterButtonHeight * (this.widget.chaps.length.roundToDouble() / n(MediaQuery.of(context).size.width, Widgeter.mangaPageChapterButtonWidth, Widgeter.mangaPageChapterGridSpacingWidth)).ceil()
    // );
  }

  double n(double dimension, double buttonDimension, double buttonSpacing) {
    double sum = buttonDimension;
    int i = 1;
    while (sum < dimension) {
      sum += buttonDimension + buttonSpacing;
      i++;
    }
    return (i - 1).roundToDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          alignment: Alignment.centerLeft,
          child: TextButton(
            child: Text(
              this.widget.s.name,
              style: TextStyle(fontFamily: Widgeter.fontFamily, color: Colors.green, fontSize: mangaPageChapterPanelExpansionButtonHeight),
            ),
            onPressed: () {
              this.switchDisplayMode();
            },
          ),
        ),
        this.widget.expandedIndex == _expandedIndex ? MangaPageCustomChapterGrid(chaps: this.widget.chaps, s: this.widget.s) : MangaPageChapterList(chaps: this.widget.chaps, s: this.widget.s),
      ],
    );
  }
}

// class MangaPageChapterPanel extends StatelessWidget {
//   static double mangaPageChapterPanelExpansionButtonHeight = 14.0;
//
//   final Map<int, ChapterData> chaps;
//   final Source s;
//   final bool displayModeIsGrid;
//   final Function onExpansion;
//
//   const MangaPageChapterPanel({Key key, this.chaps, this.s, this.displayModeIsGrid, this.onExpansion}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Container(
//           alignment: Alignment.centerLeft,
//           child: TextButton(
//             child: Text(
//               s.name,
//               style: TextStyle(fontFamily: Widgeter.fontFamily, color: Colors.green, fontSize: mangaPageChapterPanelExpansionButtonHeight),
//             ),
//             onPressed: () {
//               this.onExpansion.call();
//             },
//           ),
//         ),
//         this.displayModeIsGrid
//             ? MangaPageChapterGrid(chaps: this.chaps)
//             : MangaPageChapterList(chaps: this.chaps,),
//       ],
//     );
//   }
// }

class MangaPageChapterList extends StatelessWidget {
  final Map<int, ChapterData> chaps;
  final Source s;

  const MangaPageChapterList({Key key, this.chaps, this.s}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Widgeter.mangaPageChapterButtonHeight,
      child: ListView.separated(
        itemBuilder: (context, index) {
          return MangaPageChapterButton(
            id: chaps[index].id,
            displayName: chaps[index].chapterNumber == null || chaps[index].chapterNumber.isEmpty ? chaps[index].chapterName : chaps[index].chapterNumber,
            s: s,
          );
        },
        scrollDirection: Axis.horizontal,
        itemCount: chaps.length,
        separatorBuilder: (context, index) {
          return SizedBox(
            width: Widgeter.mangaPageChapterGridSpacingWidth,
          );
        },
      ),
    );
  }
}

class MangaPageChapterGrid extends StatelessWidget {
  final Map<int, ChapterData> chaps;
  final Source s;

  const MangaPageChapterGrid({Key key, this.chaps, this.s}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height / 2,
      ),
      // height: this.height,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: Widgeter.mangaPageChapterButtonWidth,
          mainAxisExtent: Widgeter.mangaPageChapterButtonHeight,
          mainAxisSpacing: Widgeter.mangaPageChapterGridSpacingHeight,
          crossAxisSpacing: Widgeter.mangaPageChapterGridSpacingWidth,
        ),
        itemBuilder: (context, index) {
          return MangaPageChapterButton(
            id: chaps[index].id,
            displayName: chaps[index].chapterNumber == null || chaps[index].chapterNumber.isEmpty ? chaps[index].chapterName : chaps[index].chapterNumber,
            s: s,
          );
        },
        itemCount: chaps.length,
        padding: EdgeInsets.all(0.0),
        shrinkWrap: true,
      ),
    );
  }
}

class MangaPageCustomChapterGrid extends StatefulWidget {
  final Map<int, ChapterData> chaps;
  final Source s;

  const MangaPageCustomChapterGrid({Key key, this.chaps, this.s}) : super(key: key);

  @override
  _MangaPageCustomChapterGridState createState() => _MangaPageCustomChapterGridState();
}

class _MangaPageCustomChapterGridState extends State<MangaPageCustomChapterGrid> {
  ScrollController _controller = ScrollController();
  int numOfChapsPerRow;
  int numOfRows;
  double leftOffsetMain;


  @override
  void initState() {
    super.initState();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    double w = MediaQuery.of(context).size.width;
    numOfChapsPerRow = n(w, Widgeter.mangaPageChapterButtonWidth, Widgeter.mangaPageChapterGridSpacingWidth).floor();
    leftOffsetMain = (w - (numOfChapsPerRow * Widgeter.mangaPageChapterButtonWidth + (numOfChapsPerRow - 1) * Widgeter.mangaPageChapterGridSpacingWidth)) / 2;
    numOfRows = (this.widget.chaps.length / numOfChapsPerRow).ceil();
  }

  void figureOutWhichChapterWasClicked(BuildContext context, TapUpDetails deets){
    double actY = _controller.offset + deets.localPosition.dy;
    double actX = deets.localPosition.dx;
    int colNum = discountHitTest(actY, Widgeter.mangaPageChapterButtonHeight, Widgeter.mangaPageChapterGridSpacingHeight, 0, numOfRows);
    int rowNum = discountHitTest(actX, Widgeter.mangaPageChapterButtonWidth, Widgeter.mangaPageChapterGridSpacingWidth, leftOffsetMain, numOfChapsPerRow);
    if(colNum < 0 || rowNum < 0){
      print("No chap clicked");
    } else {
      print("Chap Clicked: " + ((colNum * numOfChapsPerRow) + rowNum + 1).toString());
      MangaPageChapterButton._onChapterPress.call(context, this.widget.chaps[((colNum * numOfChapsPerRow) + rowNum)].id, this.widget.s);
    }
  }

  int discountHitTest(double offsetClicked, double buttonDimension, double buttonGap, double mainOffset, int numOfGroups){
    double sum = buttonDimension + mainOffset;
    for(int i = 0; i < numOfGroups; i++){
      if(offsetClicked > sum - buttonDimension && offsetClicked < sum){
        return i;
      }
      sum += buttonDimension + buttonGap;
    }
    return -1;
  }

  @override
  Widget build(BuildContext context) {
    double h = MediaQuery.of(context).size.height / 2;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: h,
      ),
      child: GestureDetector(
        onTapUp: (t) => figureOutWhichChapterWasClicked(context, t),
        child: SingleChildScrollView(
          controller: _controller,
          child: CustomPaint(
            painter: MangaPageCustomChapterGridPainter(chaps: this.widget.chaps, s: this.widget.s, controller: _controller, numOfChapsPerRow: this.numOfChapsPerRow, numOfRows: numOfRows, leftOffsetMain: this.leftOffsetMain, viewportHeight: h),
            size: Size(MediaQuery.of(context).size.width, numOfRows * (Widgeter.mangaPageChapterButtonHeight + Widgeter.mangaPageChapterGridSpacingHeight)),
          ),
        ),
      ),
    );
  }

  double n(double dimension, double buttonDimension, double buttonSpacing) {
    double sum = buttonDimension;
    int i = 1;
    while (sum < dimension) {
      sum += buttonDimension + buttonSpacing;
      i++;
    }
    return (i - 1).roundToDouble();
  }
}

class MangaPageCustomChapterGridPainter extends CustomPainter {
  final Paint painter = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0
    ..color = Colors.white;

  final int numOfChapsPerRow;
  final int numOfRows;
  final double leftOffsetMain;

  final double viewportHeight;

  final Map<int, ChapterData> chaps;
  final Source s;
  final ScrollController controller;

  final double radius = 2.0;

  final TextStyle style = TextStyle(
    color: Colors.white,
  );

  final double chapterButtonPaddingX = 5.0;
  final double chapterButtonPaddingY = 5.0;

  MangaPageCustomChapterGridPainter({this.chaps, this.s, this.controller, this.numOfChapsPerRow, this.numOfRows, this.leftOffsetMain, this.viewportHeight});

  @override
  void paint(Canvas canvas, Size size) {
    int rowsScrolled = (controller.offset/ (Widgeter.mangaPageChapterGridSpacingHeight + Widgeter.mangaPageChapterButtonHeight)).floor();
    // int numOfChapsPerRow = n(size.width, Widgeter.mangaPageChapterButtonWidth, Widgeter.mangaPageChapterGridSpacingWidth).floor();
    int startIndex = numOfChapsPerRow * rowsScrolled;
    int rowsThatCanBeDisplayed = n(viewportHeight, Widgeter.mangaPageChapterButtonHeight, Widgeter.mangaPageChapterGridSpacingHeight).ceil() + 1;
    // double leftOffsetMain = (size.width - (numOfChapsPerRow * Widgeter.mangaPageChapterButtonWidth + (numOfChapsPerRow - 1) * Widgeter.mangaPageChapterGridSpacingWidth)) / 2;
    // int startIndex = 0;
    double offsetAtThatRow = rowsScrolled * (Widgeter.mangaPageChapterGridSpacingHeight + Widgeter.mangaPageChapterButtonHeight);
    double top = offsetAtThatRow;
    for (int i = 0; i < rowsThatCanBeDisplayed; i++) {
      if (startIndex >= chaps.length) {
        break;
      }
      double left = leftOffsetMain;
      for (int j = 0; j < numOfChapsPerRow; j++) {
        if (startIndex >= chaps.length) {
          break;
        }
        canvas.drawRRect(RRect.fromLTRBR(left, top, left + Widgeter.mangaPageChapterButtonWidth, top + Widgeter.mangaPageChapterButtonHeight, Radius.circular(radius)), painter);
        TextPainter num = TextPainter(
          text: TextSpan(text: chaps[startIndex].chapterNumber == null || chaps[startIndex].chapterNumber.isEmpty ? chaps[startIndex].chapterName : chaps[startIndex].chapterNumber, style: style),
          maxLines: 1,
          ellipsis: "...",
          textDirection: TextDirection.ltr,
        )
          ..layout(maxWidth: Widgeter.mangaPageChapterButtonWidth - (chapterButtonPaddingX * 2))
          ..paint(canvas, Offset(left + chapterButtonPaddingX, top + chapterButtonPaddingY));
        left += Widgeter.mangaPageChapterButtonWidth + Widgeter.mangaPageChapterGridSpacingWidth;
        startIndex++;
      }
      top += Widgeter.mangaPageChapterButtonHeight + Widgeter.mangaPageChapterGridSpacingHeight;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }

  double n(double dimension, double buttonDimension, double buttonSpacing) {
    double sum = buttonDimension;
    int i = 1;
    while (sum < dimension) {
      sum += buttonDimension + buttonSpacing;
      i++;
    }
    return (i - 1).roundToDouble();
  }
}

class MangaPageChapterButton extends StatelessWidget {
  final String displayName;
  final String id;
  final Source s;

  static Function(BuildContext, String id, Source s) _onChapterPress = (c, t, s) {};

  static void configureFunction(Function(BuildContext, String id, Source s) newFunction) {
    _onChapterPress = newFunction;
  }

  const MangaPageChapterButton({Key key, this.displayName, this.id, this.s}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: ButtonStyle(side: MaterialStateProperty.all(BorderSide(color: Colors.white))),
      child: Text(
        this.displayName,
        softWrap: true,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: Colors.white, fontFamily: Widgeter.fontFamily),
      ),
      onPressed: () {
        _onChapterPress.call(context, this.id, this.s);
      },
    );
  }
}

class MangaPage extends StatefulWidget {
  final CompleteManga manga;

  const MangaPage({Key key, this.manga}) : super(key: key);

  @override
  _MangaPageState createState() => _MangaPageState();
}

class _MangaPageState extends State<MangaPage> {
  @override
  Widget build(BuildContext context) {
    return ListView.separated(
        separatorBuilder: (context, index) {
          return SizedBox(
            height: 30,
          );
        },
        itemBuilder: (context, index) {
          if (index > 3) {
            return MangaPageChapterPanel(
              s: widget.manga.linkedMangas[index - 3 - 1].source,
              chaps: widget.manga.linkedMangas[index - 3 - 1].chapters,
              expandedIndex: index,
            );
          }
          switch (index) {
            case 0:
              return MangaPageGenres(genres: widget.manga.genres);
            case 1:
              return MangaPageDescription(description: widget.manga.description);
            case 2:
              return MangaPageButtonPanel();
            case 3:
              return MangaPageChapterPanel(
                s: widget.manga.source,
                chaps: widget.manga.chapters,
                expandedIndex: 0,
              );
            default:
              return SizedBox(
                height: 30,
              );
          }
        },
        itemCount: 4 + widget.manga.linkedMangas.length);
  }
}

class ChapterPage extends StatelessWidget {
  static Map<String, Map<String, String>> headers = {
    "manganelo": {"Referer": "https://manganelo.com/"},
    "readm": {},
  };

  final String url;
  final Source s;

  const ChapterPage({Key key, this.url, this.s}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: CachedNetworkImage(
      httpHeaders: headers[s.name],
      imageUrl: url,
      progressIndicatorBuilder: (context, s, pr) => Center(
          child: SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                value: pr.progress,
              ))),
      errorWidget: (context, s, data) => Center(
          child: SizedBox(
              width: 30,
              height: 30,
              child: Icon(
                Icons.error,
                color: Colors.white,
              ))),
    ));
  }
}

class ChapterPageFromProvider extends StatelessWidget {
  final ImageProvider provider;

  const ChapterPageFromProvider({Key key, this.provider}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Image(
      image: provider,
      loadingBuilder: (context, widget, i) {
        return Center(
          child: SizedBox(
            child: CircularProgressIndicator(),
            height: 30,
            width: 30,
          ),
        );
      },
    ));
  }
}
