import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'package:zoom_widget/zoom_widget.dart';

class WorkTask {
  String status;
  double x;
  double y;

  WorkTask(this.status, this.x, this.y);
}

class ShowWorkTasks extends StatefulWidget {
  @override
  _ShowWorkTasksState createState() => _ShowWorkTasksState();
}

class _ShowWorkTasksState extends State<ShowWorkTasks> {
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
  Offset _draggingOffset = Offset.zero; // Offset of the dragging position relative to the rectangle's position

  @override
  void initState() {
    super.initState();
    initializeWorkTasks();
  }

  void initializeWorkTasks() {
    // Predefined list of work tasks with coordinates and statuses
    workTasks = [
      WorkTask('Assigned', 400.0, 800.0),
      WorkTask('Assigned', 350.0, 90.0),
      WorkTask('Assigned', 360.0,550.0),
      WorkTask('Assigned', 400.0, 600.0),
      WorkTask('Ongoing', 350.0, 1000.0),
      WorkTask('Ongoing', 300.0, 700.0),
      WorkTask('Ongoing', 350.0, 250.0),
      WorkTask('Ongoing', 400.0, 650.0),
      WorkTask('Completed', 400.0, 250.0),
      WorkTask('Completed', 420.0, 900.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Work Tasks List'),
      ),
      body: InteractiveViewer(
          panEnabled: false, // Set it to false to prevent panning.
          boundaryMargin: EdgeInsets.all(80),
          minScale: 0.1,
          maxScale: 10,// Enable scrolling within the zoomable area
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
                // Circles representing work tasks
                for (var task in workTasks)
                  Positioned(
                    left: task.x,
                    top: task.y,
                    child: Container(
                      width: 40, // Adjust according to your preference
                      height: 40, // Adjust according to your preference
                      decoration: BoxDecoration(
                        color: _getColorForStatus(task.status),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          workTasks.indexOf(task).toString(),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
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
            )
          )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}

Color _getColorForStatus(String status) {
  switch (status) {
    case 'Assigned':
      return Colors.red;
    case 'Ongoing':
      return Colors.yellow;
    case 'Completed':
      return Colors.green;
    default:
      return Colors.grey;
  }
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

