import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'package:zoom_widget/zoom_widget.dart';

class ShowDataRepresentation extends StatefulWidget {
  @override
  _ShowDataRepresentationState createState() => _ShowDataRepresentationState();
}

class WorkTask {
  String status;
  int workStaId;

  WorkTask(this.status, this.workStaId);
}

class _ShowDataRepresentationState extends State<ShowDataRepresentation> {
  List<Rect> rects = [];
  List<Color> colors = [
    Colors.blue,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.brown,
    Colors.orange
  ];
  List<WorkTask> workTasks = [];
  int _draggingIndex = -1; // Index of the rectangle being dragged
  Offset _draggingOffset = Offset.zero; // Offset of the dragging position relative to the rectangle's position

  @override
  void initState() {
    super.initState();
    // Add initial rectangles
    // rects.add(Rect.fromLTWH(0, 0, 75, 75));
    // rects.add(Rect.fromLTWH(150, 0, 75, 75));
    // rects.add(Rect.fromLTWH(0, 150, 75, 75));
    // rects.add(Rect.fromLTWH(150, 150, 75, 75));
    // rects.add(Rect.fromLTWH(300, 0, 75, 75));

    initializeWorkTasks();
    ObjectBoxStore.initStore().then((_) {
      fetchData();
    });

  }

  @override
  void dispose(){
    super.dispose();
    ObjectBoxStore.closeStore();
  }

  @override
  void didChangeDependencies() {
    print('inside did change');
    super.didChangeDependencies();
    // Call fetchData when the dependencies of the widget change,
    // which means the widget is being displayed or resumed.
    fetchData();
  }

