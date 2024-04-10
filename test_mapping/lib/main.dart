import 'package:flutter/material.dart';
import 'package:test_mapping/coordinates.dart';
import 'package:test_mapping/drag_drop_edit.dart';
import 'package:test_mapping/drag_drop_lock.dart';
import 'package:test_mapping/global_key.dart';
import 'package:test_mapping/show_data.dart';
import 'package:test_mapping/show_data_representation.dart';
import 'package:test_mapping/show_edited_data.dart';
import 'package:test_mapping/show_work_tasks.dart';

import 'drag_and_drop.dart';
import 'entities/objectBoxStore.dart';
import 'image_page.dart';
import 'objectbox.g.dart';

void main() {
  runApp(const MyApp());
}

// late final Admin _admin;
//
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   ObjectBoxStore.initStore().then((_) async {
//     if (Admin.isAvailable()) {
//       _admin = Admin(ObjectBoxStore.instance);
//     }
//
//   runApp(const MyApp());
//   });
//   ObjectBoxStore.closeStore();
// }

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Testing Image Mapping',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes: {
        '/': (context) => MyHomePage(title: 'Image Mapping'),
        '/imageMap': (context) => ImageMap(),
        '/dragAndDrop': (context) => CustomPainterDraggable(),
        '/dragAndDropLock': (context) => CustomPainterDraggableLock(),
        '/dragAndDropEdit': (context) => CustomPainterDraggableEdit(),
        '/dragAndDropShow': (context) => CustomPainterDraggableShow(),
        '/showWorkTasks': (context) => ShowWorkTasks(),
        '/showData': (context) => ShowData(),
        '/showDataRepresentation': (context) => ShowDataRepresentation(),
        '/coordinates': (context) => Coordinates(),
        '/coordinatesTest': (context) => WidgetSizeAndPositionExample(),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Text(
              'Menu',
              style: TextStyle(
                fontSize: 40.0,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            CustomButton(
              text: 'Coordinates',
              routeName: '/coordinates',
            ),
            // SizedBox(height: 150,),
            CustomButton(
              text: 'test',
              routeName: '/coordinatesTest',
            ),
            CustomButton(
              text: 'Workstation View (with objectbox)',
              routeName: '/showData',
            ),
            // SizedBox(height: 150,),
            CustomButton(
              text: 'Workstation with Representation',
              routeName: '/showDataRepresentation',
            ),
            // SizedBox(height: 150,),
            CustomButton(
              text: 'Edit Workstations',
              routeName: '/dragAndDropEdit',
            ),
            // SizedBox(height: 150,),
            CustomButton(
              text: 'Show Work Tasks',
              routeName: '/showWorkTasks',
            ),

            // Column(
            //   // crossAxisAlignment: CrossAxisAlignment.start,
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: <Widget>[
            //     CustomButton(
            //       text: 'Workstation View (with objectbox)',
            //       routeName: '/showData',
            //     ),
            //     // SizedBox(height: 150,),
            //     CustomButton(
            //       text: 'Workstation with Representation',
            //       routeName: '/showDataRepresentation',
            //     ),
            //     // SizedBox(height: 150,),
            //     CustomButton(
            //       text: 'Edit Workstations',
            //       routeName: '/dragAndDropEdit',
            //     ),
            //     // SizedBox(height: 150,),
            //     CustomButton(
            //       text: 'Show Work Tasks',
            //       routeName: '/showWorkTasks',
            //     ),
            //   ],
            // )

          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}


class CustomButton extends StatelessWidget {
  final String text;
  final String routeName;

  const CustomButton({
    Key? key,
    required this.text,
    required this.routeName,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Color buttonColor = Colors.blue;
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context, routeName);
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue, // Set the background color directly
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 16, color: Colors.white), // Set text color directly
      ),
    );
  }
}