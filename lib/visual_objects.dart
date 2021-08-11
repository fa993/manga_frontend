import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:manga_frontend/api_objects.dart';
import 'package:transparent_image/transparent_image.dart';

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
}

class MangaThumbnail extends StatelessWidget {
  final MangaHeading hd;
  final Function(DismissDirection) onDismiss;

  const MangaThumbnail({Key key, this.hd, this.onDismiss}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ObjectKey(hd.id),
      confirmDismiss: (d) {
        onDismiss.call(d);
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
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                          hd.allGenres,
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
                      ],
                    ),
                  ),
                ],
              ),
            ),
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
        ),
      ),
    );
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
  final String mangaId;
  final Map<int, ChapterData> chaps;
  final Source s;
  final int expandedIndex;

  static Function(BuildContext, Chapters) onClick = (c, t) => {};

  const MangaPageChapterPanel({Key key, this.mangaId, this.chaps, this.s, this.expandedIndex}) : super(key: key);

  @override
  _MangaPageChapterPanelState createState() => _MangaPageChapterPanelState();
}

class _MangaPageChapterPanelState extends State<MangaPageChapterPanel> {
  static double mangaPageChapterPanelExpansionButtonHeight = 14.0;

  static int _expandedIndex = -1;

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
  }

  Function onClick(int index) {
    return (context) {
      MangaPageChapterPanel.onClick.call(context, Chapters.all(mangaId: widget.mangaId, chaps: widget.chaps, currentIndex: index, s: widget.s));
    };
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
        this.widget.expandedIndex == _expandedIndex
            ? MangaPageCustomChapterGrid(
                chaps: this.widget.chaps,
                onClick: onClick,
              )
            : MangaPageChapterList(
                chaps: this.widget.chaps,
                onClick: onClick,
              ),
      ],
    );
  }
}

class MangaPageChapterList extends StatelessWidget {
  final Function onClick;
  final Map<int, ChapterData> chaps;

  const MangaPageChapterList({Key key, this.onClick, this.chaps}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: Widgeter.mangaPageChapterButtonHeight,
      child: ListView.separated(
        itemBuilder: (context, index) {
          return MangaPageChapterButton(
            displayName: chaps[index].chapterNumber == null || chaps[index].chapterNumber.isEmpty ? chaps[index].chapterName : chaps[index].chapterNumber,
            onClick: onClick.call(index),
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

class MangaPageCustomChapterGrid extends StatefulWidget {
  final Function onClick;
  final Map<int, ChapterData> chaps;

  const MangaPageCustomChapterGrid({Key key, this.chaps, this.onClick}) : super(key: key);

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

  void figureOutWhichChapterWasClicked(BuildContext context, TapUpDetails deets) {
    double actY = _controller.offset + deets.localPosition.dy;
    double actX = deets.localPosition.dx;
    int colNum = discountHitTest(actY, Widgeter.mangaPageChapterButtonHeight, Widgeter.mangaPageChapterGridSpacingHeight, 0, numOfRows);
    int rowNum = discountHitTest(actX, Widgeter.mangaPageChapterButtonWidth, Widgeter.mangaPageChapterGridSpacingWidth, leftOffsetMain, numOfChapsPerRow);
    if (colNum < 0 || rowNum < 0) {
      print("No chap clicked");
    } else {
      int index = ((colNum * numOfChapsPerRow) + rowNum);
      print("Chap Clicked: " + (index + 1).toString());
      // this.widget.onClick.call(index).call(context);
    }
  }

  int discountHitTest(double offsetClicked, double buttonDimension, double buttonGap, double mainOffset, int numOfGroups) {
    double sum = buttonDimension + mainOffset;
    for (int i = 0; i < numOfGroups; i++) {
      if (offsetClicked > sum - buttonDimension && offsetClicked < sum) {
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
            painter: MangaPageCustomChapterGridPainter(chaps: this.widget.chaps, controller: _controller, numOfChapsPerRow: this.numOfChapsPerRow, numOfRows: numOfRows, leftOffsetMain: this.leftOffsetMain, viewportHeight: h),
            size: Size(MediaQuery.of(context).size.width, numOfRows * (Widgeter.mangaPageChapterButtonHeight + Widgeter.mangaPageChapterGridSpacingHeight)),
          ),
        ),
      ),
    );
  }

  int n(double dimension, double buttonDimension, double buttonSpacing) {
    double minus = dimension - buttonDimension;
    int x = minus ~/ (buttonDimension + buttonSpacing);
    return x;
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

  final ScrollController controller;

  final double radius = 2.0;

  final TextStyle style = TextStyle(
    color: Colors.white,
  );

  final double chapterButtonPaddingX = 5.0;
  final double chapterButtonPaddingY = 5.0;

  MangaPageCustomChapterGridPainter({this.chaps, this.controller, this.numOfChapsPerRow, this.numOfRows, this.leftOffsetMain, this.viewportHeight});

  @override
  void paint(Canvas canvas, Size size) {
    int rowsScrolled = (controller.offset / (Widgeter.mangaPageChapterGridSpacingHeight + Widgeter.mangaPageChapterButtonHeight)).floor();
    // int numOfChapsPerRow = n(size.width, Widgeter.mangaPageChapterButtonWidth, Widgeter.mangaPageChapterGridSpacingWidth).floor();
    int startIndex = numOfChapsPerRow * rowsScrolled;
    int rowsThatCanBeDisplayed = n(viewportHeight, Widgeter.mangaPageChapterButtonHeight, Widgeter.mangaPageChapterGridSpacingHeight).ceil() + 1 + 1;
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

  int n(double dimension, double buttonDimension, double buttonSpacing) {
    double minus = dimension - buttonDimension;
    int x = minus ~/ (buttonDimension + buttonSpacing);
    return x;
  }
}

class MangaPageChapterButton extends StatelessWidget {
  final Function onClick;
  final String displayName;

  const MangaPageChapterButton({Key key, this.onClick, this.displayName}) : super(key: key);

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
        this.onClick.call(context);
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
              mangaId: widget.manga.id,
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
                mangaId: widget.manga.id,
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
  final double width;

  const ChapterPage({Key key, this.url, this.s, this.width}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CachedNetworkImage(
      httpHeaders: headers[s.name],
      imageUrl: url,
      width: width,
      fadeInDuration: Duration.zero,
      progressIndicatorBuilder: (context, s, pr) => Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: pr.progress,
          ),
        ),
      ),
      errorWidget: (context, s, data) => Center(
        child: SizedBox(
          width: 30,
          height: 30,
          child: Icon(
            Icons.error,
            color: Colors.white,
          ),
        ),
      ),
    );
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

class ReaderAppBar extends PreferredSize {
  @override
  final PreferredSizeWidget child;
  final AnimationController controller;
  final bool visible;
  final bool toggle;

  const ReaderAppBar({Key key, this.child, this.controller, this.visible, this.toggle}) : super(key: key);

  @override
  Size get preferredSize => child.preferredSize;

  @override
  Widget build(BuildContext context) {
    visible ? controller.reverse() : controller.forward();
    return SlideTransition(
      child: child,
      position: Tween<Offset>(
        begin: Offset.zero,
        end: Offset(0, -1),
      ).animate(CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn)),
    );
  }
}

class ReaderPageSettingsPanel extends StatefulWidget {
  final Function onLeftToRight;
  final Function onRightToLeft;
  final Function onUpToDown;

  const ReaderPageSettingsPanel({Key key, this.onLeftToRight, this.onRightToLeft, this.onUpToDown}) : super(key: key);

  @override
  _ReaderPageSettingsPanelState createState() => _ReaderPageSettingsPanelState();
}

class _ReaderPageSettingsPanelState extends State<ReaderPageSettingsPanel> {
  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.yellow,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(icon: Icon(Icons.arrow_forward), onPressed: () => this.widget.onLeftToRight.call()),
          IconButton(icon: Icon(Icons.arrow_back), onPressed: () => this.widget.onRightToLeft.call()),
          IconButton(icon: Icon(Icons.arrow_downward), onPressed: () => this.widget.onUpToDown.call()),
        ],
      ),
    );
  }
}

