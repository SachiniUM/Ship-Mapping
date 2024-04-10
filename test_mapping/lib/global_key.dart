import 'package:flutter/material.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Woolha.com Flutter Tutorial',
      home: WidgetSizeAndPositionExample(),
    );
  }
}

class WidgetSizeAndPositionExample extends StatefulWidget {

  @override
  State<StatefulWidget> createState() {
    return _WidgetSizeAndPositionExampleState();
  }
}
class _WidgetSizeAndPositionExampleState extends State<WidgetSizeAndPositionExample> {

  final GlobalKey _widgetKey = GlobalKey();
  double _size = 300;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance?.addPostFrameCallback(_getWidgetInfo);
  }

  void _getWidgetInfo(_) {
    final RenderBox renderBox = _widgetKey.currentContext?.findRenderObject() as RenderBox;

    if (renderBox != null) {
      final Size size = renderBox.size;
      print('Size: ${size.width}, ${size.height}');

      final Offset offset = renderBox.localToGlobal(Offset.zero);
      print('Offset: ${offset.dx}, ${offset.dy}');
      print('Position: ${(offset.dx + size.width) / 2}, ${(offset.dy + size.height) / 2}');
    }
  }

  @override
  Widget build(BuildContext context) {
    print('build');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Woolha.com Flutter Tutorial'),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          Positioned(
            left: 50,
            top: 100,
            child: AnimatedContainer(
              duration: const Duration(seconds: 3),
              key: _widgetKey,
              width: _size,
              height: _size,
              color: Colors.teal,
              onEnd: () {

              },
            ),
          ),
          Positioned(
            bottom: 0,
            child: OutlinedButton(
              onPressed: () {
                setState(() {
                  _size = _size == 300 ? 100 : 300;
                });
              },
              child: const Text('Change size'),
            ),
          ),
        ],
      ),
    );
  }
}