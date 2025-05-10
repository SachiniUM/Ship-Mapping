import 'package:flutter/material.dart';

import 'adminPages/configurations.dart';
import 'common/custom_button.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Image Mapping"),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('Settings'),
            ),
            ListTile(
              title: const Text('Configure'),
              onTap: () {
                Navigator.pushNamed(context, "/configurations");
              },
            ),
            ListTile(
              title: const Text('Item 2'),
              onTap: () {
                // Update the state of the app.
                // ...
              },
            ),
          ],
        ),
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
              text: 'Display Popup Options',
              routeName: '/tableDisplay',
            ),
            CustomButton(
              text: 'Edit Workstations',
              routeName: '/dragAndDropEdit',
            ),
            CustomButton(
              text: 'View Architecture',
              routeName: '/viewArchitecture',
            ),
            CustomButton(
              text: 'Edit Architecture',
              routeName: '/editArchitecture',
            ),
          ],
        ),
      ),
    );
  }
}