class ReaderPageInfoPanel extends StatelessWidget {
  final String dateString;
  final String batteryString;
  final String pageInfo;

  const ReaderPageInfoPanel({Key key, this.dateString, this.batteryString, this.pageInfo}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(4.0, 2.0, 2.0, 2.0),
      color: Colors.black54,
      child: Text(
        (this.dateString + " " + this.batteryString + " " + this.pageInfo).trim(),
        // _formatter.format(DateTime.now()) + " Battery: " + snapshot.data.toString() + "% " + this.pageInfo,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}

class SideWheel extends CustomPainter {
  static const double length = 10;
  static const double margin = 1;

  final double currentRotationAngle;
  final Offset center;
  final bool startFromLeft;
  final double radius;

  SideWheel({this.currentRotationAngle, this.startFromLeft, this.center, this.radius});

  Paint _wheelPaint = Paint()
    ..color = Colors.black
    ..style = PaintingStyle.fill;

  Paint _linePaint = Paint()..color = Colors.white;

  Offset _getPoint(Offset center, double radius, double degrees) {
    double x = center.dx + _getX(radius, degrees);
    double y = center.dy + _getY(radius, degrees);
    return Offset(x, y);
  }

  double _getX(double radius, double degrees) {
    return radius * cos(_degreeToRadians(degrees));
  }

  double _getY(double radius, double degrees) {
    return radius * sin(_degreeToRadians(degrees));
  }

  double _degreeToRadians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawCircle(center, radius, _wheelPaint);
    // canvas.drawArc(Rect.fromCenter(center: center, width: size.width, height: size.height), startFromLeft ? -pi / 2 : pi / 2, startFromLeft ? -pi : pi, true, _wheelPaint);
    double diff = currentRotationAngle - currentRotationAngle.floor();
    if (startFromLeft) {
      int lower = -90;
      while (lower <= 90) {
        canvas.drawLine(_getPoint(center, radius - length - margin, lower.toDouble() + diff), _getPoint(center, radius - margin, lower.toDouble() + diff), _linePaint);
        lower += 8;
      }
    } else {
      int lower = -180;
      while (lower <= -90) {
        canvas.drawLine(_getPoint(center, radius - length - margin, lower.toDouble() + diff), _getPoint(center, radius - margin, lower.toDouble() + diff), _linePaint);
        lower += 8;
      }
      lower = 90;
      while (lower <= 180) {
        canvas.drawLine(_getPoint(center, radius - length - margin, lower.toDouble() + diff), _getPoint(center, radius - margin, lower.toDouble() + diff), _linePaint);
        lower += 8;
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    SideWheel old = oldDelegate as SideWheel;
    return !(old.currentRotationAngle == this.currentRotationAngle && old.startFromLeft == this.startFromLeft && old.center == this.center);
  }
}

class FavouriteManga extends StatelessWidget {
  final Function onClick;
  final String name;
  final String coverURL;

  const FavouriteManga({Key key, this.name, this.coverURL, this.onClick}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: this.coverURL,
            height: Widgeter.imgHeight,
            width: Widgeter.imgWidth,
            fit: BoxFit.contain,
          ),
          Text(
            name,
            style: TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
