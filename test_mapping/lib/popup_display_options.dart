import 'dart:math';
import 'dart:ui';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_mapping/constants.dart';

import 'entities/objectBoxStore.dart';
import 'entities/workstation_positions.dart';
import 'package:url_launcher/url_launcher.dart';

class PopupDisplayOptions extends StatefulWidget {
  @override
  _PopupDisplayOptionsState createState() => _PopupDisplayOptionsState();
}

class WorkTask {
  String status;
  int workStaId;
  int WoNo;
  String description;
  String startDate;
  String priority;


  WorkTask(this.status, this.workStaId, this.WoNo, this.description, this.startDate, this.priority);
}

class _PopupDisplayOptionsState extends State<PopupDisplayOptions> with WidgetsBindingObserver{
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;
  final Uri _url = Uri.parse("https://ifscloud.tsunamit.com/main/ifsapplications/web/page/WorkTask/Form;%24filter=TaskSeq%20eq%2044");


  List<Rect> rects = [];
  List<Color> colors = [
    Colors.blue,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.brown,
    Colors.orange
  ];
  List<WorkTask> workTasks = [];
  List<bool> tickedStatuses = [true, true, true];
  String selectedFilter = 'Status';

  Map<String, List<LegendItemData>> legendItems = {
    'Status': [
      LegendItemData('Critical Path Mtrl', Colors.red),
      LegendItemData('Labor Capacity', Colors.yellow),
      LegendItemData('Safety Issues', Colors.green),
    ],
    'Date': [
      LegendItemData('High Priority', Colors.red),
      LegendItemData('Low Priority', Colors.green),
    ],
  };

