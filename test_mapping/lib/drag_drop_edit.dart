import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zoom_widget/zoom_widget.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';

class CustomPainterDraggableEdit extends StatefulWidget {
  @override
  _CustomPainterDraggableEditState createState() => _CustomPainterDraggableEditState();
}

class _CustomPainterDraggableEditState extends State<CustomPainterDraggableEdit> {
  List<WorkStation> workStations = [];
  List<Color> colors = [
    Colors.blue,
    Colors.purpleAccent,
    Colors.green,
    Colors.yellow,
    Colors.orange
  ];
  int _draggingIndex = -1; // Index of the rectangle being dragged
  Offset _draggingOffset = Offset.zero; // Offset of the dragging position relative to the rectangle's position

  @override
  void initState() {
    super.initState();

    ObjectBoxStore.initStore().then((_) {
      fetchData();
    });
    // workStations.add(WorkStation(workStationId: 1, left: 0, top: 10));
    // workStations.add(WorkStation(workStationId: 2, left: 150, top: 0));
    // workStations.add(WorkStation(workStationId: 3, left: 0, top: 150));
    // workStations.add(WorkStation(workStationId: 4, left: 150, top: 150));
    // workStations.add(WorkStation(workStationId: 5, left: 300, top: 0));
    // Initialize workStations list
    // workStations = [];
  }

  @override
  void dispose(){
    super.dispose();
    ObjectBoxStore.closeStore();
  }


  Future<void> fetchData() async{
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();

    // Retrieve and print data from ObjectBox
    final storedWorkStations = box.getAll();

    print("Stored WorkStations:");
    storedWorkStations.forEach((ws) {
      print("WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");

      // Create WorkStation object and add it to workStations list
      setState(() {
        workStations.add(WorkStation(workStationId: ws.workStationId, left: ws.left, top: ws.top));
      });
    });
    // store.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Workstations'),
        // leading: IconButton(
        //   icon: Icon(Icons.arrow_back), // You can replace this with any back icon you prefer
        //   onPressed: () {
        //     Navigator.pushNamed(context, '/');
        //   },
        // ),
        actions: [
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _savePositions,
          ),
        ],
      ),
      body: Zoom(
        backgroundColor: Colors.white,
        maxZoomWidth: MediaQuery.of(context).size.width, // Specify the width of the zoomable area
        maxZoomHeight: MediaQuery.of(context).size.height -
            AppBar().preferredSize.height -
            MediaQuery.of(context).padding.top, // Specify the height of the zoomable area
        maxScale: 3.0,
        enableScroll: true,
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
              GestureDetector(
                onPanStart: (details) {
                  _checkDragStart(details.localPosition);
                },
                onPanEnd: (details) {
                  _draggingIndex = -1; // Reset dragging index
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
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _savePositions,
      //   // onPressed: () {
      //   //   _savePositions;
      //   //   Navigator.pushNamed(context, '/dragAndDropShow'); // Navigate to another screen
      //   // },
      //   foregroundColor: Colors.white,
      //   backgroundColor: Colors.blue,
      //   // shape: customizations[index].$3,
      //   child: const Text('Save'),
      // ),
      // floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: _savePositions,
            // onPressed: () {
            //   _savePositions;
            //   Navigator.pushNamed(context, '/dragAndDropShow'); // Navigate to another screen
            // },
            foregroundColor: Colors.white,
            backgroundColor: Colors.blue,
            splashColor: Colors.white,
            // shape: customizations[index].$3,
            child: const Text('Save'),
          ),
          SizedBox(height: 16), // Add some space between the buttons
          FloatingActionButton(
            onPressed: () {
              Navigator.pushNamed(context, '/');
            },
            foregroundColor: Colors.white,
            backgroundColor: Colors.red,
            splashColor: Colors.white,
            child: const Text('Back'),
            heroTag: null, // Set heroTag to null to prevent conflicts
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  // Convert WorkStation objects to Rect objects
  List<Rect> _rectsFromWorkStations() {
    return workStations.map((ws) => Rect.fromLTWH(ws.left, ws.top, 75, 75)).toList();
  }

  // Check if the drag starts within any rectangle
  void _checkDragStart(Offset localPosition) {
    for (int i = 0; i < workStations.length; i++) {
      final rect = Rect.fromLTWH(workStations[i].left, workStations[i].top, 100, 100);
      if (rect.contains(localPosition)) {
        setState(() {
          _draggingIndex = i;
          _draggingOffset = localPosition - Offset(rect.left, rect.top);
        });
        break;
      }
    }
  }

  // Handle dragging update
  void _handleDragUpdate(Offset localPosition) {
    if (_draggingIndex != -1) {
      setState(() {
        workStations[_draggingIndex].left = localPosition.dx - _draggingOffset.dx;
        workStations[_draggingIndex].top = localPosition.dy - _draggingOffset.dy;
      });
    }
  }

  // Save positions to ObjectBox
  void _savePositions() async {
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();

    // Clear existing positions
    await box.removeAll();

    // Save updated positions
    await box.putMany(workStations);

    // Retrieve and print data from ObjectBox
    final storedWorkStations = box.getAll();
    print("Stored WorkStations:");
    storedWorkStations.forEach((ws) {
      print("WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
    });
    // store.close();
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