  Future<void> fetchData() async{
    print('inside fetch data');
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();

    // Retrieve and print data from ObjectBox
    final storedWorkStations = box.getAll();

    // Populate rects list with fetched data
    setState(() {
      late var height;
      var width;
      if(MediaQuery.of(context).size.width > MediaQuery.of(context).size.height){
        height = MediaQuery.of(context).size.width * 0.05;
      }else{
        height = MediaQuery.of(context).size.height * 0.05;
      }
      // rects = storedWorkStations.map((ws) => Rect.fromLTWH(ws.left, ws.top, MediaQuery.of(context).size.width * 0.08, MediaQuery.of(context).size.height * 0.05)).toList();
      rects = storedWorkStations.map((ws) => Rect.fromLTWH(ws.left, ws.top, height, height)).toList();
    });

    print("Stored WorkStations:");
    storedWorkStations.forEach((ws) {
      print("WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
    });

    ObjectBoxStore.closeStore();
  }



  void initializeWorkTasks() {
    // Predefined list of work tasks with coordinates and statuses
    workTasks = [
      WorkTask('Assigned', 1),
      WorkTask('Assigned', 2),
      WorkTask('Assigned', 3),
      WorkTask('Assigned', 5),
      WorkTask('Ongoing', 1),
      WorkTask('Ongoing', 1),
      WorkTask('Ongoing', 5),
      WorkTask('Ongoing', 2),
      WorkTask('Completed', 5),
      WorkTask('Completed', 4),
    ];
  }

  bool _maximumZoomReached = false;
  Size _currentImageSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Drag and Drop'),
        // actions: [
        //   IconButton(
        //     icon: Icon(Icons.edit),
        //     onPressed: (){Navigator.pushNamed(context, '/dragAndDropEdit');},
        //   ),
        // ],
      ),
      body: Zoom(
          backgroundColor: Colors.white,
          maxZoomWidth: MediaQuery.of(context).size.width, // Specify the width of the zoomable area
          maxZoomHeight: MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top, // Specify the height of the zoomable area
          // maxZoomWidth: 500, // Specify the width of the zoomable area
          // maxZoomHeight: 500, // Specify the height of the zoomable area
          maxScale: 3.0,
          enableScroll: true,

          onScaleUpdate: (scale, zoom) {
            if (scale > 1.0) {
              setState(() {
                _maximumZoomReached = true;
              });
            }else{
              setState(() {
                _maximumZoomReached = false;
              });
            }
          },
          child: Container(
            height: MediaQuery.of(context).size.height -
                AppBar().preferredSize.height -
                MediaQuery.of(context).padding.top,
            width: MediaQuery.of(context).size.width,
            child: Stack(
              children: [
                // Background Image
                Positioned.fill(
                  child: Image.asset(
                    'assets/images/ship5.jpg', // Replace this with your image asset
                    fit: BoxFit.contain,
                  ),
                ),
                // Custom Paint with draggable rectangles
                Container(
                  child: CustomPaint(
                    painter: RectanglePainter(rects, colors,workTasks,_maximumZoomReached,context),
                    child: Container(),
                  ),
                ),
                Positioned(
                  top: 20,
                  left: 20,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Assigned', Colors.red),
                        _buildLegendItem('Ongoing', Colors.yellow),
                        _buildLegendItem('Completed', Colors.green),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: () {
      //     Navigator.pushNamed(context, '/dragAndDropEdit');
      //   },
      //   foregroundColor: Colors.white,
      //   backgroundColor: Colors.blue,
      //   splashColor: Colors.white,
      //   // shape: customizations[index].$3,
      //   child: const Icon(Icons.edit),
      // ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  void _getImageSize(BuildContext context) {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    setState(() {
      _currentImageSize = renderBox.size;
    });
  }
}



class RectanglePainter extends CustomPainter {
  final List<Rect> rects;
  final List<Color> colors;
  final List<WorkTask> workTasks;
  final bool maximumZoomReached;
  final BuildContext context;


  RectanglePainter(this.rects, this.colors, this.workTasks, this.maximumZoomReached,this.context);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < rects.length; i++) {
      canvas.drawRect(rects[i], Paint()..color = colors[i]);

      if (maximumZoomReached) {
        // Initialize counters for different task statuses
        int assignedCount = 0;
        int ongoingCount = 0;
        int completedCount = 0;

        // Count tasks with different statuses for the current rectangle
        for (var task in workTasks) {
          if (task.workStaId == i + 1) {
            if (task.status == 'Assigned') {
              assignedCount++;
            } else if (task.status == 'Ongoing') {
              ongoingCount++;
            } else if (task.status == 'Completed') {
              completedCount++;
            }
          }
        }

        // Draw text showing the count of work tasks with different statuses in the middle of the rectangle
        TextPainter painter = TextPainter(
          text: TextSpan(
            text: 'Assigned: $assignedCount\nOngoing: $ongoingCount\nCompleted: $completedCount',
            style: TextStyle(color: Colors.white, fontSize: 11.0),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        painter.layout();
        painter.paint(
          canvas,
          Offset(rects[i].center.dx - painter.width / 2, rects[i].center.dy - painter.height / 2),
        );
      }else {
        // Initialize counters for different task statuses
        int assignedCount = 0;
        int ongoingCount = 0;
        int completedCount = 0;

        // Count tasks with different statuses for the current rectangle
        for (var task in workTasks) {
          if (task.workStaId == i + 1) {
            if (task.status == 'Assigned') {
              assignedCount++;
            } else if (task.status == 'Ongoing') {
              ongoingCount++;
            } else if (task.status == 'Completed') {
              completedCount++;
            }
          }
        }

        // Draw circles showing the count of work tasks with different statuses in the middle of the rectangle
        // double circleRadius = 15.0;
        late double circleRadius;
        if(MediaQuery.of(context).size.width > MediaQuery.of(context).size.height){
          circleRadius = MediaQuery.of(context).size.width * 0.01;
        }else{
          circleRadius = MediaQuery.of(context).size.height * 0.01;
        }

        double offsetX = 0.0;
        double offsetY = 0.0;

        offsetX = 0.0; // Reset offsetX
        offsetY = circleRadius * 1;
        // Draw assigned tasks circle
        canvas.drawCircle(
          Offset(rects[i].center.dx - offsetX, rects[i].center.dy - offsetY),
          circleRadius,
          Paint()..color = Colors.red, // Assigned tasks color
        );
        TextPainter assignedPainter = TextPainter(
          text: TextSpan(
            text: assignedCount.toString(),
            style: TextStyle(color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        assignedPainter.layout();
        assignedPainter.paint(
          canvas,
          Offset(rects[i].center.dx - assignedPainter.width / 2 - offsetX, rects[i].center.dy - assignedPainter.height / 2 - offsetY),
        );

        // Draw ongoing tasks circle
        offsetY = - circleRadius * 1;
        offsetX = circleRadius * 1.1; // Update offsetX for the next circle
        canvas.drawCircle(
          Offset(rects[i].center.dx - offsetX, rects[i].center.dy - offsetY),
          circleRadius,
          Paint()..color = Colors.yellow, // Ongoing tasks color
        );
        TextPainter ongoingPainter = TextPainter(
          text: TextSpan(
            text: ongoingCount.toString(),
            style: TextStyle(color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        ongoingPainter.layout();
        ongoingPainter.paint(
          canvas,
          Offset(rects[i].center.dx - ongoingPainter.width / 2 - offsetX, rects[i].center.dy - ongoingPainter.height / 2 - offsetY),
        );

        // Draw completed tasks circle
        offsetX = - circleRadius * 1.1;
        offsetY = - circleRadius * 1;
        // offsetX = 0.0; // Reset offsetX
        // offsetY = circleRadius * 1; // Update offsetY for the next row
        canvas.drawCircle(
          Offset(rects[i].center.dx - offsetX, rects[i].center.dy - offsetY),
          circleRadius,
          Paint()..color = Colors.green, // Completed tasks color
        );
        TextPainter completedPainter = TextPainter(
          text: TextSpan(
            text: completedCount.toString(),
            style: TextStyle(color: Colors.black, fontSize: 12.0, fontWeight: FontWeight.bold),
          ),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        completedPainter.layout();
        completedPainter.paint(
          canvas,
          Offset(rects[i].center.dx - completedPainter.width / 2 - offsetX, rects[i].center.dy - completedPainter.height / 2 - offsetY),
        );
      }
    }
    canvas.rotate(pi/2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

Widget _buildLegendItem(String status, Color color) {
  return Row(
    children: [
      Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
        ),
      ),
      SizedBox(width: 8),
      Text(
        status,
        style: TextStyle(fontSize: 16),
      ),
    ],
  );
}

// class RectanglePainter extends CustomPainter {
//   final List<Rect> rects;
//   final List<Color> colors;
//   final List<WorkTask> workTasks;
//
//   RectanglePainter(this.rects, this.colors, this.workTasks);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     // Paint rectangles
//     for (int i = 0; i < rects.length; i++) {
//       canvas.drawRect(rects[i], Paint()..color = colors[i]);
//       // Count work tasks within each rectangle
//       int count = countWorkTasksInRectangle(rects[i]);
//       // Display count in the middle of the rectangle
//       TextSpan span = TextSpan(
//         style: TextStyle(color: Colors.black, fontSize: 16),
//         text: count.toString(),
//       );
//       TextPainter tp = TextPainter(
//         text: span,
//         textAlign: TextAlign.center,
//         textDirection: TextDirection.ltr,
//       );
//       tp.layout();
//       tp.paint(canvas, Offset(rects[i].center.dx - tp.width / 2, rects[i].center.dy - tp.height / 2));
//
//     }
//
//     for (var task in workTasks) {
//       canvas.drawCircle(Offset(task.x, task.y), 5, Paint()..color = Colors.red);
//       }
//   }
//
//   int countWorkTasksInRectangle(Rect rectangle) {
//     List<WorkTask> workTasksCheck =[];
//     int count = 0;
//     for (var task in workTasks) {
//       // Check if the task is directly within the rectangle or within the proximity
//       if (rectangle.contains(Offset(task.x, task.y))) {
//       // if (rectangle.contains(Offset(task.x, task.y)) || rectangle == findNearestRectangle){
//         count++;
//         // workTasksCheck.add(task);
//         // if(task)
//       }else if(findNearestRectangle(task) == rectangle){
//         print('inside else block');
//         count++;
//       }
//       // canvas.drawCircle(Offset(task.x, task.y), 5, Paint()..color = Colors.red);
//     }
//
//     return count;
//   }
//
//   Rect findNearestRectangle(WorkTask task) {
//     double minDistance = double.infinity;
//     Rect nearestRect = rects.first;
//     for (var rect in rects) {
//       double distance = calculateDistance(rect.center, Offset(task.x, task.y));
//       if (distance < minDistance) {
//         minDistance = distance;
//         nearestRect = rect;
//       }
//     }
//     print('nearest rectangle $nearestRect');
//     return nearestRect;
//   }
//
//   double calculateDistance(Offset p1, Offset p2) {
//     double dx = p1.dx - p2.dx;
//     double dy = p1.dy - p2.dy;
//     return sqrt(dx * dx + dy * dy);
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }

// ***** code ******

// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/widgets.dart';
//
// import 'entities/objectBoxStore.dart';
// import 'entities/workstation_positions.dart';
// import 'package:zoom_widget/zoom_widget.dart';
//
// class CustomPainterDraggableShow extends StatefulWidget {
//   @override
//   _CustomPainterDraggableShowState createState() => _CustomPainterDraggableShowState();
// }
//
// class _CustomPainterDraggableShowState extends State<CustomPainterDraggableShow> {
//   List<Rect> rects = [];
//   List<Color> colors = [
//     Colors.grey,
//     Colors.purpleAccent,
//     Colors.greenAccent,
//     Colors.yellow,
//     Colors.orange
//   ];
//   int _draggingIndex = -1; // Index of the rectangle being dragged
//   Offset _draggingOffset = Offset.zero; // Offset of the dragging position relative to the rectangle's position
//
//   @override
//   void initState() {
//     super.initState();
//     // Add initial rectangles
//     // rects.add(Rect.fromLTWH(0, 0, 100, 100));
//     // rects.add(Rect.fromLTWH(150, 0, 100, 100));
//     // rects.add(Rect.fromLTWH(0, 150, 100, 100));
//     // rects.add(Rect.fromLTWH(150, 150, 100, 100));
//     // rects.add(Rect.fromLTWH(300, 0, 100, 100));
//
//
//     ObjectBoxStore.initStore().then((_) {
//       fetchData();
//     });
//   }
//
//   @override
//   void dispose(){
//     super.dispose();
//     ObjectBoxStore.closeStore();
//   }
//
//   @override
//   void didChangeDependencies() {
//     print('inside did change');
//     super.didChangeDependencies();
//     // Call fetchData when the dependencies of the widget change,
//     // which means the widget is being displayed or resumed.
//     fetchData();
//   }
//
//   Future<void> fetchData() async{
//     final store = ObjectBoxStore.instance;
//     final box = store.box<WorkStation>();
//
//     // Retrieve and print data from ObjectBox
//     final storedWorkStations = box.getAll();
//
//     // Populate rects list with fetched data
//     setState(() {
//       rects = storedWorkStations.map((ws) => Rect.fromLTWH(ws.left, ws.top, 100, 100)).toList();
//     });
//
//     print("Stored WorkStations:");
//     storedWorkStations.forEach((ws) {
//       print("WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
//     });
//
//     ObjectBoxStore.closeStore();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Drag and Drop'),
//         // actions: [
//         //   IconButton(
//         //     icon: Icon(Icons.edit),
//         //     onPressed: (){Navigator.pushNamed(context, '/dragAndDropEdit');},
//         //   ),
//         // ],
//       ),
//       body: InteractiveViewer(
//           panEnabled: false, // Set it to false to prevent panning.
//           boundaryMargin: EdgeInsets.all(80),
//           minScale: 0.1,
//           maxScale: 10,// Enable scrolling within the zoomable area
//         child: Container(
//           height: MediaQuery.of(context).size.height -
//               AppBar().preferredSize.height -
//               MediaQuery.of(context).padding.top,
//           width: MediaQuery.of(context).size.width,
//           child: Stack(
//             children: [
//               // Background Image
//               Positioned.fill(
//                 child: Image.asset(
//                   'assets/images/ship.png', // Replace this with your image asset
//                   fit: BoxFit.cover,
//                 ),
//               ),
//               // Custom Paint with draggable rectangles
//               Container(
//                 child: CustomPaint(
//                   painter: RectanglePainter(rects, colors),
//                   child: Container(),
//                 ),
//               ),
//             ],
//           ),
//         )
//       ),
//       // floatingActionButton: FloatingActionButton(
//       //   onPressed: () {
//       //     Navigator.pushNamed(context, '/dragAndDropEdit');
//       //   },
//       //   foregroundColor: Colors.white,
//       //   backgroundColor: Colors.blue,
//       //   splashColor: Colors.white,
//       //   // shape: customizations[index].$3,
//       //   child: const Icon(Icons.edit),
//       // ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
//     );
//   }
// }
//
// class RectanglePainter extends CustomPainter {
//   final List<Rect> rects;
//   final List<Color> colors;
//
//   RectanglePainter(this.rects, this.colors);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     for (int i = 0; i < rects.length; i++) {
//       canvas.drawRect(rects[i], Paint()..color = colors[i]);
//     }
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