  @override
  void initState() {
    super.initState();
    initializeWorkTasks();
    ObjectBoxStore.initStore().then((_) {
      checkAndInsertInitialData().then((_) {
        fetchData();
      });
    });

    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());
  }

  Future<void> checkAndInsertInitialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      // Insert your initial data into ObjectBox here
      final store = ObjectBoxStore.instance;
      final box = store.box<WorkStation>();

      // Define your initial workstations
      List<WorkStation> initialWorkStations = [
        WorkStation(workStationId: 1, left: 0.1, top: 0.1),
        WorkStation(workStationId: 2, left: 0.1, top: 0.2),
        WorkStation(workStationId: 3, left: 0.4, top: 0.3),
        WorkStation(workStationId: 4, left: 0.1, top: 0.6),
        WorkStation(workStationId: 5, left: 0.2, top: 0.1),
      ];

      await box.putMany(initialWorkStations);

      // Set 'isFirstRun' to false so this block won't execute again
      prefs.setBool('isFirstRun', false);
    }
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
      WorkTask('Assigned', 1, 1001, 'Task 1 Description', '2024-01-01','High'),
      WorkTask('Assigned', 2, 1002, 'Task 2 Description', '2024-01-02','Low'),
      WorkTask('Assigned', 3, 1003, 'Task 3 Description', '2024-01-03','High'),
      WorkTask('Assigned', 5, 1004, 'Task 4 Description', '2024-01-04','Low'),
      WorkTask('Ongoing', 1, 1005, 'Task 5 Description', '2024-01-05','High'),
      WorkTask('Ongoing', 1, 1006, 'Task 6 Description', '2024-01-06','Low'),
      WorkTask('Ongoing', 5, 1007, 'Task 7 Description', '2024-01-07','High'),
      WorkTask('Ongoing', 2, 1008, 'Task 8 Description', '2024-01-08','Low'),
      WorkTask('Completed', 5, 1009, 'Task 9 Description', '2024-01-09','Low'),
      WorkTask('Completed', 4, 1010, 'Task 10 Description', '2024-01-10','Low'),
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
                              painter: selectedFilter == 'Status'
                                  ? RectanglePainter(
                                rects,
                                colors,
                                workTasks,
                                _maximumZoomReached,
                                tickedStatuses,
                                context,
                              )
                                  : RectanglePainterDate(
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
                top: 25,
                left: MediaQuery.of(context).size.width * 0.03,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DropdownButton<String>(
                      value: selectedFilter,
                      items: <String>['Status', 'Date'].map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        setState(() {
                          selectedFilter = newValue!;
                        });
                      },
                      style: TextStyle(color: Colors.blueAccent, fontSize: 16),
                      icon: Icon(Icons.arrow_drop_down, color: Colors.blueAccent),
                      dropdownColor: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      underline: Container(
                        height: 2,
                        color: Colors.blueAccent,
                      ),
                    ),
                    ...legendItems[selectedFilter]!.map((item) => LegendItem(
                      status: item.status,
                      color: item.color,
                      onChanged: (value) {
                        setState(() {
                          tickedStatuses[legendItems[selectedFilter]!.indexOf(item)] = value;
                        });
                      },
                    )).toList(),
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
        if(selectedFilter == 'Status'){
          showPopup(context, i);
          return;
        }else if(selectedFilter == 'Date'){
          showPopupDate(context, i);
          return;
        }

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
              this.setState(() {});
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

  void showPopupDate(BuildContext context, int rectIndex) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double popupWidth = screenWidth * 0.6;
    final double popupHeight = screenWidth * 1;
    int workStationId = rectIndex + 1;

    List<WorkTask> getFilteredTasks(String status) {
      return workTasks
          .where((task) =>
      task.priority == status && task.workStaId == rectIndex + 1)
          .toList();
    }

    List<WorkTask> highPriorityTasks = getFilteredTasks('High');
    List<WorkTask> lowPriorityTasks = getFilteredTasks('Low');

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateTaskStatus(WorkTask task, String newStatus) {
              setState(() {
                if (task.priority != newStatus) {
                  if (task.priority == 'High') {
                    highPriorityTasks.remove(task);
                  } else if (task.priority == 'Low') {
                    lowPriorityTasks.remove(task);
                  }
                  task.priority = newStatus;
                  if (newStatus == 'High') {
                    highPriorityTasks.add(task);
                  } else if (newStatus == 'Low') {
                    lowPriorityTasks.add(task);
                  }
                }
              });
              this.setState(() {});
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
                      height: popupHeight / 11,
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
                      height: popupHeight / 3,
                      child: Column(
                        children: [
                          Text(
                            'High Priority',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: highPriorityTasks.isNotEmpty
                                ? Swiper(
                              itemCount: highPriorityTasks.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                WorkTask task = highPriorityTasks[index];
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
                                        Text('Status: ${task.status}'),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceEvenly,
                                          children: [
                                            buildStyledButton(
                                              label: 'Low Priority',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'Low');
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
                      height: popupHeight / 3,
                      child: Column(
                        children: [
                          Text(
                            'Low Priority',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: lowPriorityTasks.isNotEmpty
                                ? Swiper(
                              itemCount: lowPriorityTasks.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                WorkTask task = lowPriorityTasks[index];
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
                                        Text('Status: ${task.status}'),
                                        SizedBox(
                                          height: 10,
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment
                                              .spaceEvenly,
                                          children: [
                                            buildStyledButton(
                                              label: 'High Priority',
                                              icon: Icons.check_circle,
                                              onPressed: () {
                                                updateTaskStatus(
                                                    task, 'High');
                                              },
                                              color: AppColors.red,
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

      // Add GestureDetector to handle tap events on rectangles
      // GestureDetector(
      //   onTap: () {
      //     // Show popup when a rectangle is tapped
      //     print('hello');
      //     showPopup(context);
      //   },
      //   child: Container(
      //     width: rects[i].width,
      //     height: rects[i].height,
      //     // You can add other properties to customize the rectangles
      //   ),
      // );

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

  static bool isTapInsideRect(Offset tapPosition, Rect rect) {
    return rect.contains(tapPosition);
  }
}


class RectanglePainterDate extends CustomPainter {
  final List<Rect> rects;
  final List<Color> colors;
  final List<WorkTask> workTasks;
  final bool maximumZoomReached;
  final BuildContext context;
  final List<bool> tickedStatuses;

  RectanglePainterDate(this.rects, this.colors, this.workTasks, this.maximumZoomReached, this.tickedStatuses,this.context);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < rects.length; i++) {
      canvas.drawRect(rects[i], Paint()..color = colors[i]);

      if (maximumZoomReached) {
        // Initialize counters for different task statuses
        int highCount = 0;
        int mediumCount = 0;
        int lowCount = 0;

        // Count tasks with different statuses for the current rectangle
        for (var task in workTasks) {
          if (task.workStaId == i + 1) {
            if (task.priority == 'High') {
              highCount++;
            } else if (task.priority == 'Medium') {
              mediumCount++;
            } else if (task.priority == 'Low') {
              lowCount++;
            }
          }
        }

        String assignedLabel = tickedStatuses[0] ? 'High: $highCount\n\n' : '';
        String completedLabel = tickedStatuses[2] ? 'Low: $lowCount\n\n' : '';

        TextPainter painter = TextPainter(
          text: TextSpan(
            text: '$assignedLabel$completedLabel',
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
        int highCount = 0;
        int lowCount = 0;

        // Count tasks with different statuses for the current rectangle
        for (var task in workTasks) {
          if (task.workStaId == i + 1) {
            if (task.priority == 'High') {
              highCount++;
            } else if (task.priority == 'Low') {
              lowCount++;
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
          offsetX = circleRadius * 1.1; // Reset offsetX
          offsetY = 0.0;
          // Draw assigned tasks circle
          canvas.drawCircle(
            Offset(rects[i].center.dx - offsetX, rects[i].center.dy - offsetY),
            circleRadius,
            Paint()..color = Colors.red, // Assigned tasks color
          );
          TextPainter assignedPainter = TextPainter(
            text: TextSpan(
              text: highCount.toString(),
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
          // Draw completed tasks circle
          offsetX = - circleRadius * 1.1;
          offsetY = 0.0;
          canvas.drawCircle(
            Offset(rects[i].center.dx - offsetX, rects[i].center.dy - offsetY),
            circleRadius,
            Paint()..color = Colors.green, // Completed tasks color
          );
          TextPainter completedPainter = TextPainter(
            text: TextSpan(
              text: lowCount.toString(),
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

class LegendItemData {
  final String status;
  final Color color;

  LegendItemData(this.status, this.color);
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

