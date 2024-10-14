import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:test_mapping/services/error_handling.dart';
import 'package:zoom_widget/zoom_widget.dart';

import 'common/logout_popup.dart';
import 'config/user_data.dart';
import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'package:test_mapping/services/api_service.dart' as apiService;

class CustomPainterDraggableEdit extends StatefulWidget {
  CustomPainterDraggableEdit({super.key, required this.logOutFunction, required this.refreshTokenFunction});
  final logOutFunction;
  final refreshTokenFunction;

  @override
  _CustomPainterDraggableEditState createState() => _CustomPainterDraggableEditState();
}

class _CustomPainterDraggableEditState extends State<CustomPainterDraggableEdit> with WidgetsBindingObserver {
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;

  List<WorkStation> workStations = [];
  List<Color> colors = [Colors.blue, Colors.purpleAccent, Colors.tealAccent, Colors.brown, Colors.orange,Colors.deepPurple];
  List<String> selectedWorkStationIds = [];

  int _draggingIndex = -1;
  Offset _draggingOffset = Offset.zero;
  final int maxWorkStations = 6;

  List<String> workStationId = [];
  Future<void>? workStationListFuture;

  @override
  void initState() {
    super.initState();
    ObjectBoxStore.initStore().then((_) {
      fetchData();
    });
    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());

    workStationListFuture = getWorkStationIds();
  }

  @override
  void dispose() {
    super.dispose();
    // ObjectBoxStore.closeStore();
    WidgetsBinding.instance?.removeObserver(this);
  }

  getSizeAndPosition() {
    final RenderBox? _imageBox = _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (_imageBox != null) {
      setState(() {
        imageSize = _imageBox.size;
        imagePosition = _imageBox.localToGlobal(Offset.zero);
        fetchData();
      });
    }
  }

  Future<void> fetchData() async {
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();
    final storedWorkStations = box.getAll();

    setState(() {
      workStations = storedWorkStations;
    });
  }

  void _addWorkStation() {
    if (workStations.length < maxWorkStations) {
      setState(() {
        workStations.add(WorkStation(left: 0.5, top: 0.5, id: 0)); // Default to (0.5, 0.5)
      });
    }
  }

