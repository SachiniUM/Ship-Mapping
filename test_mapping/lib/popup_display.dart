import 'dart:math';
import 'dart:ui';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test_mapping/constants.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'package:url_launcher/url_launcher.dart';

class PopupDisplay extends StatefulWidget {
  @override
  _PopupDisplayState createState() => _PopupDisplayState();
}

class WorkTask {
  String status;
  int workStaId;
  int WoNo;
  String description;
  String startDate;


  WorkTask(this.status, this.workStaId, this.WoNo, this.description, this.startDate);
}

class _PopupDisplayState extends State<PopupDisplay> with WidgetsBindingObserver{
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;
  final Uri _url = Uri.parse('https://ifscloud.tsunamit.com/main/ifsapplications/web/page/WorkTasks/List');


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
      WorkTask('Assigned', 1, 1001, 'Task 1 Description', '2024-01-01'),
      WorkTask('Assigned', 2, 1002, 'Task 2 Description', '2024-01-02'),
      WorkTask('Assigned', 3, 1003, 'Task 3 Description', '2024-01-03'),
      WorkTask('Assigned', 5, 1004, 'Task 4 Description', '2024-01-04'),
      WorkTask('Ongoing', 1, 1005, 'Task 5 Description', '2024-01-05'),
      WorkTask('Ongoing', 1, 1006, 'Task 6 Description', '2024-01-06'),
      WorkTask('Ongoing', 5, 1007, 'Task 7 Description', '2024-01-07'),
      WorkTask('Ongoing', 2, 1008, 'Task 8 Description', '2024-01-08'),
      WorkTask('Completed', 5, 1009, 'Task 9 Description', '2024-01-09'),
      WorkTask('Completed', 4, 1010, 'Task 10 Description', '2024-01-10'),
    ];
  }

  bool _maximumZoomReached = false;
  Size _currentImageSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Critical Path Use Cases',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
          ),
        ),
        // backgroundColor: Colors.blueGrey[50],
      ),
      body: Container(
        color: Colors.white,
        width: MediaQuery.of(context).size.width, // Specify the width of the zoomable area
        height: MediaQuery.of(context).size.height -
            AppBar().preferredSize.height -
            MediaQuery.of(context).padding.top, // Specify the height of the zoomable area
        child: Container(
          alignment: Alignment.center,
          child: Stack(
            children: [
              // Background Image
              Center(
                child: Container(
                  alignment: Alignment.center,
                  child: AspectRatio(
                    key: _imageKey,
                    aspectRatio: 147 / 400,
                    child: Stack(
                      children: [
                        Image.asset(
                          'assets/images/ship5.jpg',
                          fit: BoxFit.contain,
                        ),
                        GestureDetector(
                          onTapDown: (details) {
                            Offset tapPosition = details.localPosition;
                            handleTap(tapPosition);
                          },
                          child: CustomPaint(
                            painter: RectanglePainter(
                              rects,
                              colors,
                              workTasks,
                              _maximumZoomReached,
                              tickedStatuses,
                              context,
                            ),
                            child: Container(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 35, // Adjust this value to position the legend vertically
                left: MediaQuery.of(context).size.width * 0.03, // Adjust this value to position the legend horizontally
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
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  void handleTap(Offset tapPosition) {
    for (int i = 0; i < rects.length; i++) {
      if (rects[i].contains(tapPosition)) {
        showPopup(context, i);
        return;
      }
    }
  }


  void showPopup(BuildContext context, int rectIndex) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double popupWidth = screenWidth * 0.6;
    final double popupHeight = screenWidth * 1;
    int workStationId = rectIndex + 1;

    List<WorkTask> getFilteredTasks(String status) {
      return workTasks
          .where((task) =>
      task.status == status && task.workStaId == rectIndex + 1)
          .toList();
    }

    List<WorkTask> criticalPathTasks = getFilteredTasks('Assigned');
    List<WorkTask> laborCapacityTasks = getFilteredTasks('Ongoing');
    List<WorkTask> safetyIssuesTasks = getFilteredTasks('Completed');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateTaskStatus(WorkTask task, String newStatus) {
              setState(() {
                if (task.status != newStatus) {
                  if (task.status == 'Assigned') {
                    criticalPathTasks.remove(task);
                  } else if (task.status == 'Ongoing') {
                    laborCapacityTasks.remove(task);
                  } else if (task.status == 'Completed') {
                    safetyIssuesTasks.remove(task);
                  }
                  task.status = newStatus;
                  if (newStatus == 'Ongoing') {
                    laborCapacityTasks.add(task);
                  } else if (newStatus == 'Completed') {
                    safetyIssuesTasks.add(task);
                  } else {
                    criticalPathTasks.add(task);
                  }
                }
              });
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(10.0)),
              ),
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: popupWidth,
                height: popupHeight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      height: popupHeight / 10,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Text(
                              'Work Station : $workStationId',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20.0,
                                  color: Colors.blue),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 1.5,
                      color: Colors.grey[500],
                    ),
                    Container(
                      height: popupHeight / 4,
                      child: Column(
                        children: [
                          Text(
                            'Critical Path Mtrl',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: criticalPathTasks.isNotEmpty
                                ? Swiper(
                              itemCount: criticalPathTasks.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                WorkTask task = criticalPathTasks[index];
                                return Card(
                                  color: AppColors.red,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('WO No: ${task.WoNo.toString()}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(_url);
                                              },
                                              child: Icon(Icons.link, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        // Text(
                                        //     'WO No: ${task.WoNo.toString()}'),
                                        Text('Description: ${task.description}'),
                                        Text('Start Date: ${task.startDate}'),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceEvenly,
                                          children: [
                                            buildStyledButton(
                                              label: 'Labor',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Ongoing');
                                              },
                                              color: AppColors.yellow,
                                            ),
                                            buildStyledButton(
                                              label: 'Safety',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Completed');
                                              },
                                              color: AppColors.green,
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              control: SwiperControl(),
                              pagination: SwiperPagination(
                                builder: DotSwiperPaginationBuilder(
                                  color: Colors.yellow[400],
                                ),
                              ),
                            )
                                : Center(
                                  child: Text('No tasks'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 1.5,
                      color: Colors.grey[500],
                    ),
                    Container(
                      height: popupHeight / 4,
                      child: Column(
                        children: [
                          Text(
                            'Labor Capacity',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: laborCapacityTasks.isNotEmpty
                                ? Swiper(
                              itemCount: laborCapacityTasks.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                WorkTask task = laborCapacityTasks[index];
                                return Card(
                                  color: AppColors.yellow,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('WO No: ${task.WoNo.toString()}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(_url);
                                              },
                                              child: Icon(Icons.link, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        Text('Description: ${task.description}'),
                                        Text('Start Date: ${task.startDate}'),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceEvenly,
                                          children: [
                                            buildStyledButton(
                                              label: 'Critical',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Assigned');
                                              },
                                              color: AppColors.red,
                                            ),
                                            buildStyledButton(
                                              label: 'Safety',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Completed');
                                              },
                                              color: AppColors.green,
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              control: SwiperControl(),
                              pagination: SwiperPagination(
                                builder: DotSwiperPaginationBuilder(
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                                : Center(
                              child: Text('No tasks'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(
                      thickness: 1.5,
                      color: Colors.grey[500],
                    ),
                    Container(
                      height: popupHeight / 4,
                      child: Column(
                        children: [
                          Text(
                            'Safety Issues',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: safetyIssuesTasks.isNotEmpty
                                ? Swiper(
                              itemCount: safetyIssuesTasks.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                WorkTask task = safetyIssuesTasks[index];
                                return Card(
                                  color: AppColors.green,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('WO No: ${task.WoNo.toString()}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(_url);
                                              },
                                              child: Icon(Icons.link, color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        Text('Description: ${task.description}'),
                                        Text('Start Date: ${task.startDate}'),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceEvenly,
                                          children: [
                                            buildStyledButton(
                                              label: 'Critical',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Assigned');
                                              },
                                              color: AppColors.red,
                                            ),
                                            buildStyledButton(
                                              label: 'Labor',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Ongoing');
                                              },
                                              color: AppColors.yellow,
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height: 10,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              control: SwiperControl(),
                              pagination: SwiperPagination(
                                builder: DotSwiperPaginationBuilder(
                                  color: Colors.grey[400],
                                ),
                              ),
                            )
                                : Center(
                              child: Text('No tasks'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildStyledButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    required Color? color,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: color ?? Colors.black),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
          SizedBox(width: 8), // Add space between text and icon
          CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: Icon(
              icon,
              size: 25,
              color: color,
            ),
          ),
        ],
      ),
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

  static bool isTapInsideRect(Offset tapPosition, Rect rect) {
    return rect.contains(tapPosition);
  }
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

