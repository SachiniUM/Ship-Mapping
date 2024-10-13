import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:test_mapping/config/user_data.dart';
import 'package:test_mapping/coordinates.dart';
import 'package:test_mapping/drag_drop_edit.dart';
import 'package:test_mapping/drag_drop_lock.dart';
import 'package:test_mapping/global_key.dart';
import 'package:test_mapping/home_page.dart';
import 'package:test_mapping/popup_display.dart';
import 'package:test_mapping/popup_display_options.dart';
import 'package:test_mapping/services/error_handling.dart';
import 'package:test_mapping/zoom_pinch_overlay.dart';
import 'package:test_mapping/select_legends.dart';
import 'package:test_mapping/show_data.dart';
import 'package:test_mapping/show_data_representation.dart';
import 'package:test_mapping/show_edited_data.dart';
import 'package:test_mapping/show_work_tasks.dart';
import 'package:test_mapping/zoom_work_stations.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:http/http.dart' as http;

import 'config/config.dart';
import 'drag_and_drop.dart';
import 'entities/objectBoxStore.dart';
import 'image_page.dart';
import 'objectbox.g.dart';


const FlutterAppAuth visualizerAuth = FlutterAppAuth();

void main() {
  runApp(ShipMapping());
}

late bool _isUserLoggedIn;

class ShipMapping extends StatefulWidget {
  @override
  State<ShipMapping> createState() {
    return _ShipMappingState();
  }
}

class _ShipMappingState extends State<ShipMapping> {

  late int _pageIndex;

  @override
  void initState() {
    super.initState();
    _pageIndex = 1;
    _isUserLoggedIn = false;
  }

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
        // '/': (context) => MyHomePage(title: 'Image Mapping'),
        '/': (context) => LogInPage(loginFunction),
        '/imageMap': (context) => ImageMap(),
        '/dragAndDrop': (context) => CustomPainterDraggable(),
        '/dragAndDropLock': (context) => CustomPainterDraggableLock(),
        '/dragAndDropShow': (context) => CustomPainterDraggableShow(),
        '/showWorkTasks': (context) => ShowWorkTasks(),
        '/showData': (context) => ShowData(),
        '/showDataRepresentation': (context) => ShowDataRepresentation(),
        '/coordinates': (context) => Coordinates(),
        '/coordinatesTest': (context) => SizePositionPage(),
        '/selectLegends': (context) => SelectLegends(),
        '/zoomWorkStations': (context) => ZoomWorkStations(),
        '/zoomPinchOverlay': (context) => ZoomPinchOverlayPage(),
        '/displayPopup': (context) => PopupDisplay(),

        '/dragAndDropEdit': (context) => CustomPainterDraggableEdit(
          logOutFunction: logOutFunction,
          refreshTokenFunction: refreshTokenFunction,
        ),
        '/displayPopupOptions': (context) => PopupDisplayOptions(
          logOutFunction: logOutFunction,
          refreshTokenFunction: refreshTokenFunction,
        ),
        '/homePage': (context) => HomePage(),

      },
    );
  }

  void setPageIndex(index) {
    setState(() {
      _pageIndex = index;
    });
  }

  Future<void> loginFunction() async {
    print('login function');
    try {
      final AuthorizationTokenResponse? result =
      await visualizerAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          Config.clientId,
          Config.redirectUrl,
          discoveryUrl: Config.discoveryUrl,
          promptValues: ['login'],
          scopes: ['openid', 'profile'],
        ),
      );

      setState(() {
        print('print token results -> access token ${result?.accessToken}');
        print('print token results -> refresh token ${result?.refreshToken}');
        _isUserLoggedIn = true;
        UserData.accessToken = result?.accessToken;
        UserData.refreshToken = result?.refreshToken;
        UserData.idToken = result?.idToken;
        _pageIndex = 2;
        var token = UserData.accessToken?.split('.');
        var payload = json.decode(ascii.decode(base64.decode(base64.normalize(token![1]))));  //decode the token
        // print(payload['preferred_username']);
        UserData.userId = payload['preferred_username'].toString().toUpperCase();
      });
    } catch (e, s) {
      print('Error while login to the system: $e - stack: $s');
      setState(() {
        _isUserLoggedIn = false;
      });
    }
  }


  Future<bool> logOutFunction() async {
    try {
      // send logout request
      String apiEndPoint = Config.logoutUrl;
      Map<String, dynamic>? queryParameters = {"id_token_hint": UserData.idToken};

      final response = await http.get(
        Uri.https(Config.apiURL, apiEndPoint,queryParameters),
        headers: {'Authorization': 'Bearer ${UserData.accessToken}'},
      );

      if (response.statusCode == 200) {
        setState(() {
          _isUserLoggedIn = false;
          _pageIndex = 1;
          UserData.userId = "";  // remove user id
        });

        // End the session
        // final EndSessionResponse? result = await visualizerAuth.endSession(
        //   EndSessionRequest(
        //     idTokenHint: _idToken,
        //     postLogoutRedirectUrl: Config.redirectUrl,
        //     discoveryUrl: Config.discoveryUrl,
        //   ),
        // );
      } else {
        if (context.mounted) {
          HttpErrorHandler.showStatusDialog(
              context, response.statusCode, response.reasonPhrase!);
          Navigator.pushReplacementNamed(context, '/');
        }
      }
    } catch (e, s) {
      print('Error while login to the system: $e - stack: $s');
      setState(() {
        _isUserLoggedIn = true;
      });
    }
    return _isUserLoggedIn;
  }

  // refresh the access token using refresh token
  Future<String?> refreshTokenFunction() async {
    Map<String, dynamic> requestBody = {
      "client_id": Config.clientId,
      "grant_type": "refresh_token",
      "refresh_token": UserData.refreshToken,
    };

    // Encode the request body to x-www-form-urlencoded format
    String encodedBody = requestBody.entries
        .map((entry) => '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value.toString())}')
        .join('&');

    String apiEndPoint = Config.tokenUrl;

    final response = await http.post(
      Uri.https(Config.apiURL, apiEndPoint),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: encodedBody,
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      Map<String, dynamic> jsonResponse = json.decode(response.body);

      // Extract tokens and reset to variables
      setState(() {
        _isUserLoggedIn = true;
        UserData.idToken = jsonResponse['id_token'];
        UserData.accessToken = jsonResponse['access_token'];
        UserData.refreshToken = jsonResponse['refresh_token'];
      });
      return UserData.accessToken;
    } else {
      print('Request failed with status: ${response.statusCode}');
      return 'unsuccessful';
    }
  }
}

class LogInPage extends StatelessWidget {
  // ignore: prefer_typing_uninitialized_variables
  final loginFunction;

  const LogInPage(this.loginFunction);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset("assets/images/IdeastoSolutionLogo.jpg", scale: 0.5),
          Center(
            heightFactor: 1.5,
            child: ElevatedButton(
              style: ButtonStyle(
                fixedSize: MaterialStatePropertyAll(Size(250, 40)),
              ),
              onPressed: () {
                loginFunction().then((_) {
                  if (_isUserLoggedIn == true) {
                    // Navigate to home page after login successful
                    Navigator.pushNamed(context, '/homePage');
                  }
                });
                // loginFunction();
              },
              child: Text('Sign In', textScaler: TextScaler.linear(1.4)),
            ),
          ),
        ],
      ),
    );
  }
}