// Function to remove a workstation based on the index
  void _removeWorkStation(int index) {
    setState(() {
      workStations.removeAt(index);
    });
  }

  // Function to check if all workstations have selected IDs
  bool _canSave() {
    for (var ws in workStations) {
      if (ws.workStationId == null || ws.workStationId!.isEmpty) {
        return false; // At least one workstation doesn't have a selected ID
      }
    }
    return true; // All workstations have selected IDs
  }

  Future<void> getWorkStationIds() async {
    print("from online get work order list");
    final serverCall = await apiService.Methods();
    String apiEndPoint =
        "main/ifsapplications/projection/v1/WorkTypesHandling.svc/WorkTypeSet"; //api endpoint

    Map<String, dynamic>? queryParameters = {
      "\$filter":"((startswith(WorkTypeId,'I2S')))",
      // "\$top":"6"
    };

    var response = await serverCall.getWithParameters(
        UserData.accessToken, apiEndPoint, queryParameters,widget.refreshTokenFunction); //call the getWithParameters method to get the work tasks

    List<String> workStationIdsOnline = [];
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      for (var i = 0; i < data["value"].length; i++) {
        workStationIdsOnline.add(data["value"][i]["WorkTypeId"]);
        print("WorkTypeId added: ${data["value"][i]["WorkTypeId"]}"); //add the record to the workTasks array as a map
        print("count : $i");
      }
    }else if(response.body == 'Token refresh failed'){
      if(context.mounted){
        showLogoutPopup(context, widget.logOutFunction);
      }
    }else {
      if(context.mounted){
        HttpErrorHandler.showStatusDialog(context, response.statusCode, response.reasonPhrase!);
      }
    }
    setState(() {
      print("work station ids : $workStationIdsOnline");
      workStationId = workStationIdsOnline;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        getSizeAndPosition();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Workstations'),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePositions,
          ),
        ],
      ),
      body: FutureBuilder(
        future: workStationListFuture,
        builder: (context,snapshot){
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: Colors.blue,
              ),
            );
          }else{
            Set<String> selectedWorkStationIds = workStations
                .where((ws) => ws.workStationId != null)
                .map((ws) => ws.workStationId!)
                .toSet();
            return Stack(
              children: [
                Column(
                  children: [
                    // Add Button to add new workstation
                    // if (workStations.length < maxWorkStations)
                    //   ElevatedButton(
                    //     onPressed: _addWorkStation,
                    //     child: Text('Add Workstation'),
                    //   ),
                    Expanded(
                      child: Container(
                        alignment: Alignment.center,
                        child: AspectRatio(
                          key: _imageKey,
                          aspectRatio: 147 / 400,
                          child: Stack(
                            children: [
                              Image.asset('assets/images/ship5.jpg', fit: BoxFit.contain),
                              GestureDetector(
                                onPanStart: (details) {
                                  _checkDragStart(details.localPosition);
                                },
                                onPanEnd: (details) {
                                  _draggingIndex = -1;
                                },
                                onPanUpdate: (details) {
                                  _handleDragUpdate(details.localPosition);
                                },
                                child: CustomPaint(
                                  painter: RectanglePainter(_rectsFromWorkStations(), colors),
                                  child: Container(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Move Dropdowns to top left outside the image
                Positioned(
                  top: 25,
                  left: 16, // Set some padding from the left edge
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(workStations.length, (index) {

                      // Remove already selected IDs from the available options for the current dropdown
                      // List<String> availableWorkStationIds = workStationId
                      //     .where((id) => !selectedWorkStationIds.contains(id))
                      //     .toList();


                      // Remove already selected IDs from the available options for the current dropdown
                      List<String> availableWorkStationIds = workStationId
                          .where((id) => id == workStations[index].workStationId || !selectedWorkStationIds.contains(id))
                          .toList();
                      return Row(
                        children: [
                          // Text('Workstation ${index + 1}: '),
                          // Rectangle matching the workstation color
                          Container(
                            width: 20, // Adjust width as needed
                            height: 20, // Adjust height as needed
                            color: colors[index], // Use the corresponding color for each workstation
                            margin: EdgeInsets.only(right: 8), // Space between the rectangle and dropdown
                          ),
                          DropdownButton<String>(
                            value: workStations[index].workStationId,
                            items: availableWorkStationIds.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text('$value'),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                if (newValue != null) {
                                  print("new value : $newValue");
                                  print("work station id : ${workStations[index].workStationId}");
                                  // selectedWorkStationIds[index] = newValue;
                                  selectedWorkStationIds.add(newValue);
                                  workStations[index].workStationId = newValue;
                                }
                              });
                            },
                            // hint: Text(workStations[index].workStationId != "" ? workStations[index].workStationId : "select id",),
                            hint: Text('select id'),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: Colors.red), // "X" button
                            onPressed: () {
                              _removeWorkStation(index);
                            },
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ],
            );
          }
        }
      ),


      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (workStations.length < maxWorkStations)
            FloatingActionButton(
              onPressed: _addWorkStation,
              foregroundColor: Colors.white,
              // backgroundColor: Colors.blue,
              backgroundColor: Colors.green,
              splashColor: Colors.white,
              heroTag: null,
              child: const Text('Add'),
            ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: _canSave() ? _savePositions : null,
            foregroundColor: Colors.white,
            // backgroundColor: Colors.blue,
            backgroundColor: _canSave() ? Colors.blue : Colors.grey,
            splashColor: Colors.white,
            child: const Text('Save'),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/homePage');
            },
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            splashColor: Colors.white,
            heroTag: null,
            child: const Text('Back'),
          ),

        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  List<Rect> _rectsFromWorkStations() {
    var height = MediaQuery.of(context).size.shortestSide * 0.08;
    return workStations.map((ws) => Rect.fromCenter(
      center: Offset(ws.left * imageSize.width, ws.top * imageSize.height),
      width: height,
      height: height,
    )).toList();
  }

  void _checkDragStart(Offset localPosition) {
    var height = MediaQuery.of(context).size.shortestSide * 0.08;
    for (int i = 0; i < workStations.length; i++) {
      final rect = Rect.fromCenter(
        center: Offset(workStations[i].left * imageSize.width, workStations[i].top * imageSize.height),
        width: height,
        height: height,
      );
      if (rect.contains(localPosition)) {
        setState(() {
          _draggingIndex = i;
          _draggingOffset = localPosition - Offset(rect.left, rect.top);
        });
        break;
      }
    }
  }

  void _handleDragUpdate(Offset localPosition) {
    if (_draggingIndex != -1) {
      double left = (localPosition.dx - _draggingOffset.dx) / imageSize.width;
      double top = (localPosition.dy - _draggingOffset.dy) / imageSize.height;

      if (left >= 0 && top >= 0 && left <= 1 && top <= 1) {
        setState(() {
          workStations[_draggingIndex].left = left;
          workStations[_draggingIndex].top = top;
        });
      }
    }
  }

  void _savePositions() async {
    if(_canSave()){
      final store = ObjectBoxStore.instance;
      final box = store.box<WorkStation>();

      await box.removeAll();
      await box.putMany(workStations);
    }
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


// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
// import 'package:zoom_widget/zoom_widget.dart';
//
// import 'entities/objectBoxStore.dart';
// import 'entities/workstation_positions.dart';
//
// class CustomPainterDraggableEdit extends StatefulWidget {
//
//   CustomPainterDraggableEdit({super.key, required this.logOutFunction, required this.refreshTokenFunction});
//   final logOutFunction;
//   final refreshTokenFunction;
//
//   @override
//   _CustomPainterDraggableEditState createState() =>
//       _CustomPainterDraggableEditState();
// }
//
// class _CustomPainterDraggableEditState extends State<CustomPainterDraggableEdit> with WidgetsBindingObserver{
//   final GlobalKey _imageKey = GlobalKey();
//   late Size imageSize = Size.zero;
//   late Offset imagePosition = Offset.zero;
//
//   List<WorkStation> workStations = [];
//   List<Color> colors = [
//     Colors.blue,
//     Colors.purpleAccent,
//     Colors.tealAccent,
//     Colors.brown,
//     // Colors.orange
//   ];
//   int _draggingIndex = -1;
//   Offset _draggingOffset = Offset.zero;
//
//   @override
//   void initState() {
//     super.initState();
//
//     ObjectBoxStore.initStore().then((_) {
//       fetchData();
//     });
//     WidgetsBinding.instance?.addObserver(this);
//     WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
//
//     // workStations.add(WorkStation(workStationId: 1, left: 0.1, top: 0.1));
//     // workStations.add(WorkStation(workStationId: 2, left: 0.1, top: 0.1));
//     // workStations.add(WorkStation(workStationId: 3, left: 0.4, top: 0.3));
//     // workStations.add(WorkStation(workStationId: 4, left: 0.1, top: 0.6));
//     // workStations.add(WorkStation(workStationId: 5, left: 0.2, top: 0.1));
//   }
//
//   @override
//   void dispose() {
//     super.dispose();
//     ObjectBoxStore.closeStore();
//     WidgetsBinding.instance?.removeObserver(this);
//   }
//
//   @override
//   void didChangeDependencies() {
//     print('inside did change');
//     super.didChangeDependencies();
//     // Call fetchData when the dependencies of the widget change,
//     // which means the widget is being displayed or resumed.
//     // fetchData();
//     WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
//   }
//
//   getSizeAndPosition() {
//     final RenderBox? _imageBox =
//     _imageKey.currentContext?.findRenderObject() as RenderBox?;
//     if (_imageBox != null) {
//       setState(() {
//         imageSize = _imageBox.size;
//         imagePosition = _imageBox.localToGlobal(Offset.zero);
//         fetchData();
//       });
//     }
//   }
//
//   Future<void> fetchData() async {
//     final store = ObjectBoxStore.instance;
//     final box = store.box<WorkStation>();
//
//     final storedWorkStations = box.getAll();
//
//     setState(() {
//       workStations = storedWorkStations;
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Edit Workstations'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.save),
//             onPressed: _savePositions,
//           ),
//         ],
//       ),
//       body: Container(
//         alignment: Alignment.center,
//         child: AspectRatio(
//           key: _imageKey,
//           aspectRatio: 147/400,
//           child: Stack(
//             children: [
//               Image.asset(
//                 'assets/images/ship5.jpg',
//                 fit: BoxFit.contain,
//               ),
//               GestureDetector(
//                   onPanStart: (details) {
//                     _checkDragStart(details.localPosition);
//                   },
//                   onPanEnd: (details) {
//                     _draggingIndex = -1;
//                   },
//                   onPanUpdate: (details) {
//                     _handleDragUpdate(details.localPosition);
//                   },
//                   child: CustomPaint(
//                     painter: RectanglePainter(_rectsFromWorkStations(), colors),
//                     child: Container(),
//                   ),
//                 ),
//             ],
//           )
//         ),
//       ),
//
//
//       // body: Container(
//       //   // alignment: Alignment.center,
//       //     child: Stack(
//       //       // alignment: Alignment.center,
//       //       key: _imageKey,
//       //       children: [
//       //         AspectRatio(
//       //
//       //           aspectRatio: 147/400,
//       //           child:Image.asset(
//       //             'assets/images/ship5.jpg',
//       //             fit: BoxFit.contain,
//       //           ),
//       //         ),
//       //         Positioned(
//       //             child:GestureDetector(
//       //               onPanStart: (details) {
//       //                 _checkDragStart(details.localPosition);
//       //               },
//       //               onPanEnd: (details) {
//       //                 _draggingIndex = -1;
//       //               },
//       //               onPanUpdate: (details) {
//       //                 _handleDragUpdate(details.localPosition);
//       //               },
//       //               child: CustomPaint(
//       //                 painter: RectanglePainter(_rectsFromWorkStations(), colors),
//       //                 child: Container(),
//       //               ),
//       //             ),
//       //         )
//       //
//       //       ],
//       //     )
//       //   ),
//
//
//
//
//       floatingActionButton: Column(
//         mainAxisAlignment: MainAxisAlignment.end,
//         crossAxisAlignment: CrossAxisAlignment.end,
//         children: [
//           FloatingActionButton(
//             onPressed: _savePositions,
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.blue,
//             splashColor: Colors.white,
//             child: const Text('Save'),
//           ),
//           SizedBox(height: 16),
//           FloatingActionButton(
//             onPressed: () {
//               Navigator.pushNamed(context, '/homePage');
//             },
//             foregroundColor: Colors.white,
//             backgroundColor: Colors.red,
//             splashColor: Colors.white,
//             child: const Text('Back'),
//             heroTag: null,
//           ),
//         ],
//       ),
//       floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
//     );
//   }
//
//   List<Rect> _rectsFromWorkStations() {
//     var height = MediaQuery.of(context).size.shortestSide * 0.08;
//     return workStations.map((ws) => Rect.fromCenter(
//       center: Offset(ws.left * imageSize.width, ws.top * imageSize.height),
//       width: height,
//       height: height,
//     )).toList();
//   }
//
//   void _checkDragStart(Offset localPosition) {
//     var height = MediaQuery.of(context).size.shortestSide * 0.08;
//     for (int i = 0; i < workStations.length; i++) {
//       final rect = Rect.fromCenter(
//         center: Offset(workStations[i].left * imageSize.width,
//             workStations[i].top * imageSize.height),
//         width: height,
//         height: height,
//       );
//       if (rect.contains(localPosition)) {
//         setState(() {
//           _draggingIndex = i;
//           _draggingOffset = localPosition - Offset(rect.left, rect.top);
//         });
//         break;
//       }
//     }
//   }
//
//   // void _handleDragUpdate(Offset localPosition) {
//   //   if (_draggingIndex != -1) {
//   //     setState(() {
//   //       workStations[_draggingIndex].left =
//   //           (localPosition.dx - _draggingOffset.dx) / imageSize.width;
//   //       workStations[_draggingIndex].top =
//   //           (localPosition.dy - _draggingOffset.dy) / imageSize.height;
//   //     });
//   //   }
//   // }
//
//   void _handleDragUpdate(Offset localPosition) {
//     if (_draggingIndex != -1) {
//       // Calculate the position relative to the image
//       double left = (localPosition.dx - _draggingOffset.dx) / imageSize.width;
//       double top = (localPosition.dy - _draggingOffset.dy) / imageSize.height;
//
//       // Check if the dropping position is inside the image
//       if (left >= 0 && top >= 0 && left <= 1 && top <= 1) {
//         setState(() {
//           workStations[_draggingIndex].left = left;
//           workStations[_draggingIndex].top = top;
//         });
//       }
//     }
//   }
//
//   void _savePositions() async {
//     final store = ObjectBoxStore.instance;
//     final box = store.box<WorkStation>();
//
//     await box.removeAll();
//     // workStations.add(WorkStation(workStationId: 1, left: 0.1, top: 0.1));
//     // workStations.add(WorkStation(workStationId: 2, left: 0.1, top: 0.2));
//     // workStations.add(WorkStation(workStationId: 3, left: 0.4, top: 0.3));
//     // workStations.add(WorkStation(workStationId: 4, left: 0.1, top: 0.6));
//     // workStations.add(WorkStation(workStationId: 5, left: 0.2, top: 0.1));
//     await box.putMany(workStations);
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
