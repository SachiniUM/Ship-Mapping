import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:card_swiper/card_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_mapping/config/user_data.dart';
import 'package:test_mapping/constants.dart';
import 'package:test_mapping/services/error_handling.dart';

import '../common/logout_popup.dart';
import '../entities/objectBoxStore.dart';
import '../entities/workstation_positions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:test_mapping/services/api_service.dart' as apiService;
import 'package:image_picker/image_picker.dart';

class ViewArchitecture extends StatefulWidget {
  ViewArchitecture(
      {super.key,
        required this.logOutFunction,
        required this.refreshTokenFunction});
  final logOutFunction;
  final refreshTokenFunction;

  @override
  _ViewArchitectureState createState() => _ViewArchitectureState();
}

class WorkTask {
  String status;
  int workStaId;
  int WoNo;
  String description;
  String startDate;
  String priority;

  WorkTask(this.status, this.workStaId, this.WoNo, this.description,
      this.startDate, this.priority);
}

// class RectWithId {
//   final Rect rect;
//   final String id;
//
//   RectWithId({required this.rect, required this.id});
// }
Future<File?> getSavedImage() async {
  final prefs = await SharedPreferences.getInstance();
  String? imagePath = prefs.getString("saved_image");
  return imagePath != null ? File(imagePath) : null;
}

