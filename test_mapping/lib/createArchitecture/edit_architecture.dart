import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_mapping/entities/custom_workstations.dart';
import 'package:test_mapping/services/error_handling.dart';
import 'package:zoom_widget/zoom_widget.dart';

import '../common/logout_popup.dart';
import '../config/user_data.dart';
import '../entities/objectBoxStore.dart';
import '../entities/workstation_positions.dart';
import 'package:test_mapping/services/api_service.dart' as apiService;
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

class EditArchitecture extends StatefulWidget {
  EditArchitecture({super.key, required this.logOutFunction, required this.refreshTokenFunction});
  final logOutFunction;
  final refreshTokenFunction;

  @override
  _EditArchitectureState createState() => _EditArchitectureState();
}

Future<File?> getSavedImage() async {
  final prefs = await SharedPreferences.getInstance();
  String? imagePath = prefs.getString("saved_architecture_image");
  return imagePath != null ? File(imagePath) : null;
}

class _EditArchitectureState extends State<EditArchitecture> with WidgetsBindingObserver {
  final GlobalKey _imageKey = GlobalKey();
  late Size imageSize = Size.zero;
  late Offset imagePosition = Offset.zero;

  List<CustomWorkStation> customWorkStations = [];
  List<Color> colors = [Colors.blue, Colors.purpleAccent, Colors.tealAccent, Colors.brown, Colors.orange,  Colors.cyan, Colors.pinkAccent, Colors.amberAccent, Colors.deepPurple, Colors.indigo];
  List<String> selectedWorkStationIds = [];

  int _draggingIndex = -1;
  Offset _draggingOffset = Offset.zero;
  final int maxWorkStations = 10;

  List<String> workStationId = [];
  Future<void>? workStationListFuture;
  File? savedImage;

  //---------------------------------------------------------------------------------//
  final List<String> predefinedImages = [
    "assets/images/architecture/architecture_2.png",
    "assets/images/architecture/architecture_3.png",
    "assets/images/architecture/architecture_4.png",
  ];

  final ImagePicker _picker = ImagePicker();

  Future<void> _selectPredefinedImage(String assetPath) async {
    final byteData = await DefaultAssetBundle.of(context).load(assetPath);
    final file = File('${(await getTemporaryDirectory()).path}/${assetPath.split("/").last}');
    await file.writeAsBytes(byteData.buffer.asUint8List());

    await _saveImagePath(file.path);
    setState(() {
      savedImage = file;
    });
  }

