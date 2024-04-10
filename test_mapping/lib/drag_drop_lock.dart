import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MaterialApp(
    home: CustomPainterDraggableLock(),
  ));
}

class CustomPainterDraggableLock extends StatefulWidget {
  @override
  _CustomPainterDraggableLockState createState() => _CustomPainterDraggableLockState();
}

class _CustomPainterDraggableLockState extends State<CustomPainterDraggableLock> {
  List<Rect> rects = [];
  List<Color> colors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.yellow,
    Colors.orange
  ];
  int _draggingIndex = -1; // Index of the rectangle being dragged
  Offset _draggingOffset = Offset.zero; // Offset of the dragging position relative to the rectangle's position
  bool _lockDragging = false; // Flag to lock/unlock dragging

  @override
  void initState() {
    super.initState();
    // Add initial rectangles
    rects.add(Rect.fromLTWH(0, 0, 100, 100));
    rects.add(Rect.fromLTWH(150, 0, 100, 100));
    rects.add(Rect.fromLTWH(0, 150, 100, 100));
    rects.add(Rect.fromLTWH(150, 150, 100, 100));
    rects.add(Rect.fromLTWH(300, 0, 100, 100));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drag and Drop'),
        actions: [
          IconButton(
            icon: Icon(_lockDragging ? Icons.lock : Icons.lock_open),
            onPressed: () {
              setState(() {
                _lockDragging = !_lockDragging;
              });
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/ship.png', // Replace this with your image asset
              fit: BoxFit.cover,
            ),
          ),
          // Custom Paint with draggable rectangles
          GestureDetector(
            onTap: () {
              if (_lockDragging) {
                _handleLockTap();
              }
            },
            onPanStart: (details) {
              if (!_lockDragging) {
                _checkDragStart(details.localPosition);
              }
            },
            onPanEnd: (details) {
              _draggingIndex = -1; // Reset dragging index
            },
            onPanUpdate: (details) {
              if (!_lockDragging) {
                _handleDragUpdate(details.localPosition);
              }
            },
            child: CustomPaint(
              painter: RectanglePainter(rects, colors),
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }

  // Check if the drag starts within any rectangle
  void _checkDragStart(Offset localPosition) {
    for (int i = 0; i < rects.length; i++) {
      if (rects[i].contains(localPosition)) {
        setState(() {
          _draggingIndex = i;
          _draggingOffset = localPosition - Offset(rects[i].left, rects[i].top);
        });
        break;
      }
    }
  }

  // Handle dragging update
  void _handleDragUpdate(Offset localPosition) {
    if (_draggingIndex != -1) {
      setState(() {
        rects[_draggingIndex] = Rect.fromLTWH(
          localPosition.dx - _draggingOffset.dx,
          localPosition.dy - _draggingOffset.dy,
          rects[_draggingIndex].width,
          rects[_draggingIndex].height,
        );
      });
    }
  }

  // Handle lock/unlock icon tap
  void _handleLockTap() {
    setState(() {
      _lockDragging = !_lockDragging;
    });
  }
}

class RectanglePainter extends CustomPainter {
  final List<Rect> rects;
  final List<Color> colors;

  RectanglePainter(this.rects, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < rects.length; i++) {
      canvas.drawRect(rects[i], Paint()..color = colors[i]);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}