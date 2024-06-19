import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SizePositionPage extends StatefulWidget {
  @override
  _SizePositionPageState createState() => _SizePositionPageState();
}

class _SizePositionPageState extends State<SizePositionPage> with WidgetsBindingObserver {
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;

  final List<Offset> dotPositions = [
    Offset(0.2, 0.6),
    Offset(-0.1, 0.8),
    Offset(0.2, 0.4),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
  }

  getSizeAndPosition() {
    final RenderBox? _imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (_imageBox != null) {
      imageSize = _imageBox.size;
      imagePosition = _imageBox.localToGlobal(Offset.zero);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;

    return Scaffold(
      appBar: AppBar(
        title: Text("Size Position"),
      ),
      body: Container(
        alignment: Alignment.center,
        child: AspectRatio(
          key: _imageKey,
          aspectRatio: 147/500,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/ship5.jpg',
              ),
              ...dotPositions.map((position) => CustomPaint(
                size: Size(10, 10),
                painter: RedDotPainter(
                  position: _calculateDotPosition(position, orientation),
                ),
              )),
              Text("Size - $imageSize\nwidth- ${imageSize.width} Height- ${imageSize.height}\nPosition - $imagePosition \nx - ${imagePosition.dx} y-${imagePosition.dy}"),
            ],
          ),
        ),
      ),
    );
  }

  Offset _calculateDotPosition(Offset position, Orientation orientation) {
    return Offset(
      // position.dx * (orientation == Orientation.portrait ? imageSize.width : imageSize.height),
      // position.dy * (orientation == Orientation.portrait ? imageSize.height : imageSize.width),
      position.dx * imageSize.width, position.dy * imageSize.height
    );
  }
}

class RedDotPainter extends CustomPainter {
  final Offset position;

  RedDotPainter({required this.position});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = Colors.blue;
    canvas.drawCircle(position, 10, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

void main() {
  runApp(MaterialApp(
    home: SizePositionPage(),
  ));
}



// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
//
// class SizePositionPage extends StatefulWidget {
//   @override
//   _SizePositionPageState createState() => _SizePositionPageState();
// }
//
// class _SizePositionPageState extends State<SizePositionPage> {
//   final GlobalKey _imageKey = GlobalKey();
//   late Size imageSize = Size.zero; // Initialize with zero size
//   late Offset imagePosition = Offset.zero; // Initialize with zero position
//
//   // List to store the positions of the red dots
//   final List<Offset> dotPositions = [
//     Offset(0.2, 0.6),
//     Offset(-0.1, 0.8),
//     Offset(0.2, 0.4),
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
//   }
//
//   getSizeAndPosition() {
//     final RenderBox? _imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
//     if (_imageBox != null) {
//       imageSize = _imageBox.size;
//       print('image box size ${_imageKey.currentContext?.size}');
//       imagePosition = _imageBox.localToGlobal(Offset.zero);
//       setState(() {});
//       // print('inside size and position');
//       // print('size $imageSize');
//       // print('position $imagePosition');
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // Retrieve the orientation using MediaQuery
//     final Orientation orientation = MediaQuery.of(context).orientation;
//     print('orientation $orientation');
//     print('screen width ${MediaQuery.of(context).size.width}');
//     print('screen height ${MediaQuery.of(context).size.height}');
//     print('width- ${imageSize.width} Height- ${imageSize.height}');
//     print('x - ${imagePosition.dx} y-${imagePosition.dy}');
//     return Scaffold(
//       appBar: AppBar(
//         title: Text("Size Position"),
//       ),
//       body: Container(
//         alignment: Alignment.center,
//             child: AspectRatio(
//               key: _imageKey,
//               aspectRatio: 147/500,
//               child: Stack(
//                 children: [
//                     Image.asset(
//                       'assets/images/ship5.jpg',
//                       // key: _imageKey,
//                       // fit: BoxFit.contain,
//                     ),
//                 // CustomPaint(
//                 //     size: Size(10, 10), // Size of the red dot
//                 //     painter: RedDotPainter(position: Offset(-0.1 * imageSize.width, 0.6 * imageSize.height)),
//                 //   ),
//                 //   CustomPaint(
//                 //     size: Size(10, 10), // Size of the red dot
//                 //     painter: RedDotPainter(
//                 //       position: orientation == Orientation.portrait
//                 //           ? Offset(-0.1 * MediaQuery.of(context).size.width, 0.6 * MediaQuery.of(context).size.height)
//                 //           : Offset(-0.1 * MediaQuery.of(context).size.height, -0.6 * MediaQuery.of(context).size.width),
//                 //     ),
//                 //   ),
//                   ...dotPositions.map((position) => CustomPaint(
//                     size: Size(10, 10),
//                     painter: RedDotPainter(
//                       position: _calculateDotPosition(position, orientation),
//                     ),
//                   )),
//                   Text("Size - $imageSize\nwidth- ${imageSize.width} Height- ${imageSize.height}\nPosition - $imagePosition \nx - ${imagePosition.dx} y-${imagePosition.dy}"),
//                   // Text('width- ${imageSize.width} Height- ${imageSize.height}'),
//                   // Text("Position - $imagePosition "),
//                   // Text('x - ${imagePosition.dx} y-${imagePosition.dy}'),
//                 ],
//               ),
//             ),
//
//             // CustomPaint(
//             //   size: Size(10, 10), // Size of the red dot
//             //   painter: RedDotPainter(),
//             // ),
//       )
//     );
//
//   }
//   Offset _calculateDotPosition(Offset position, Orientation orientation) {
//     return Offset(
//       position.dx * (orientation == Orientation.portrait ? imageSize.width : imageSize.height),
//       position.dy * (orientation == Orientation.portrait ? imageSize.height : imageSize.width),
//     );
//   }
// }
//
// class RedDotPainter extends CustomPainter {
//   final Offset position;
//
//   RedDotPainter({required this.position});
//   @override
//   void paint(Canvas canvas, Size size) {
//     final Paint paint = Paint()..color = Colors.blue;
//     canvas.drawCircle(position, 10, paint); // Adjust the radius as needed
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }
//
// void main() {
//   runApp(MaterialApp(
//     home: SizePositionPage(),
//   ));
// }
