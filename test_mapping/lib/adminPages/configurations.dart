import 'package:flutter/material.dart';

import '../common/custom_button.dart';

class ConfigurationPage extends StatefulWidget {
  ConfigurationPage({super.key, required this.logOutFunction, required this.refreshTokenFunction});
  final logOutFunction;
  final refreshTokenFunction;

  @override
  State<ConfigurationPage> createState() => _ConfigurationPageState();
}

class _ConfigurationPageState extends State<ConfigurationPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Configuration"),
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
              text: 'Change Drawing',
              routeName: '/changeDrawing',
            ),
          ],
        ),
      ),
    );
  }
}
