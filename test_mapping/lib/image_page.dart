import 'package:flutter/material.dart';

class ImageMap extends StatefulWidget {
  const ImageMap({super.key});
  @override
  State<ImageMap> createState() => _ImageMapState();
}

class _ImageMapState extends State<ImageMap> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var imageWidth = MediaQuery.of(context).size.width;
    var imageHeight = MediaQuery.of(context).size.height -
        AppBar().preferredSize.height -
        MediaQuery.of(context).padding.top;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Image Mapping',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: InteractiveViewer(
        panEnabled: false, // Set it to false to prevent panning.
        boundaryMargin: EdgeInsets.all(80),
        minScale: 0.5,
        maxScale: 4,
        child: Container(
          width: imageWidth,
          height: imageHeight,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/ship.png',
                fit: BoxFit.fill,
              ),
              CustomPaint(
                painter: YourRect(
                  leftFraction: 0.45,
                  topFraction: 0.15,
                  rightFraction: 0.50,
                  bottomFraction: 0.19,
                  color: Color(0xFF0099FF),
                ),
              ),
              CustomPaint(
                painter: YourRect(
                  leftFraction: 0.45,
                  topFraction: 0.28,
                  rightFraction: 0.50,
                  bottomFraction: 0.31,
                  color: Colors.red,
                ),
              ),
              CustomPaint(
                painter: YourRect(
                  leftFraction: 0.45,
                  topFraction: 0.6,
                  rightFraction: 0.50,
                  bottomFraction: 0.65,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class YourRect extends CustomPainter {
  final double leftFraction;
  final double topFraction;
  final double rightFraction;
  final double bottomFraction;
  final Color color;

  YourRect({
    required this.leftFraction,
    required this.topFraction,
    required this.rightFraction,
    required this.bottomFraction,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final left = leftFraction * size.width;
    final top = topFraction * size.height;
    final right = rightFraction * size.width;
    final bottom = bottomFraction * size.height;

    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
