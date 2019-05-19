import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'card_data.dart';

void main() => runApp(CardFlip());

class CardFlip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  double scrollPercent = 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Room for Status Bar.
          Container(
            height: 20.0,
            width: double.infinity,
          ),
          // Cards.
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 7.0, bottom: 7.0),
              child: CardFlipper(
                cards: demoCards,
                onScroll: (double scrollPercent) {
                  setState(() {
                    this.scrollPercent = scrollPercent;
                  });
                },
              ),
            ),
          ),
          // Bottom Bar.
          BottomBar(
            cardCount: demoCards.length,
            scrollPercent: scrollPercent,
          ),
        ],
      ),
    );
  }
}

class BottomBar extends StatefulWidget {
  final double scrollPercent;
  final int cardCount;

  BottomBar({
    this.scrollPercent,
    this.cardCount,
  });
  @override
  _BottomBarState createState() => _BottomBarState();
}

class _BottomBarState extends State<BottomBar> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 10.0),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Center(
              child: Icon(Icons.settings),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              height: 5.0,
              child: ScrollIndicator(
                  scrollPercent: widget.scrollPercent,
                  cardCount: widget.cardCount),
            ),
          ),
          Expanded(
            child: Center(
              child: Icon(Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}

class ScrollIndicator extends StatelessWidget {
  final double scrollPercent;
  final int cardCount;

  ScrollIndicator({
    this.scrollPercent,
    this.cardCount,
  });
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ScrollIndicatorPainter(
        cardCount: cardCount,
        scrollPercent: scrollPercent,
      ),
      child: Container(),
    );
  }
}

class ScrollIndicatorPainter extends CustomPainter {
  final int cardCount;
  final double scrollPercent;
  final Paint thumbPaint;
  final Paint trackPaint;

  ScrollIndicatorPainter({
    this.scrollPercent,
    this.cardCount,
  })  : trackPaint = Paint()
          ..color = Color(0xFF444444)
          ..style = PaintingStyle.fill,
        thumbPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    // DrawTrack
    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            0.0,
            0.0,
            size.width,
            size.height,
          ),
          topLeft: Radius.circular(3.0),
          bottomLeft: Radius.circular(3.0),
          topRight: Radius.circular(3.0),
          bottomRight: Radius.circular(3.0),
        ),
        trackPaint);
    // Draw thumb
    final thumbWidth = size.width / cardCount;
    final thumbLeft = scrollPercent * size.width;

    canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(
            thumbLeft,
            0.0,
            thumbWidth,
            size.height,
          ),
          topLeft: Radius.circular(3.0),
          bottomLeft: Radius.circular(3.0),
          topRight: Radius.circular(3.0),
          bottomRight: Radius.circular(3.0),
        ),
        thumbPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class CardFlipper extends StatefulWidget {
  final List<CardViewModel> cards;
  final Function(double scrollPercent) onScroll;

  CardFlipper({this.cards, this.onScroll});
  @override
  _CardFlipperState createState() => _CardFlipperState();
}