  Future<void> _selectFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final file = File(pickedFile.path);
      await _saveImagePath(file.path);
      setState(() {
        savedImage = file;
      });
    }
  }

  Future<void> _saveImagePath(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("saved_architecture_image", path);
  }

  void _showChangeArchitectureDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Change Architecture"),
        content: SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: predefinedImages.map((path) {
                  return GestureDetector(
                    onTap: () async {
                      Navigator.of(context).pop();
                      await _selectPredefinedImage(path);
                    },
                    child: Image.asset(
                      path,
                      width: 200,
                      height: 200,
                      fit: BoxFit.contain,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await _selectFromGallery();
                },
                icon: const Icon(Icons.photo_library),
                label: const Text("Select from Gallery"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _loadSavedImage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPath = prefs.getString("saved_architecture_image");
    if (savedPath != null && File(savedPath).existsSync()) {
      setState(() {
        savedImage = File(savedPath);
      });
    }
  }

  final List<String> partImages = [
    "assets/images/architecture/part_1.png",
    "assets/images/architecture/part_2.png",
    "assets/images/architecture/part_3.png",
  ];

  final List<String> types = ["warehouse", "workstation", "purchase order", "shop order"];
  final List<String> statuses = ["started", "ongoing", "completed"];

  List<OverlayItem> overlayItems = [];

  void _showAddOverlayPopup() {
    String? selectedImage;
    String name = '';
    String? selectedType;
    String? selectedStatus;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text("Add Work Center"),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    // Image picker options
                    Wrap(
                      spacing: 10,
                      children: partImages.map((path) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedImage = path;
                            });
                          },
                          child: Image.asset(
                            path,
                            width: 100,
                            height: 100,
                            fit: BoxFit.contain,
                            color: selectedImage == path ? Colors.green.withOpacity(0.6) : null,
                            colorBlendMode: selectedImage == path ? BlendMode.color : null,
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          setState(() {
                            selectedImage = pickedFile.path;
                          });
                        }
                      },
                      child: Text("Upload Image"),
                    ),
                    SizedBox(height: 10),

                    // Show selected image
                    if (selectedImage != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: selectedImage!.contains("assets/")
                            ? Image.asset(selectedImage!, height: 120)
                            : Image.file(File(selectedImage!), height: 120),
                      ),

                    SizedBox(height: 10),
                    TextField(
                      decoration: InputDecoration(labelText: "Name"),
                      onChanged: (val) => name = val,
                    ),
                    SizedBox(height: 10),
                    DropdownButton<String>(
                      hint: Text("- Select Category -",style: TextStyle(color: Colors.grey),),
                      value: selectedType,
                      isExpanded: true,
                      items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedType = val!;
                        });
                      },
                    ),
                    DropdownButton<String>(
                      hint: Text("- Select Filter -",style: TextStyle(color: Colors.grey),),
                      value: selectedStatus,
                      isExpanded: true,
                      items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                      onChanged: (val) {
                        setState(() {
                          selectedStatus = val!;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (selectedImage != null) {
                      final newWS = CustomWorkStation(
                        name: name,
                        imagePath: selectedImage!,
                        type: selectedType!,
                        status: selectedStatus!,
                        left: 0.5,
                        top: 0.5,
                      );

                      setState(() {
                        customWorkStations.add(newWS);
                      });

                      await saveUserWorkStations(customWorkStations);
                      await _loadImages(); // <- important!
                    }

                    Navigator.of(context).pop();
                  },
                  child: Text("OK"),
                )
              ],
            );
          },
        );
      },
    );
  }





  Future<void> saveUserWorkStations(List<CustomWorkStation> workstations) async {
    print("custom work stations : " + customWorkStations.toString());
    final store = ObjectBoxStore.instance;
    final box = store.box<CustomWorkStation>();
    await box.putMany(workstations);
  }

  Future<ui.Image> loadImageFromFile(String path) async {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    return frame.image;
  }

  Map<String, ui.Image> _loadedImages = {};

  Future<void> _loadImages() async {
    final Map<String, ui.Image> result = {};
    for (final ws in customWorkStations) {
      try {
        if (ws.imagePath.contains("assets/")) {
          // Load asset image
          final byteData = await rootBundle.load(ws.imagePath);
          final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
          final frame = await codec.getNextFrame();
          result[ws.imagePath] = frame.image;
        } else {
          // Load image from file system
          final file = File(ws.imagePath);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final codec = await ui.instantiateImageCodec(bytes);
            final frame = await codec.getNextFrame();
            result[ws.imagePath] = frame.image;
          } else {
            print("⚠️ File not found: ${ws.imagePath}");
          }
        }
      } catch (e) {
        print("Error loading image for path ${ws.imagePath}: $e");
      }
    }

    setState(() {
      _loadedImages = result;
    });
  }
  //-----------------------------------------------------------------------------//

  @override
  void initState() {
    super.initState();
    _loadSavedImage();
    ObjectBoxStore.initStore().then((_) {
      checkAndInsertInitialData().then((_) {
        fetchData();
      });
    });
    WidgetsBinding.instance?.addObserver(this);
    WidgetsBinding.instance?.addPostFrameCallback((_) => getSizeAndPosition());

    // workStationListFuture = getWorkStationIds();
  }

  Future<void> _loadImage() async {
    File? image = await getSavedImage();
    setState(() {
      savedImage = image;
    });
  }

  Future<void> checkAndInsertInitialData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isFirstRun = prefs.getBool('isFirstRun') ?? true;

    if (isFirstRun) {
      // Insert your initial data into ObjectBox here
      final store = ObjectBoxStore.instance;
      final box = store.box<CustomWorkStation>();

      // Set 'isFirstRun' to false so this block won't execute again
      prefs.setBool('isFirstRun', false);
    }
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
        _loadImages(); // Add this
        getSizeAndPosition();
      });
    });
  }

  Future<void> fetchData() async {
    final store = ObjectBoxStore.instance;
    final box = store.box<CustomWorkStation>();
    final storedWorkStations = box.getAll();

    setState(() {
      customWorkStations = storedWorkStations;
    });
  }

  // void _addWorkStation() {
  //   if (customWorkStations.length < maxWorkStations) {
  //     setState(() {
  //       customWorkStations.add(WorkStation(left: 0.5, top: 0.5, id: 0)); // Default to (0.5, 0.5)
  //     });
  //   }
  // }

