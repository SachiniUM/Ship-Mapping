import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zoom_widget/zoom_widget.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';

class CustomPainterDraggableEdit extends StatefulWidget {

  CustomPainterDraggableEdit({super.key, required this.logOutFunction, required this.refreshTokenFunction});
  final logOutFunction;
  final refreshTokenFunction;

  @override
  _CustomPainterDraggableEditState createState() =>
      _CustomPainterDraggableEditState();
}

class _CustomPainterDraggableEditState extends State<CustomPainterDraggableEdit> with WidgetsBindingObserver{
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;

  List<WorkStation> workStations = [];
  List<Color> colors = [
    Colors.blue,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.brown,
    Colors.orange
  ];
  int _draggingIndex = -1;
  Offset _draggingOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    ObjectBoxStore.initStore().then((_) {
      fetchData();
    });
    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());

    // workStations.add(WorkStation(workStationId: 1, left: 0.1, top: 0.1));
    // workStations.add(WorkStation(workStationId: 2, left: 0.1, top: 0.1));
    // workStations.add(WorkStation(workStationId: 3, left: 0.4, top: 0.3));
    // workStations.add(WorkStation(workStationId: 4, left: 0.1, top: 0.6));
    // workStations.add(WorkStation(workStationId: 5, left: 0.2, top: 0.1));
  }

  @override
  void dispose() {
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
    final RenderBox? _imageBox =
    _imageKey.currentContext?.findRenderObject() as RenderBox?;
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
      body: Container(
        alignment: Alignment.center,
        child: AspectRatio(
          key: _imageKey,
          aspectRatio: 147/400,
          child: Stack(
            children: [
              Image.asset(
                'assets/images/ship5.jpg',
                fit: BoxFit.contain,
              ),
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
          )
        ),
      ),


      // body: Container(
      //   // alignment: Alignment.center,
      //     child: Stack(
      //       // alignment: Alignment.center,
      //       key: _imageKey,
      //       children: [
      //         AspectRatio(
      //
      //           aspectRatio: 147/400,
      //           child:Image.asset(
      //             'assets/images/ship5.jpg',
      //             fit: BoxFit.contain,
      //           ),
      //         ),
      //         Positioned(
      //             child:GestureDetector(
      //               onPanStart: (details) {
      //                 _checkDragStart(details.localPosition);
      //               },
      //               onPanEnd: (details) {
      //                 _draggingIndex = -1;
      //               },
      //               onPanUpdate: (details) {
      //                 _handleDragUpdate(details.localPosition);
      //               },
      //               child: CustomPaint(
      //                 painter: RectanglePainter(_rectsFromWorkStations(), colors),
      //                 child: Container(),
      //               ),
      //             ),
      //         )
      //
      //       ],
      //     )
      //   ),




      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _savePositions,
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            splashColor: Colors.white,
            child: const Text('Save'),
          ),
          SizedBox(height: 16),
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/homePage');
            },
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            splashColor: Colors.white,
            child: const Text('Back'),
            heroTag: null,
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
        center: Offset(workStations[i].left * imageSize.width,
            workStations[i].top * imageSize.height),
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

  // void _handleDragUpdate(Offset localPosition) {
  //   if (_draggingIndex != -1) {
  //     setState(() {
  //       workStations[_draggingIndex].left =
  //           (localPosition.dx - _draggingOffset.dx) / imageSize.width;
  //       workStations[_draggingIndex].top =
  //           (localPosition.dy - _draggingOffset.dy) / imageSize.height;
  //     });
  //   }
  // }

  void _handleDragUpdate(Offset localPosition) {
    if (_draggingIndex != -1) {
      // Calculate the position relative to the image
      double left = (localPosition.dx - _draggingOffset.dx) / imageSize.width;
      double top = (localPosition.dy - _draggingOffset.dy) / imageSize.height;

      // Check if the dropping position is inside the image
      if (left >= 0 && top >= 0 && left <= 1 && top <= 1) {
        setState(() {
          workStations[_draggingIndex].left = left;
          workStations[_draggingIndex].top = top;
        });
      }
    }
  }

  void _savePositions() async {
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();

    await box.removeAll();
    // workStations.add(WorkStation(workStationId: 1, left: 0.1, top: 0.1));
    // workStations.add(WorkStation(workStationId: 2, left: 0.1, top: 0.2));
    // workStations.add(WorkStation(workStationId: 3, left: 0.4, top: 0.3));
    // workStations.add(WorkStation(workStationId: 4, left: 0.1, top: 0.6));
    // workStations.add(WorkStation(workStationId: 5, left: 0.2, top: 0.1));
    await box.putMany(workStations);
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