class _CardFlipperState extends State<CardFlipper>
    with TickerProviderStateMixin {
  double scrollPercent = 0.0;
  Offset startDrag;
  double startDragPercentScroll;
  double finishScrollStart;
  double finishScrollEnd;
  AnimationController finishScrollController;

  void initState() {
    super.initState();

    finishScrollController = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 150,
      ),
    )..addListener(() {
        setState(() {
          scrollPercent = lerpDouble(
              finishScrollStart, finishScrollEnd, finishScrollController.value);

          if (widget.onScroll != null) {
            widget.onScroll(scrollPercent);
          }
        });
      });
  }

  @override
  void dispose() {
    finishScrollController.dispose();
    super.dispose();
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    startDrag = details.globalPosition;
    startDragPercentScroll = scrollPercent;
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final currDrag = details.globalPosition;
    final dragDistance = currDrag.dx - startDrag.dx;
    final singleCardDragPercent = dragDistance / context.size.width;

    final numCards = widget.cards.length;
    setState(() {
      scrollPercent =
          (startDragPercentScroll + (-singleCardDragPercent / numCards))
              .clamp(0.0, 1.0 - (1 / numCards));
    });

    if (widget.onScroll != null) {
      widget.onScroll(scrollPercent);
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final numCards = widget.cards.length;
    finishScrollStart = scrollPercent;
    finishScrollEnd = (scrollPercent * numCards).round() / numCards;
    finishScrollController.forward(from: 0.0);

    setState(() {
      startDrag = null;
      startDragPercentScroll = null;
    });
  }

  List<Widget> _buildCards() {
    final cardCount = widget.cards.length;

    int index = -1;
    return widget.cards.map((CardViewModel viewModel) {
      ++index;
      return _buildCard(viewModel, index, cardCount, scrollPercent);
    }).toList();
  }

  Matrix4 _buildCardProjection(double scrollPercent) {
    // Pre-multiplied matrix of a projection matrix and a view matrix.
    //
    // Projection matrix is a simplified perspective matrix
    // http://web.iitd.ac.in/~hegde/cad/lecture/L9_persproj.pdf
    // in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, 0.0],
    //  [0.0, 0.0, -perspective, 1.0]]
    //
    // View matrix is a simplified camera view matrix.
    // Basically re-scales to keep object at original size at angle = 0 at
    // any radius in the form of
    // [[1.0, 0.0, 0.0, 0.0],
    //  [0.0, 1.0, 0.0, 0.0],
    //  [0.0, 0.0, 1.0, -radius],
    //  [0.0, 0.0, 0.0, 1.0]]
    final perspective = 0.002;
    final radius = 1.0;
    final angle = scrollPercent * pi / 8;
    final horizontalTranslation = 0.0;
    Matrix4 projection = new Matrix4.identity()
      ..setEntry(0, 0, 1 / radius)
      ..setEntry(1, 1, 1 / radius)
      ..setEntry(3, 2, -perspective)
      ..setEntry(2, 3, -radius)
      ..setEntry(3, 3, perspective * radius + 1.0);

    // Model matrix by first translating the object from the origin of the world
    // by radius in the z axis and then rotating against the world.
    final rotationPointMultiplier = angle > 0.0 ? angle / angle.abs() : 1.0;
    print('Angle: $angle');
    projection *= new Matrix4.translationValues(
            horizontalTranslation + (rotationPointMultiplier * 300.0), 0.0, 0.0) *
        new Matrix4.rotationY(angle) *
        new Matrix4.translationValues(0.0, 0.0, radius) *
        new Matrix4.translationValues(-rotationPointMultiplier * 300.0, 0.0, 0.0);

return projection;
  }

  Widget _buildCard(CardViewModel viewModel, int cardIndex, int cardCount,
      double scrollPercent) {
    final cardScrollPercent = scrollPercent / (1 / cardCount);
    final parallax = scrollPercent - (cardIndex / cardCount);

    return FractionalTranslation(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 14.0,
        ),
        child: Transform(
          transform: _buildCardProjection(cardScrollPercent - cardIndex),
          child: Card(
            viewModel: viewModel,
            parallaxPercent: parallax,
          ),
        ),
      ),
      translation: Offset(
        cardIndex - cardScrollPercent,
        0.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragStart: _onHorizontalDragStart,
      onHorizontalDragUpdate: _onHorizontalDragUpdate,
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Stack(
        children: _buildCards(),
      ),
    );
  }
}

class Card extends StatefulWidget {
  final CardViewModel viewModel;
  final double parallaxPercent;
  Card({
    this.viewModel,
    this.parallaxPercent = 0.0,
  });
  @override
  _CardState createState() => _CardState();
}

class _CardState extends State<Card> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        // Background
        ClipRRect(
          borderRadius: BorderRadius.circular(10.0),
          child: FractionalTranslation(
            translation: Offset(widget.parallaxPercent * 2.0, 0.0),
            child: OverflowBox(
              maxHeight: double.infinity,
              child: Image.asset(
                widget.viewModel.backdropAssetPath,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),

        // Content.
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(top: 30.0, left: 20.0, right: 20.0),
              child: Text(
                widget.viewModel.address.toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20.0,
                  fontFamily: 'petita',
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      '${widget.viewModel.minHeightInFeet}-${widget.viewModel.maxHeightInFeet}',
                      style: TextStyle(
                        fontSize: 140.0,
                        fontFamily: 'petita',
                        letterSpacing: -5.0,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(top: 35.0, left: 5.0),
                      child: Text(
                        'FT'.toUpperCase(),
                        style: TextStyle(
                            fontFamily: 'petita',
                            fontSize: 22.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2.0),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Icon(
                      Icons.wb_sunny,
                      size: 20.0,
                    ),
                    Padding(
                      padding: EdgeInsets.all(6.5),
                    ),
                    Text(
                      '${widget.viewModel.tempInDegrees}°',
                      style: TextStyle(
                        fontFamily: 'petita',
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                top: 50.0,
                bottom: 50.0,
              ),
              child: InkWell(
                onTap: () {},
                splashColor: Colors.white,
                highlightColor: Colors.white,
                child: Container(
                  decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(30.0),
                      border: Border.all(width: 1.5, color: Colors.white)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30.0, vertical: 15.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        Text(
                          widget.viewModel.weatherType,
                          style: TextStyle(
                            fontFamily: 'petita',
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 10.0,
                          ),
                          child: Icon(
                            Icons.wb_cloudy,
                            size: 15.0,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${widget.viewModel.windSpeedInMph} mph ${widget.viewModel.cardinalDirection}',
                          style: TextStyle(
                            fontFamily: 'petita',
                            fontWeight: FontWeight.bold,
                            fontSize: 15.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