// Function to remove a workstation based on the index
  void _removeWorkStation(int index) {
    setState(() {
      customWorkStations.removeAt(index);
    });
  }

  // Function to check if all workstations have selected IDs
  // bool _canSave() {
  //   for (var ws in customWorkStations) {
  //     if (ws.workStationId == null || ws.workStationId!.isEmpty) {
  //       return false; // At least one workstation doesn't have a selected ID
  //     }
  //   }
  //   return true; // All workstations have selected IDs
  // }

  Future<void> getWorkStationIds() async {
    print("from online get work order list");
    final serverCall = await apiService.Methods();
    String apiEndPoint =
        "main/ifsapplications/projection/v1/WorkTypesHandling.svc/WorkTypeSet"; //api endpoint

    // Map<String, dynamic>? queryParameters = {
    //   "\$filter":"((startswith(WorkTypeId,'I2S')))",
    //   // "\$top":"6"
    // };

    var response = await serverCall.get(
        UserData.accessToken, apiEndPoint,widget.refreshTokenFunction);

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

  void _showWorkstationPopup(CustomWorkStation ws) {
    bool isEditing = false;
    final nameController = TextEditingController(text: ws.name);
    String selectedCategory = ws.type;
    String selectedStatus = ws.status;
    String imagePath = ws.imagePath;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text("Work Center Details"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: isEditing
                          ? () async {
                        final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
                        if (picked != null) {
                          setModalState(() {
                            imagePath = picked.path;

                          });
                        }
                      }
                          : null,
                      child: imagePath.isNotEmpty
                          ? (imagePath.startsWith("assets/")
                          ? Image.asset(imagePath, height: 100) // Asset image
                          : Image.file(File(imagePath), height: 100)) // File image
                          : Container(
                        height: 100,
                        color: Colors.grey[300],
                        child: Icon(Icons.image),
                      ),
                    ),
                    SizedBox(height: 12),
                    isEditing
                        ? TextField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: "Name"),
                    )
                        : Text("Name: ${ws.name}"),
                    SizedBox(height: 8),
                    isEditing
                        ? DropdownButton<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      items: types.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setModalState(() => selectedCategory = val!),
                    )
                        : Text("Category: ${ws.type}"),
                    SizedBox(height: 8),
                    isEditing
                        ? DropdownButton<String>(
                      value: selectedStatus,
                      isExpanded: true,
                      items: statuses.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (val) => setModalState(() => selectedStatus = val!),
                    )
                        : Text("Status: ${ws.status}"),
                  ],
                ),
              ),
              actions: [
                if (!isEditing)
                  TextButton(
                    onPressed: () => setModalState(() => isEditing = true),
                    child: Text("Edit"),
                  ),
                if (isEditing)
                  TextButton(
                    onPressed: () {
                      ws.name = nameController.text;
                      ws.type = selectedCategory;
                      ws.status = selectedStatus;
                      ws.imagePath = imagePath;

                      final store = ObjectBoxStore.instance;
                      store.box<CustomWorkStation>().put(ws);

                      setState(() {}); // refresh UI
                      Navigator.pop(context);
                    },
                    child: Text("Save"),
                  ),
                TextButton(
                  onPressed: () {
                    final store = ObjectBoxStore.instance;
                    store.box<CustomWorkStation>().remove(ws.id);
                    setState(() {
                      customWorkStations.removeWhere((w) => w.id == ws.id);
                    });
                    Navigator.pop(context);
                  },
                  child: Text("Delete", style: TextStyle(color: Colors.red)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Close"),
                ),
              ],
            );
          },
        );
      },
    );
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
              // Set<String> selectedWorkStationIds = customWorkStations
              //     .where((ws) => ws.workStationId != null)
              //     .map((ws) => ws.workStationId!)
              //     .toSet();
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
                            aspectRatio: 1.2,
                            child: Stack(
                              children: [
                                // Image.asset('assets/images/ship5.jpg', fit: BoxFit.contain),
                                Center(
                                  child: savedImage != null
                                      ? Image.file(savedImage!, fit: BoxFit.contain)
                                      : Image.asset("assets/images/architecture/architecture_1.png", fit: BoxFit.contain),
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
                                  onDoubleTapDown: (details) {
                                    _handleTap(details.localPosition);
                                  },
                                  child: CustomPaint(
                                    painter: RectanglePainter(_workStationsWithRects(), _loadedImages),
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
                ],
              );
            }
          }
      ),


      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // if (customWorkStations.length < maxWorkStations)
          FloatingActionButton.extended(
            onPressed: _showChangeArchitectureDialog,
            foregroundColor: Colors.white,
            backgroundColor: Colors.green,
            splashColor: Colors.white,
            heroTag: null,
            label: const Text(
              'Change Architecture',
              style: TextStyle(fontSize: 14), // you can adjust font size
            ),
          ),
          SizedBox(height: 16),
            FloatingActionButton(
              onPressed: _showAddOverlayPopup,
              foregroundColor: Colors.white,
              // backgroundColor: Colors.blue,
              backgroundColor: Colors.green,
              splashColor: Colors.white,
              heroTag: null,
              child: const Text('Add'),
            ),
          SizedBox(height: 16),
          // FloatingActionButton(
          //   onPressed: _canSave() ? _savePositions : null,
          //   foregroundColor: Colors.white,
          //   // backgroundColor: Colors.blue,
          //   backgroundColor: _canSave() ? Colors.blue : Colors.grey,
          //   splashColor: Colors.white,
          //   child: const Text('Save'),
          // ),
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

  List<WorkStationWithRect> _workStationsWithRects() {
    return customWorkStations.map((ws) {
      final rect = Rect.fromCenter(
        center: Offset(ws.left * imageSize.width, ws.top * imageSize.height),
        width: 100,
        height: 100,
      );
      return WorkStationWithRect(ws, rect);
    }).toList();
  }

  void _checkDragStart(Offset localPosition) {
    var height = MediaQuery.of(context).size.shortestSide * 0.05;
    for (int i = 0; i < customWorkStations.length; i++) {
      final rect = Rect.fromCenter(
        center: Offset(customWorkStations[i].left * imageSize.width, customWorkStations[i].top * imageSize.height),
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
          customWorkStations[_draggingIndex].left = left;
          customWorkStations[_draggingIndex].top = top;
        });

        // Save updated position
        _savePositions();
      }
    }
  }

  void _handleTap(Offset localPosition) {
    for (int i = 0; i < customWorkStations.length; i++) {
      final ws = customWorkStations[i];
      final rect = Rect.fromCenter(
        center: Offset(ws.left * imageSize.width, ws.top * imageSize.height),
        width: 100,
        height: 100,
      );
      if (rect.contains(localPosition)) {
        _showWorkstationPopup(ws);
        break;
      }
    }

    void _deleteWorkstation(CustomWorkStation ws) {
      final store = ObjectBoxStore.instance;
      final box = store.box<CustomWorkStation>();

      box.remove(ws.id);
      setState(() {
        customWorkStations.removeWhere((w) => w.id == ws.id);
      });
    }
  }

  void _savePositions() async {
    // if(_canSave()){
      final store = ObjectBoxStore.instance;
      final box = store.box<CustomWorkStation>();

      await box.removeAll();
      await box.putMany(customWorkStations);
    // }
  }
}

