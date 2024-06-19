import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'package:zoom_widget/zoom_widget.dart';

class SelectLegends extends StatefulWidget {
  @override
  _SelectLegendsState createState() => _SelectLegendsState();
}

class WorkTask {
  String status;
  int workStaId;

  WorkTask(this.status, this.workStaId);
}

class _SelectLegendsState extends State<SelectLegends> with WidgetsBindingObserver{
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;

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
  List<bool> tickedStatuses = [true, true, true];

  @override
  void initState() {
    super.initState();
    initializeWorkTasks();
    ObjectBoxStore.initStore().then((_) {
      fetchData();
    });

    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
  }

  @override
  void dispose(){
    super.dispose();
    ObjectBoxStore.closeStore();
    WidgetsBinding.instance?.removeObserver(this);
  }

  @override
  void didChangeDependencies() {
    print('inside did change');
    super.didChangeDependencies();
    // Call fetchData when the dependencies of the widget change,
    // which means the widget is being displayed or resumed.
    // fetchData();
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
  }

  getSizeAndPosition() {
    final RenderBox? _imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (_imageBox != null) {
      imageSize = _imageBox.size;
      imagePosition = _imageBox.localToGlobal(Offset.zero);
      setState(() {
        fetchData();
      });
    }
  }

  Future<void> fetchData() async{
    print('inside fetch data ---- image size ${imageSize}');
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
      rects = storedWorkStations.map((ws) {
        double centerX = ws.left * imageSize.width;
        double centerY = ws.top * imageSize.height;
        return Rect.fromCenter(center: Offset(centerX, centerY), width: height, height: height);
      }).toList();
    });

    print("Stored WorkStations:");
    storedWorkStations.forEach((ws) {
      print("WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
    });

    // ObjectBoxStore.closeStore();
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
        title: Text('Critical Path Use Cases',
        style: TextStyle(
          // fontWeight: FontWeight.bold,
        ),
        ),
        // backgroundColor: Colors.blueGrey[50],
      ),
      body: Zoom(
          backgroundColor: Colors.white,
          maxZoomWidth: MediaQuery.of(context).size.width, // Specify the width of the zoomable area
          maxZoomHeight: MediaQuery.of(context).size.height -
              AppBar().preferredSize.height -
              MediaQuery.of(context).padding.top, // Specify the height of the zoomable area
          maxScale: 4.0,
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
            alignment: Alignment.center,
            child: Stack(
              children: [
                // Background Image
                Center(
                  child: AspectRatio(
                    key: _imageKey,
                    aspectRatio: 147/400,
                    child:Stack(
                      children: [
                        Image.asset(
                          'assets/images/ship5.jpg', // Replace this with your image asset
                          fit: BoxFit.contain,
                        ),
                        Container(
                          child: CustomPaint(
                            painter: RectanglePainter(rects, colors,workTasks,_maximumZoomReached,tickedStatuses,context),
                            child: Container(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 35, // Adjust this value to position the legend vertically
                  left:  MediaQuery.of(context).size.width * 0.03, // Adjust this value to position the legend horizontally
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LegendItem(
                        status: 'Critical Path Mtrl',
                        color: Colors.red,
                        onChanged: (value) {
                          setState(() {
                            tickedStatuses[0] = value;
                          });
                      },
                      ),
                      LegendItem(
                        status: 'Labor capacity',
                        color: Colors.yellow,
                        onChanged: (value) {
                          setState(() {
                            tickedStatuses[1] = value;
                          });
                        },
                      ),
                      LegendItem(
                        status: 'Safety issues',
                        color: Colors.green,
                        onChanged: (value) {
                          setState(() {
                            tickedStatuses[2] = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // )
          )
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }
}



class RectanglePainter extends CustomPainter {
  final List<Rect> rects;
  final List<Color> colors;
  final List<WorkTask> workTasks;
  final bool maximumZoomReached;
  final BuildContext context;
  final List<bool> tickedStatuses;

  RectanglePainter(this.rects, this.colors, this.workTasks, this.maximumZoomReached, this.tickedStatuses,this.context);

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
        // TextPainter painter = TextPainter(
        //   text: TextSpan(
        //     text: 'Assigned: $assignedCount\nOngoing: $ongoingCount\nCompleted: $completedCount',
        //     style: TextStyle(color: Colors.white, fontSize: 11.0),
        //   ),
        //   textAlign: TextAlign.center,
        //   textDirection: TextDirection.ltr,
        // );
        String assignedLabel = tickedStatuses[0] ? 'Critical Path Mtrl: $assignedCount\n\n' : '';
        String ongoingLabel = tickedStatuses[1] ? 'Labor capacity: $ongoingCount\n\n' : '';
        String completedLabel = tickedStatuses[2] ? 'Safety issues: $completedCount\n\n' : '';

        TextPainter painter = TextPainter(
          text: TextSpan(
            text: '$assignedLabel$ongoingLabel$completedLabel',
            style: TextStyle(color: Colors.white, fontSize: 6.0),
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

        if(tickedStatuses[0]){
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
        }

        if(tickedStatuses[1]){
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
        }

        if(tickedStatuses[2]){
          // Draw completed tasks circle
          offsetX = - circleRadius * 1.1;
          offsetY = - circleRadius * 1;
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
    }
    canvas.rotate(pi/2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

class LegendItem extends StatefulWidget {
  final String status;
  final Color color;
  final Function(bool) onChanged;

  const LegendItem({
    required this.status,
    required this.color,
    required this.onChanged,
    Key? key,
  }) : super(key: key);

  @override
  _LegendItemState createState() => _LegendItemState();
}

class _LegendItemState extends State<LegendItem> {
  bool value = true; // Checkbox is ticked by default

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 190,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Container(
          //   width: 20,
          //   height: 20,
          //   decoration: BoxDecoration(
          //     color: widget.color,
          //     shape: BoxShape.circle,
          //   ),
          // ),
          // SizedBox(width: 8),
          Text(
            widget.status,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Transform.scale(
            scale: 1.5, // Adjust the scale factor as needed
            child: Checkbox(
              shape: const CircleBorder(),
              value: value,
              activeColor: widget.color,
              onChanged: (newValue) {
                setState(() {
                  value = newValue ?? false;
                });
                widget.onChanged(value);
              },
            ),
          )
        ],
      ),
    );
  }
}




// import 'dart:async';
// import 'dart:math';
// import 'package:flutter/material.dart';
// import 'package:zoom_widget/zoom_widget.dart';
//
// import 'entities/workstation_positions.dart';
//
// class SelectLegends extends StatefulWidget {
//   @override
//   _SelectLegendsState createState() => _SelectLegendsState();
// }
//
// class WorkTask {
//   String status;
//   int workStaId;
//
//   WorkTask(this.status, this.workStaId);
// }
//
// class _SelectLegendsState extends State<SelectLegends> with WidgetsBindingObserver {
//   final GlobalKey _imageKey = GlobalKey();
//   late Size imageSize = Size.zero;
//   late Offset imagePosition = Offset.zero;
//
//   List<Rect> rects = [];
//   List<Color> colors = [
//     Colors.blue,
//     Colors.purpleAccent,
//     Colors.tealAccent,
//     Colors.brown,
//     Colors.orange
//   ];
//   List<WorkTask> workTasks = [];
//   int _draggingIndex = -1; // Index of the rectangle being dragged
//   Offset _draggingOffset = Offset.zero; // Offset of the dragging position relative to the rectangle's position
//   List<String> legendList = ["Assigned","Ongoing", "Completed"];
//   List<bool> tickedStatuses = [true, true, true]; // Initially all statuses are ticked
//
//   @override
//   void initState() {
//     super.initState();
//     initializeWorkTasks();
//     WidgetsBinding.instance?.addObserver(this);
//     WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     WidgetsBinding.instance?.removeObserver(this);
//   }
//
//   @override
//   void didChangeDependencies() {
//     super.didChangeDependencies();
//     WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
//   }
//
//   getSizeAndPosition() {
//     final RenderBox? _imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
//     if (_imageBox != null) {
//       imageSize = _imageBox.size;
//       imagePosition = _imageBox.localToGlobal(Offset.zero);
//       setState(() {
//         fetchData();
//       });
//     }
//   }
//
//   Future<void> fetchData() async {
//     final storedWorkStations = <WorkStation>[]; // Fetch your data here
//     setState(() {
//       late var height;
//       var width;
//       if (MediaQuery.of(context).size.width > MediaQuery.of(context).size.height) {
//         height = MediaQuery.of(context).size.width * 0.05;
//       } else {
//         height = MediaQuery.of(context).size.height * 0.05;
//       }
//       rects = storedWorkStations.map((ws) {
//         double centerX = ws.left * imageSize.width;
//         double centerY = ws.top * imageSize.height;
//         return Rect.fromCenter(center: Offset(centerX, centerY), width: height, height: height);
//       }).toList();
//     });
//   }
//
//   void initializeWorkTasks() {
//     workTasks = [
//       WorkTask('Assigned', 1),
//       WorkTask('Assigned', 2),
//       WorkTask('Assigned', 3),
//       WorkTask('Assigned', 5),
//       WorkTask('Ongoing', 1),
//       WorkTask('Ongoing', 1),
//       WorkTask('Ongoing', 5),
//       WorkTask('Ongoing', 2),
//       WorkTask('Completed', 5),
//       WorkTask('Completed', 4),
//     ];
//   }
//
//   bool _maximumZoomReached = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Select Legend Items'),
//       ),
//       body: Zoom(
//         backgroundColor: Colors.white,
//         maxZoomWidth: MediaQuery.of(context).size.width, // Specify the width of the zoomable area
//         maxZoomHeight: MediaQuery.of(context).size.height -
//             AppBar().preferredSize.height -
//             MediaQuery.of(context).padding.top, // Specify the height of the zoomable area
//         maxScale: 3.0,
//         enableScroll: true,
//         onScaleUpdate: (scale, zoom) {
//           if (scale > 1.0) {
//             setState(() {
//               _maximumZoomReached = true;
//             });
//           } else {
//             setState(() {
//               _maximumZoomReached = false;
//             });
//           }
//         },
//         child: Container(
//           alignment: Alignment.center,
//           child: Stack(
//             children: [
//               // Background Image
//               Center(
//                 child: AspectRatio(
//                   key: _imageKey,
//                   aspectRatio: 147 / 400,
//                   child: Stack(
//                     children: [
//                       Image.asset(
//                         'assets/images/ship5.jpg', // Replace this with your image asset
//                         fit: BoxFit.contain,
//                       ),
//                       Container(
//                         child: CustomPaint(
//                           painter: RectanglePainter(rects, colors, workTasks, tickedStatuses, _maximumZoomReached, context),
//                           child: Container(),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//               Positioned(
//                 top: 16, // Adjust this value to position the legend vertically
//                 left: 2, // Adjust this value to position the legend horizontally
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     LegendItem(
//                       status: 'Assigned',
//                       color: Colors.red,
//                       onChanged: (value) {
//                         setState(() {
//                           tickedStatuses[0] = value;
//                         });
//                       },
//                     ),
//                     LegendItem(
//                       status: 'Ongoing',
//                       color: Colors.yellow,
//                       onChanged: (value) {
//                         setState(() {
//                           tickedStatuses[1] = value;
//                         });
//                       },
//                     ),
//                     LegendItem(
//                       status: 'Completed',
//                       color: Colors.green,
//                       onChanged: (value) {
//                         setState(() {
//                           tickedStatuses[2] = value;
//                         });
//                       },
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
//     );
//   }
// }
//
// class RectanglePainter extends CustomPainter {
//   final List<Rect> rects;
//   final List<Color> colors;
//   final List<WorkTask> workTasks;
//   final List<bool> tickedStatuses;
//   final bool maximumZoomReached;
//   final BuildContext context;
//
//   RectanglePainter(this.rects, this.colors, this.workTasks, this.tickedStatuses, this.maximumZoomReached, this.context);
//
//   @override
//   void paint(Canvas canvas, Size size) {
//     for (int i = 0; i < rects.length; i++) {
//       if (maximumZoomReached) {
//         // Initialize counters for different task statuses
//         int assignedCount = 0;
//         int ongoingCount = 0;
//         int completedCount = 0;
//
//         // Count tasks with different statuses for the current rectangle
//         for (var task in workTasks) {
//           if (task.workStaId == i + 1) {
//             if (tickedStatuses[0] && task.status == 'Assigned') {
//               assignedCount++;
//             }
//             if (tickedStatuses[1] && task.status == 'Ongoing') {
//               ongoingCount++;
//             }
//             if (tickedStatuses[2] && task.status == 'Completed') {
//               completedCount++;
//             }
//           }
//         }
//
//         // Draw text showing the count of work tasks with different statuses in the middle of the rectangle
//         TextPainter painter = TextPainter(
//           text: TextSpan(
//             text: 'Assigned: $assignedCount\nOngoing: $ongoingCount\nCompleted: $completedCount',
//             style: TextStyle(color: Colors.white, fontSize: 11.0),
//           ),
//           textAlign: TextAlign.center,
//           textDirection: TextDirection.ltr,
//         );
//         painter.layout();
//         painter.paint(
//           canvas,
//           Offset(rects[i].center.dx - painter.width / 2, rects[i].center.dy - painter.height / 2),
//         );
//       } else {
//         // Other existing code...
//       }
//     }
//   }
//
//   @override
//   bool shouldRepaint(CustomPainter oldDelegate) => true;
// }
//
// class LegendItem extends StatefulWidget {
//   final String status;
//   final Color color;
//   final Function(bool) onChanged;
//
//   const LegendItem({
//     required this.status,
//     required this.color,
//     required this.onChanged,
//     Key? key,
//   }) : super(key: key);
//
//   @override
//   _LegendItemState createState() => _LegendItemState();
// }
//
// class _LegendItemState extends State<LegendItem> {
//   bool value = true; // Checkbox is ticked by default
//
//   @override
//   Widget build(BuildContext context) {
//     return Row(
//       children: [
//         Container(
//           width: 20,
//           height: 20,
//           decoration: BoxDecoration(
//             color: widget.color,
//             shape: BoxShape.circle,
//           ),
//         ),
//         SizedBox(width: 8),
//         Text(
//           widget.status,
//           style: TextStyle(fontSize: 16),
//         ),
//         Checkbox(
//           value: value,
//           onChanged: (newValue) {
//             setState(() {
//               value = newValue ?? false;
//             });
//             widget.onChanged(value);
//           },
//         ),
//       ],
//     );
//   }
// }





