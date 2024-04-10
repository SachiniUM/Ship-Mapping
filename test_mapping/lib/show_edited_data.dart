import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'dart:math';
import 'package:zoom_widget/zoom_widget.dart';

class WorkTask {
  String status;
  double x;
  double y;

  WorkTask(this.status, this.x, this.y);
}

class CustomPainterDraggableShow extends StatefulWidget {
  @override
  _CustomPainterDraggableShowState createState() =>
      _CustomPainterDraggableShowState();
}

class _CustomPainterDraggableShowState
    extends State<CustomPainterDraggableShow> {
  List<Rect> rects = [];
  List<Color> colors = [
    Colors.grey,
    Colors.purpleAccent,
    Colors.greenAccent,
    Colors.yellow,
    Colors.orange
  ];
  List<WorkTask> workTasks = []; // List of work tasks
  int _draggingIndex = -1; // Index of the rectangle being dragged
  Offset _draggingOffset = Offset
      .zero; // Offset of the dragging position relative to the rectangle's position

  @override
  void initState() {
    super.initState();
    // Add initial rectangles
    // rects.add(Rect.fromLTWH(0, 0, 50, 50));
    // rects.add(Rect.fromLTWH(150, 0, 50, 50));
    // rects.add(Rect.fromLTWH(0, 150, 50, 50));
    // rects.add(Rect.fromLTWH(150, 150, 50, 50));
    // rects.add(Rect.fromLTWH(300, 0, 50, 50));

    initializeWorkTasks();
    ObjectBoxStore.initStore().then((_) {
      fetchData();
    });
  }

  @override
  void dispose() {
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

  Future<void> fetchData() async {
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();

    // Retrieve and print data from ObjectBox
    final storedWorkStations = box.getAll();

    // Populate rects list with fetched data
    setState(() {
      rects = storedWorkStations
          .map((ws) => Rect.fromLTWH(ws.left, ws.top, 100, 100))
          .toList();
    });

    print("Stored WorkStations:");
    storedWorkStations.forEach((ws) {
      print(
          "WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
    });

    ObjectBoxStore.closeStore();
  }

  void initializeWorkTasks() {
    // Predefined list of work tasks with coordinates and statuses
    workTasks = [
      WorkTask('Assigned', 400.0, 800.0),
      WorkTask('Assigned', 350.0, 90.0),
      WorkTask('Assigned', 360.0, 550.0),
      WorkTask('Assigned', 400.0, 600.0),
      WorkTask('Ongoing', 350.0, 1000.0),
      WorkTask('Ongoing', 300.0, 700.0),
      WorkTask('Ongoing', 350.0, 250.0),
      WorkTask('Ongoing', 400.0, 650.0),
      WorkTask('Completed', 400.0, 250.0),
      WorkTask('Completed', 420.0, 900.0),
    ];
  }

  bool _maximumZoomReached = false;

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
      body: InteractiveViewer(
          panEnabled: false, // Set it to false to prevent panning.
          boundaryMargin: EdgeInsets.all(80),
          minScale: 0.1,
          maxScale: 10, // Enable scrolling within the zoomable area
          onInteractionUpdate: (details) {
            setState(() {
              // Check if the scale is approximately 5
              _maximumZoomReached = details.scale > 1;
              print('_maximumZoomReached $_maximumZoomReached');
              print('details scale ${details.scale}');
            });
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
                    painter: RectanglePainter(
                        rects, colors, workTasks, _maximumZoomReached),
                    child: Container(),
                  ),
                ),
              ],
            ),
          )),
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
}

class RectanglePainter extends CustomPainter {
  final List<Rect> rects;
  final List<Color> colors;
  final List<WorkTask> workTasks;
  final bool maximumZoomReached;

  RectanglePainter(
      this.rects, this.colors, this.workTasks, this.maximumZoomReached);

  @override
  void paint(Canvas canvas, Size size) {
    // Paint rectangles
    for (int i = 0; i < rects.length; i++) {
      canvas.drawRect(rects[i], Paint()..color = colors[i]);

      // Check if scale reached 5
      if (maximumZoomReached) {
        print('***** max zoom in rectangle *****');
        // Count work tasks within each rectangle
        int assignedCount = countWorkTasksInStatus(rects[i], 'Assigned');
        int ongoingCount = countWorkTasksInStatus(rects[i], 'Ongoing');
        int completedCount = countWorkTasksInStatus(rects[i], 'Completed');

        // Display count in the middle of the rectangle
        TextSpan span = TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 16),
          text:
              'Assigned: $assignedCount\nOngoing: $ongoingCount\nCompleted: $completedCount',
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
            canvas,
            Offset(rects[i].center.dx - tp.width / 2,
                rects[i].center.dy - tp.height / 2));
      } else {
        int count = countWorkTasksInRectangle(rects[i]);
        // Display count in the middle of the rectangle
        TextSpan span = TextSpan(
          style: TextStyle(color: Colors.black, fontSize: 16),
          text: count.toString(),
        );
        TextPainter tp = TextPainter(
          text: span,
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
            canvas,
            Offset(rects[i].center.dx - tp.width / 2,
                rects[i].center.dy - tp.height / 2));
      }
    }

    // // Paint work task circles
    // for (var task in workTasks) {
    //   canvas.drawCircle(Offset(task.x, task.y), 5, Paint()..color = Colors.red);
    // }
  }

  int countWorkTasksInStatus(Rect rectangle, String status) {
    int count = 0;
    for (var task in workTasks) {
      if (rectangle.contains(Offset(task.x, task.y)) && task.status == status) {
        count++;
      }else if (findNearestRectangle(task) == rectangle && task.status == status) {
        print('inside else block');
        count++;
      }
    }
    return count;
  }

  int countWorkTasksInRectangle(Rect rectangle) {
    int count = 0;
    for (var task in workTasks) {
      // Check if the task is directly within the rectangle or within the proximity
      if (rectangle.contains(Offset(task.x, task.y))) {
        // if (rectangle.contains(Offset(task.x, task.y)) || rectangle == findNearestRectangle){
        count++;
        // workTasksCheck.add(task);
        // if(task)
      } else if (findNearestRectangle(task) == rectangle) {
        print('inside else block');
        count++;
      }
      // canvas.drawCircle(Offset(task.x, task.y), 5, Paint()..color = Colors.red);
    }

    return count;
  }

  Rect findNearestRectangle(WorkTask task) {
    double minDistance = double.infinity;
    Rect nearestRect = rects.first;
    for (var rect in rects) {
      double distance = calculateDistance(rect.center, Offset(task.x, task.y));
      if (distance < minDistance) {
        minDistance = distance;
        nearestRect = rect;
      }
    }
    print('nearest rectangle $nearestRect');
    return nearestRect;
  }

  double calculateDistance(Offset p1, Offset p2) {
    double dx = p1.dx - p2.dx;
    double dy = p1.dy - p2.dy;
    return sqrt(dx * dx + dy * dy);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
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
