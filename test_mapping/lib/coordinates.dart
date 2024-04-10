import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class Coordinates extends StatefulWidget {
  @override
  _CoordinatesState createState() => _CoordinatesState();
}

class _CoordinatesState extends State<Coordinates> {
  List<Offset> dotCoordinates = [];
  double imageWidth = 0;
  int ratioWidth = 5;
  int ratioHeight = 8;
  // var ratio = 5/8;


  @override
  void initState() {
    super.initState();
    loadDotCoordinates();

  }

  void loadDotCoordinates() {
    // Simulate loading dot coordinates, you can replace this with your own logic to load dot coordinates
    // For example, fetching from an API or reading from a file.
    setState(() {
      dotCoordinates = [
        Offset(0.2, 0.3), // Example: x = 20% of image width, y = 30% of image height
        Offset(-0.2, 0.3), // Example: x = 50% of image width, y = 60% of image height
      ];
    });
  }

  // Function to calculate pixel values based on child aspect ratio (5:8)
  Size calculatePixelValues(Size imageSize) {

    // Aspect ratio of 5:8
    double aspectRatio = ratioWidth/ratioHeight;

    // Calculate height based on aspect ratio
    double targetWidth = imageSize.height * aspectRatio;

    // Calculate pixel values
    double pixelWidth = targetWidth * ui.window.devicePixelRatio;
    double pixelHeight = imageSize.height * ui.window.devicePixelRatio;

    return Size(pixelWidth, pixelHeight);
  }

  @override
  Widget build(BuildContext context) {
    print('screen width ${MediaQuery.of(context).size.width}');
    print('screen height ${MediaQuery.of(context).size.height}');
    imageWidth = MediaQuery.of(context).size.width ;
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: LayoutBuilder(
            builder: (context, constraints) {
              print('contraint width ${constraints.maxWidth}');
              print('constraint height ${constraints.maxHeight}');
              // Example image dimensions
              Size imageSize = Size(constraints.maxWidth, constraints.maxHeight); // Width: 1920, Height: 1080

              // Calculate pixel values
              Size pixelValues = calculatePixelValues(imageSize);

              print('Pixel Width: ${pixelValues.width}');
              print('Pixel Height: ${pixelValues.height}');
              return AspectRatio(
                aspectRatio: ratioWidth/ratioHeight, // Assuming aspect ratio of the image
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Your image goes here
                    Image.asset(
                      'assets/images/ship5.jpg',
                      fit: BoxFit.contain,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                    ),
                    // Custom Paint for drawing dots
                    CustomPaint(
                      painter: DotPainter(dotCoordinates, constraints.maxWidth, constraints.maxHeight),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class DotPainter extends CustomPainter {
  final List<Offset> points;
  final double imageWidth;
  final double imageHeight;

  DotPainter(this.points, this.imageWidth, this.imageHeight);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 5.0;

    for (var point in points) {
      // Convert normalized coordinates to actual coordinates
      double x = point.dx * imageWidth;
      double y = point.dy * imageHeight;
      canvas.drawCircle(Offset(x, y), 10.0, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}




// import 'package:flutter/material.dart';
//
// class Coordinates extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: Scaffold(
//         appBar: AppBar(
//           title: Text('Custom Paint Example'),
//         ),
//         body: ImageWithDots(),
//       ),
//     );
//   }
// }
//
// class ImageWithDots extends StatelessWidget {
//   // Coordinates for the dots normalized to the image size
//   final List<Offset> dotCoordinates = [
//     Offset(0.2, 0.3), // Example: x = 20% of image width, y = 30% of image height
//     Offset(0.5, 0.6), // Example: x = 50% of image width, y = 60% of image height
//   ];
//
//   @override
//   Widget build(BuildContext context) {
//     return LayoutBuilder(
//       builder: (context, constraints) {
//         return AspectRatio(
//           aspectRatio: 5 / 4, // Assuming aspect ratio of the image
//           child: Stack(
//             children: [
//               // Your image goes here
//               Image.asset(
//                 'assets/images/ship5.jpg',
//                 fit: BoxFit.contain,
//                 width: constraints.maxWidth,
//                 height: constraints.maxHeight,
//               ),
//               // Custom Paint for drawing dots
//               CustomPaint(
//                 painter: DotPainter(dotCoordinates, constraints.maxWidth, constraints.maxHeight),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }
//
// class DotPainter extends CustomPainter {
//   final List<Offset> points;
//   final double imageWidth;
//   final double imageHeight;
//
//   DotPainter(this.points, this.imageWidth, this.imageHeight);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.red
//       ..strokeCap = StrokeCap.round
//       ..strokeWidth = 5.0;
//
//     for (var point in points) {
//       // Convert normalized coordinates to actual coordinates
//       double x = point.dx * imageWidth;
//       double y = point.dy * imageHeight;
//       canvas.drawCircle(Offset(x, y), 10.0, paint);
//     }
//   }
//
//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) {
//     return true;
//   }
// }