class RectanglePainter extends CustomPainter {
  final List<WorkStationWithRect> items;
  final Map<String, ui.Image> images;

  RectanglePainter(this.items, this.images);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.blue.withOpacity(0.5);

    for (var item in items) {
      final rect = item.rect;
      final ws = item.ws;

      // Draw rectangle
      canvas.drawRect(rect, paint);

      // Draw image inside rectangle
      if (images.containsKey(ws.imagePath)) {
        final img = images[ws.imagePath]!;
        final imgSize = Size(img.width.toDouble(), img.height.toDouble());

        final dstRect = Rect.fromCenter(
          center: rect.center,
          width: rect.width * 0.8,
          height: rect.height * 0.6,
        );
        paintImage(
          canvas: canvas,
          rect: dstRect,
          image: img,
          fit: BoxFit.contain,
        );
      }

      // Draw name below the image
      final textSpan = TextSpan(
        text: ws.name,
        style: const TextStyle(color: Colors.black, fontSize: 13,fontWeight: FontWeight.bold),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout(
        minWidth: 0,
        maxWidth: rect.width,
      );

      final offset = Offset(
        rect.center.dx - textPainter.width / 2,
        rect.bottom - textPainter.height - 4,
      );
      textPainter.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}


class OverlayItem {
  String name;
  String imagePath;
  String type;
  String status;
  Offset position;

  OverlayItem({
    required this.name,
    required this.imagePath,
    required this.type,
    required this.status,
    required this.position,
  });
}

class WorkStationWithRect {
  final CustomWorkStation ws;
  final Rect rect;

  WorkStationWithRect(this.ws, this.rect);
}