class _ViewArchitectureState extends State<ViewArchitecture>
    with WidgetsBindingObserver {
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;
  final Uri _url = Uri.parse(
      "https://ifscloud.tsunamit.com/main/ifsapplications/web/page/WorkTask/Form;%24filter=TaskSeq%20eq%2044");
  var workOrders = [];
  Future<void>? workOrderListFuture;
  // List<RectWithId> rectsWithIds = [];
  List<String> workTypeIds = ['I2S-100', 'I2S-110', 'I2S-120', 'I2S-130'];
  List<WorkStation> storedWorkStations = [];

  List<Rect> rects = [];
  List<Color> colors = [
    Colors.blue,
    Colors.purpleAccent,
    Colors.tealAccent,
    Colors.brown,
    Colors.orange,
    Colors.cyan,
    Colors.pinkAccent,
    Colors.amberAccent,
    Colors.deepPurple,
    Colors.indigo
  ];
  List<WorkTask> workTasks = [];
  List<bool> tickedStatuses = [true, true, true];
  String selectedFilter = 'Status';

  List<dynamic> selectedWorkOrders = [];

  Map<String, List<LegendItemData>> legendItems = {
    'Status': [
      LegendItemData('Requested', Colors.red),
      LegendItemData('Preparation', Colors.yellow),
      LegendItemData('Ongoing', Colors.green),
    ],
    'Priority': [
      LegendItemData('High Priority', Colors.red),
      LegendItemData('Low Priority', Colors.green),
    ],
  };
  File? _selectedImage;
  File? savedImage;

  @override
  void initState() {
    super.initState();
    _loadImage();
    // Future.delayed(Duration.zero, () => _showImageUploadDialog());
    // initializeWorkTasks();
    ObjectBoxStore.initStore().then((_) {
      checkAndInsertInitialData().then((_) {
        fetchData().then((_) {
          // Fetch the work order list after the fetchData has completed
          workOrderListFuture = getWorkOrderList();
        });
      });
    });

    // WidgetsBinding.instance?.addObserver(this);
    // WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());

    // Ensure the function runs after the first frame is rendered
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   getSizeAndPosition();
    // });

    // workOrderListFuture = getWorkOrderList();
  }

  Future<void> _loadImage() async {
    File? image = await getSavedImage();
    setState(() {
      savedImage = image;
    });
  }

  Future<void> getWorkOrderList() async {
    print("from online get work order list");
    final serverCall = await apiService.Methods();
    String apiEndPoint =
        "main/ifsapplications/projection/v1/ActiveWorkOrdersHandling.svc/ActiveSeparateSet"; //api endpoint

    // Generate the filter string dynamically based on the workstation IDs
    String filterString = storedWorkStations
        .map<String>((ws) => "(WorkTypeId eq '${ws.workStationId}')")
        .join(" or ");
    print("filter string : $filterString");

    print("test stored-------");
    storedWorkStations.forEach((ws) {
      print(
          "WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
    });

    Map<String, dynamic>? queryParameters = {
      // "\$filter":"(WorkTypeId eq 'I2S-100') or (WorkTypeId eq 'I2S-110') or (WorkTypeId eq 'I2S-120') or (WorkTypeId eq 'I2S-130')",
      // "\$filter":filterString,
      "\$orderby": "WoNo"
    };

    if (filterString.isNotEmpty) {
      queryParameters["\$filter"] = filterString;

      //call the getWithParameters method to get the work tasks
      var response = await serverCall.getWithParameters(UserData.accessToken,
          apiEndPoint, queryParameters, widget.refreshTokenFunction);

      List<Map<String, dynamic>> workOrdersOnline = [];
      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        for (var i = 0; i < data["value"].length; i++) {
          workOrdersOnline.add({
            'WoNo': data["value"][i]["WoNo"],
            'ErrDescr': data["value"][i]["ErrDescr"],
            'WorkTypeId': data["value"][i]["WorkTypeId"],
            'Objstate': data["value"][i]["Objstate"],
            'PriorityId': data["value"][i]["PriorityId"],
            'LatestFinish': data["value"][i]["LatestFinish"]
          }); //add the record to the workTasks array as a map
          print("wo no : ${workOrdersOnline[i]}");
          print("count : $i");
        }
      } else if (response.body == 'Token refresh failed') {
        if (context.mounted) {
          showLogoutPopup(context, widget.logOutFunction);
        }
      } else {
        if (context.mounted) {
          HttpErrorHandler.showStatusDialog(
              context, response.statusCode, response.reasonPhrase!);
        }
      }
      setState(() {
        print("work orders : $workOrders");
        workOrders = workOrdersOnline;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          getSizeAndPosition();
        });
      });
    }
  }

  Future<void> checkAndInsertInitialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      // Insert your initial data into ObjectBox here
      final store = ObjectBoxStore.instance;
      final box = store.box<WorkStation>();

      // Define your initial workstations

      // Set 'isFirstRun' to false so this block won't execute again
      prefs.setBool('isFirstRun', false);
    }
  }

  Future<void> _showImageUploadDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: false, // Prevent user from dismissing without action
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload an Image'),
          content: Text('Please select an image before proceeding.'),
          actions: [
            TextButton(
              onPressed: () async {
                await _pickImage();
                if (_selectedImage != null) {
                  Navigator.of(context)
                      .pop(); // Close dialog after picking image
                }
              },
              child: Text('Choose Image'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickImage() async {
    final pickedFile =
    await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  @override
  void dispose() {
    super.dispose();
    // ObjectBoxStore.closeStore();
    WidgetsBinding.instance?.removeObserver(this);
  }

  @override
  void didChangeDependencies() {
    print('inside did change');
    super.didChangeDependencies();
    // Call fetchData when the dependencies of the widget change,
    // which means the widget is being displayed or resumed.
    // fetchData();
    // WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchData().then((_) {
        // Fetch the work order list after the fetchData has completed
        workOrderListFuture = getWorkOrderList();
        // WidgetsBinding.instance.addPostFrameCallback((_) {
        //   getSizeAndPosition();
        // });
        // getSizeAndPosition();
      });
    });
  }

  getSizeAndPosition() {
    print("inside get size and position");
    final RenderBox? _imageBox =
    _imageKey.currentContext?.findRenderObject() as RenderBox?;
    print("image box : $_imageBox");
    if (_imageBox != null) {
      imageSize = _imageBox.size;
      imagePosition = _imageBox.localToGlobal(Offset.zero);
      setState(() {
        // divideAndPlaceRectangles();
        // fetchData();

        late var height;
        var width;
        if (MediaQuery.of(context).size.width >
            MediaQuery.of(context).size.height) {
          height = MediaQuery.of(context).size.width * 0.03;
        } else {
          height = MediaQuery.of(context).size.height * 0.03;
        }
        rects = storedWorkStations.map<Rect>((ws) {
          double centerX = ws.left * imageSize.width;
          double centerY = ws.top * imageSize.height;
          return Rect.fromCenter(
              center: Offset(centerX, centerY), width: height, height: height);
        }).toList();
      });
    }
  }

  void divideAndPlaceRectangles() {
    print('inside fetch data ---- image size ${imageSize}');
    if (imageSize == Size.zero) return;

    double halfWidth = imageSize.width / 2;
    double halfHeight = imageSize.height / 2;

    setState(() {
      print("rects: ${Rect}");
      late var height;
      var width;
      if (MediaQuery.of(context).size.width >
          MediaQuery.of(context).size.height) {
        height = MediaQuery.of(context).size.width * 0.03;
      } else {
        height = MediaQuery.of(context).size.height * 0.03;
      }

      // Define rectangles in the four corners
      rects = [
        // Top left
        Rect.fromCenter(
            center: Offset(halfWidth / 2, halfHeight / 2),
            width: height,
            height: height),
        // Rect.fromLTWH(0.0, 0.0, halfWidth, halfHeight),
        // Top right
        Rect.fromCenter(
            center: Offset((halfWidth + halfWidth / 2), halfHeight / 2),
            width: height,
            height: height),
        // Rect.fromLTWH(halfWidth, 0.0, halfWidth, halfHeight),
        // Bottom left
        Rect.fromCenter(
            center: Offset(halfWidth / 2, (halfHeight + halfHeight / 2)),
            width: height,
            height: height),
        // Rect.fromLTWH(0.0, halfHeight, halfWidth, halfHeight),
        // Bottom right
        // Rect.fromLTWH(halfWidth, halfHeight, halfWidth, halfHeight),
        Rect.fromCenter(
            center: Offset(
                (halfWidth + halfWidth / 2), (halfHeight + halfHeight / 2)),
            width: height,
            height: height),
      ];
    });
  }

  Future<void> fetchData() async {
    print('inside fetch data ---- image size ${imageSize}');
    final store = ObjectBoxStore.instance;
    final box = store.box<WorkStation>();

    // // Retrieve and print data from ObjectBox
    // storedWorkStations = box.getAll();

    // Populate rects list with fetched data
    setState(() {
      // Retrieve and print data from ObjectBox
      storedWorkStations = box.getAll();
      // late var height;
      // var width;
      // if(MediaQuery.of(context).size.width > MediaQuery.of(context).size.height){
      //   height = MediaQuery.of(context).size.width * 0.05;
      // }else{
      //   height = MediaQuery.of(context).size.height * 0.05;
      // }
      // rects = storedWorkStations.map<Rect>((ws) {
      //   double centerX = ws.left * imageSize.width;
      //   double centerY = ws.top * imageSize.height;
      //   return Rect.fromCenter(center: Offset(centerX, centerY), width: height, height: height);
      // }).toList();
    });

    print("Stored WorkStations:");
    storedWorkStations.forEach((ws) {
      print(
          "WorkStation id: ${ws.workStationId}, left: ${ws.left}, top: ${ws.top}");
    });

    // ObjectBoxStore.closeStore();
  }

  void initializeWorkTasks() {
    // Predefined list of work tasks with coordinates and statuses
    workTasks = [
      WorkTask('Assigned', 1, 1001, 'Task 1 Description', '2024-01-01', 'High'),
      WorkTask('Assigned', 2, 1002, 'Task 2 Description', '2024-01-02', 'Low'),
      WorkTask('Assigned', 3, 1003, 'Task 3 Description', '2024-01-03', 'High'),
      WorkTask('Assigned', 5, 1004, 'Task 4 Description', '2024-01-04', 'Low'),
      WorkTask('Ongoing', 1, 1005, 'Task 5 Description', '2024-01-05', 'High'),
      WorkTask('Ongoing', 1, 1006, 'Task 6 Description', '2024-01-06', 'Low'),
      WorkTask('Ongoing', 5, 1007, 'Task 7 Description', '2024-01-07', 'High'),
      WorkTask('Ongoing', 2, 1008, 'Task 8 Description', '2024-01-08', 'Low'),
      WorkTask('Completed', 5, 1009, 'Task 9 Description', '2024-01-09', 'Low'),
      WorkTask(
          'Completed', 4, 1010, 'Task 10 Description', '2024-01-10', 'Low'),
    ];
  }

  bool _maximumZoomReached = false;
  Size _currentImageSize = Size.zero;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Work Orders',
          style: TextStyle(
            // fontWeight: FontWeight.bold,
          ),
        ),
        // backgroundColor: Colors.blueGrey[50],
      ),
      body: FutureBuilder(
          future: workOrderListFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Colors.blue,
                ),
              );
            } else {
              return Row(
                children: [
                  // Main image + rectangles
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: Colors.white,
                      child: Center(
                        child: AspectRatio(
                          key: _imageKey,
                          aspectRatio: 1.2,
                          child: Stack(
                            children: [
                              Center(
                                child: savedImage != null
                                    ? Image.file(savedImage!,
                                    fit: BoxFit.contain)
                                    : Image.asset(
                                    "assets/images/siteStructure.png",
                                    fit: BoxFit.contain),
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
                                      _maximumZoomReached,
                                      tickedStatuses,
                                      workOrders,
                                      context,
                                      storedWorkStations),
                                  child: Container(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Right-side table
                  if (selectedWorkOrders.isNotEmpty)
                    Expanded(
                      flex: 2,
                      child: Container(
                        color: Colors.grey[100],
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Work Orders",
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: Icon(Icons.close, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      selectedWorkOrders.clear();
                                      WidgetsBinding.instance
                                          .addPostFrameCallback((_) {
                                        getSizeAndPosition(); // Recalculate image size after layout changes
                                      });
                                    });
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: SingleChildScrollView(
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text("WoNo")),
                                    DataColumn(label: Text("WorkTypeId")),
                                    DataColumn(label: Text("Status")),
                                  ],
                                  rows: selectedWorkOrders.map((wo) {
                                    // Parse the date safely
                                    DateTime? latestFinish;
                                    try {
                                      latestFinish =
                                          DateTime.parse(wo["LatestFinish"]);
                                    } catch (_) {
                                      latestFinish = null;
                                    }

                                    // Determine cell color
                                    Color statusColor = Colors.grey;
                                    if (latestFinish != null) {
                                      final now = DateTime.now();
                                      final difference =
                                          latestFinish.difference(now).inDays;

                                      if (difference > 10) {
                                        statusColor = Colors.green;
                                      } else if (difference >= 0) {
                                        statusColor = Colors.yellow;
                                      } else {
                                        statusColor = Colors.red;
                                      }
                                    }

                                    return DataRow(cells: [
                                      DataCell(Text(wo["WoNo"].toString())),
                                      DataCell(
                                          Text(wo["WorkTypeId"].toString())),
                                      DataCell(
                                        Container(
                                          width: double.infinity, // force to fill cell
                                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                                          color: latestFinish != null
                                              ? (latestFinish.isAfter(DateTime.now())
                                              ? Colors.green
                                              : (DateTime.now().difference(latestFinish).inDays <= 10
                                              ? Colors.yellow
                                              : Colors.red))
                                              : Colors.grey,
                                          child: Text(
                                            latestFinish != null
                                                ? latestFinish.toLocal().toString().split(' ')[0]
                                                : '',
                                            style: TextStyle(color: Colors.white),
                                          ),
                                        ),
                                      ),
                                    ]);
                                  }).toList(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }
          }),
      floatingActionButtonLocation: FloatingActionButtonLocation.endTop,
    );
  }

  // void handleTap(Offset tapPosition) {
  //   for (int i = 0; i < rects.length; i++) {
  //     if (rects[i].contains(tapPosition)) {
  //       if(selectedFilter == 'Status'){
  //         showPopup(context, i);
  //         return;
  //       }else if(selectedFilter == 'Priority'){
  //         showPopupPriority(context, i);
  //         return;
  //       }
  //
  //     }
  //   }
  // }

  void handleTap(Offset tapPosition) {
    for (int i = 0; i < rects.length; i++) {
      if (rects[i].contains(tapPosition)) {
        String? workstationId = storedWorkStations[i].workStationId;
        print("clicked work station ID : ${workstationId!}");
        print("work orders : " + workOrders.length.toString());
        print("work orders list : " + workOrders.toString());

        setState(() {
          selectedWorkOrders = workOrders
              .where((wo) => wo["WorkTypeId"] == workstationId)
              .toList();
          print(
              "selected work orders : " + selectedWorkOrders.length.toString());
          print("selected work orders : " + selectedWorkOrders.toString());
        });

        WidgetsBinding.instance.addPostFrameCallback((_) {
          getSizeAndPosition(); // Recalculate image size after layout changes
        });
        return; // Exit after finding the match
      }
    }
  }

  Uri createWorkOrderUrl(String woNo) {
    return Uri.parse(
        "https://ifscloud.tsunamit.com/main/ifsapplications/web/page/PrepareWorkOrder/Form;%24filter=WoNo%20eq%20$woNo");
  }

  void showPopup(BuildContext context, int rectIndex) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double popupWidth = screenWidth * 0.6;
    final double popupHeight = screenWidth * 1;

    // int workStationId = rectIndex + 1;

    // List<WorkTask> getFilteredTasks(String status) {
    //   return workTasks
    //       .where((task) =>
    //   task.status == status && task.workStaId == rectIndex + 1)
    //       .toList();
    // }
    // Get the corresponding rectangle by index and extract its ID (workTypeId)
    String? workTypeId = storedWorkStations[rectIndex].workStationId;
    print("work type Id : $workTypeId");

    List<dynamic> getFilteredOrders(List<String> statuses) {
      return workOrders
          .where((order) =>
      statuses.contains(order['Objstate']) &&
          order['WorkTypeId'] == workTypeId)
          .toList();
    }

    // Get counts for each category based on objState
    List<dynamic> requestedWorkOrders =
    getFilteredOrders(['WORKREQUEST', 'OBSERVED']);
    List<dynamic> ongoingWorkOrders =
    getFilteredOrders(['UNDERPREPARATION', 'PREPARED', 'RELEASED']);
    List<dynamic> safetyIssuesTasks =
    getFilteredOrders(['STARTED', 'WORKDONE', 'REPORTED']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            void updateTaskStatus(WorkTask task, String newStatus) {
              setState(() {
                if (task.status != newStatus) {
                  if (task.status == 'Assigned') {
                    requestedWorkOrders.remove(task);
                  } else if (task.status == 'Ongoing') {
                    ongoingWorkOrders.remove(task);
                  } else if (task.status == 'Completed') {
                    safetyIssuesTasks.remove(task);
                  }
                  task.status = newStatus;
                  if (newStatus == 'Ongoing') {
                    ongoingWorkOrders.add(task);
                  } else if (newStatus == 'Completed') {
                    safetyIssuesTasks.add(task);
                  } else {
                    requestedWorkOrders.add(task);
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
                              'Work Station : $workTypeId',
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
                            'Requested Work Orders',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: requestedWorkOrders.isNotEmpty
                                ? Swiper(
                              itemCount: requestedWorkOrders.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                var workOrder =
                                requestedWorkOrders[index];
                                return Card(
                                  color: AppColors.red,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            // Text('WO No: ${workOrder.WoNo.toString()}'),
                                            Text(
                                                'WO No: ${workOrder['WoNo']}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(
                                                    createWorkOrderUrl(
                                                        workOrder['WoNo']
                                                            .toString()));
                                              },
                                              child: Icon(Icons.link,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        // Text(
                                        //     'WO No: ${task.WoNo.toString()}'),
                                        Text(
                                            'Description: ${workOrder['ErrDescr']}'),
                                        Text(
                                            'Object State: ${workOrder['Objstate']}'),
                                        SizedBox(
                                          height: 10,
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
                            'Preperation Work Oders',
                            style: TextStyle(
                                fontSize: 16.0, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                          Expanded(
                            child: ongoingWorkOrders.isNotEmpty
                                ? Swiper(
                              itemCount: ongoingWorkOrders.length,
                              itemBuilder:
                                  (BuildContext context, int index) {
                                var workOrder = ongoingWorkOrders[index];
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
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                'WO No: ${workOrder['WoNo']}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(
                                                    createWorkOrderUrl(
                                                        workOrder['WoNo']
                                                            .toString()));
                                              },
                                              child: Icon(Icons.link,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        Text(
                                            'Description: ${workOrder['ErrDescr']}'),
                                        Text(
                                            'Object State: ${workOrder['Objstate']}'),
                                        SizedBox(
                                          height: 10,
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
                            'Ongoing Work Orders',
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
                                var workOrder = safetyIssuesTasks[index];
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
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                'WO No: ${workOrder['WoNo']}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(
                                                    createWorkOrderUrl(
                                                        workOrder['WoNo']
                                                            .toString()));
                                              },
                                              child: Icon(Icons.link,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        Text(
                                            'Description: ${workOrder['ErrDescr']}'),
                                        Text(
                                            'Object State: ${workOrder['Objstate']}'),
                                        SizedBox(
                                          height: 10,
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

  void showPopupPriority(BuildContext context, int rectIndex) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final double popupWidth = screenWidth * 0.6;
    final double popupHeight = screenWidth * 1;

    // String workTypeId = workTypeIds[rectIndex];
    String? workTypeId = storedWorkStations[rectIndex].workStationId;
    print("work type Id : $workTypeId");

    List<dynamic> getFilteredOrders(List<String> priorityIds) {
      return workOrders
          .where((order) =>
      priorityIds.contains(order['PriorityId']) &&
          order['WorkTypeId'] == workTypeId)
          .toList();
    }

    List<dynamic> highPriorityTasks = getFilteredOrders(['1', '2']);
    List<dynamic> lowPriorityTasks = getFilteredOrders(['3', '4', '5']);

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
                              'Work Station : $workTypeId',
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
                                var workOrder = highPriorityTasks[index];
                                // WorkTask task = highPriorityTasks[index];
                                return Card(
                                  color: AppColors.red,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.center,
                                      mainAxisAlignment:
                                      MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                'WO No: ${workOrder['WoNo']}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(
                                                    createWorkOrderUrl(
                                                        workOrder['WoNo']
                                                            .toString()));
                                              },
                                              child: Icon(Icons.link,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        // Text(
                                        //     'WO No: ${task.WoNo.toString()}'),
                                        Text(
                                            'Description:  ${workOrder['ErrDescr']}'),
                                        Text(
                                            'Priority Level: ${workOrder['PriorityId']}'),
                                        SizedBox(
                                          height: 10,
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
                                var workOrder = lowPriorityTasks[index];
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
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                'WO No: ${workOrder['WoNo']}'),
                                            GestureDetector(
                                              onTap: () {
                                                launchUrl(
                                                    createWorkOrderUrl(
                                                        workOrder['WoNo']
                                                            .toString()));
                                              },
                                              child: Icon(Icons.link,
                                                  color: Colors.black),
                                            ),
                                          ],
                                        ),
                                        Text(
                                            'Description:  ${workOrder['ErrDescr']}'),
                                        Text(
                                            'Priority Level: ${workOrder['PriorityId']}'),
                                        SizedBox(
                                          height: 10,
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
  final bool maximumZoomReached;
  final BuildContext context;
  final List<bool> tickedStatuses;
  final List<dynamic> workOrders;
  final List<WorkStation> storedWorkStations;

  RectanglePainter(
      this.rects,
      this.colors,
      this.maximumZoomReached,
      this.tickedStatuses,
      this.workOrders,
      this.context,
      this.storedWorkStations);

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < rects.length; i++) {
      canvas.drawRect(rects[i], Paint()..color = Colors.lightGreen);

      String? workTypeId = storedWorkStations[i].workStationId;

      int totalWorkCount =
          workOrders.where((wo) => wo['WorkTypeId'] == workTypeId).length;

      // Draw total count in the center of the rectangle
      TextPainter totalCountPainter = TextPainter(
        text: TextSpan(
          text: totalWorkCount.toString(),
          style: TextStyle(
              color: Colors.black, fontSize: 15.0, fontWeight: FontWeight.bold),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      totalCountPainter.layout();
      totalCountPainter.paint(
        canvas,
        Offset(
          rects[i].center.dx - totalCountPainter.width / 2,
          rects[i].center.dy - totalCountPainter.height / 2,
        ),
      );
    }
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
