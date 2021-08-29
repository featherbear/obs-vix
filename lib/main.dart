import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/controls/PreviewProgramController.dart';
import 'package:obs_vix/settings/assignment/view.dart';
import 'package:obs_vix/settings/connection/view.dart';
import 'package:web_socket_channel/io.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OBS Vix - Vision Mix',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(title: 'OBS Vix - Vision Mix'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  OBSClient client = new OBSClient()
    // ..addRawListener((data) {
    //   log(data);
    // })
    ..connect(host: 'localhost', port: 4444, password: "1234")
        .then((client) async {
      {
        client.request(command: "EnableStudioMode");
        client.request(command: "GetCurrentScene").then((data) {
          updateState((m) {
            m["activeProgram"] = data["name"];
          });
        });
        client.request(command: "GetPreviewScene").then((data) {
          updateState((m) {
            m["activePreview"] = data["name"];
          });
        });
      }

      client.addEventListener("StudioModeSwitched", (data) async {
        if (!data["new-state"]) client.request(command: "EnableStudioMode");
      });

      client.addEventListener("SwitchScenes", (data) async {
        updateState((m) {
          m["activeProgram"] = data["scene-name"];
        });
      });

      client.addEventListener("PreviewSceneChanged", (data) async {
        updateState((m) {
          m["activePreview"] = data["scene-name"];
        });
      });

      client.addEventListener("SceneItemVisibilityChanged", (data) async {
// SceneItemAdded
// SourceOrderChanged
      });

// ScenesChanged
// SwitchedScenes

      var resp = await client.request(command: "GetSceneList");
      String currentScene = resp["current-scene"];

      List<dynamic> scenes = resp["scenes"];

      updateState((fn) {
        fn["scenes"] = scenes.map((e) => (e["name"])).toList();
      });
      // Map<String, dynamic> scenesObject = new Map();
      // for (dynamic scene in scenes)
      //   scenesObject[scene["name"]] = scene["sources"];
    });
  Uri? obsAddress;

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: Text(widget.title),
      ),
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(
          // Column is also a layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug painting" (press "p" in the console, choose the
          // "Toggle Debug Paint" action from the Flutter Inspector in Android
          // Studio, or the "Toggle Debug Paint" command in Visual Studio Code)
          // to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            new Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: provideState(SettingsAssignment(
                  saveCallback: (buttons) {
                    log(("Got save"));
                    updateState((fn) {
                      fn["buttons"] = buttons;
                    });
                  },
                ))),
            new Padding(
                padding: EdgeInsets.symmetric(horizontal: 15),
                child: SettingsConnection(
                  saveCallback: (settings) {
                    Uri? _ =
                        Uri.tryParse('ws://${settings.host}:${settings.port}');
                    if (_ != null) {
                      setState(() {
                        obsAddress = _;
                      });
                      client.connectURI(_);
                    }
                  },
                )),
            provideState(PreviewProgramController()),
            Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
            Text(obsAddress?.toString() ?? ""),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}
