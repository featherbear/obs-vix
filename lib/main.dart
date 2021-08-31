import 'dart:async';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_vix/NBox_funcs.dart';
import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXClient.dart';
import 'package:obs_vix/PageViewWrapper.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/controls/NBoxController.dart';
import 'package:obs_vix/controls/PreviewProgramController.dart';
import 'package:obs_vix/controls/SourceView.dart';
import 'package:obs_vix/settings/assignment/data.dart';
import 'package:obs_vix/settings/assignment/view.dart';
import 'package:obs_vix/settings/connection/data.dart';
import 'package:obs_vix/settings/connection/view.dart';
import 'package:page_transition/page_transition.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vix :: OBS Vision Mixer',
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
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(title: 'Vix :: OBS Vision Mixer'),
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

  _MyHomePageState() {
    SharedPreferences.getInstance().then((prefs) {
      {
        String? host = prefs.getString("obs::host");
        int? port = prefs.getInt("obs::port");
        String? password = prefs.getString("obs::pass");

        if (host == null || port == null) {
          this._connectionSettings = ConnectionSettings(
            host: "localhost",
            port: 4444,
          );
        } else {
          this._connectionSettings = ConnectionSettings(host: host, port: port, password: password);
        }
      }

      updateVIXState((m) {
        m["buttons"] = (prefs.getStringList("vix::buttons") ?? []).map((s) => s.isNotEmpty ? s : null).toList();
        m["nBoxes"] = prefs.getInt("vix::nBoxes") ?? 0;
      });
    }).then((_) {
      this.client.addConnectCallback((client) async {
        var data = await NBox_funcs.updateNBoxSources(client);
        updateVIXState((m) => {m["nBoxSources"] = data});
      });

      {
        this.client
          ..addEventListener("SceneItemAdded", (resp) async {
            if (!resp["scene-name"].startsWith("vix::nbox::switcher::")) return;
            var data = await NBox_funcs.updateNBoxSources(client, scene: resp["scene-name"]);
            updateVIXState((m) {
              (m["nBoxSources"] as Map).addAll(data);
            });
          })
          ..addEventListener("SceneItemRemoved", (resp) async {
            if (!resp["scene-name"].startsWith("vix::nbox::switcher::")) return;
            var data = await NBox_funcs.updateNBoxSources(client, scene: resp["scene-name"]);
            updateVIXState((m) {
              (m["nBoxSources"] as Map).addAll(data);
            });
          });
      }
      {
        this.client
          ..addEventListener("SwitchScenes", (data) {
            sourceViewer.updateSource(data["scene-name"]);
          })
          ..addEventListener("PreviewSceneChanged", (data) {
            sourceViewer.updateSource(data["scene-name"]);
          });
      }

      _tryConnect().then((_) {
        // TODO: reeee
        setState(() {
          sourceViewer.init(this.client);
        });
      });
    });
  }

  late ConnectionSettings _connectionSettings;

  void showConnectionSettingsPage() {
    Navigator.push(
        context,
        PageTransition(
            type: PageTransitionType.fade,
            child: PageViewWrapper(
                title: "OBS Connection Settings",
                child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 15),
                    child: SettingsConnectionView(
                      prefill: this._connectionSettings,
                      saveCallback: (settings) {
                        SharedPreferences.getInstance().then((prefs) => Future.wait([
                              prefs.setString("obs::host", settings.host),
                              prefs.setInt("obs::port", settings.port),
                              (settings.password == null) ? prefs.remove("obs::pass") : prefs.setString("obs::pass", settings.password!)
                            ]));
                        this._connectionSettings = settings;
                        Navigator.pop(context);
                        this._tryConnect();
                      },
                    )))));
  }

  Future _tryConnect() async {
    void showConfigErrorDialog(String title, String description) {
      showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
                title: Text(title),
                content: Text(description),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        this.showConnectionSettingsPage();
                      },
                      child: Padding(padding: EdgeInsets.all(5), child: Text("Edit Settings")))
                ],
              ));
    }

    try {
      await this.client.connectObject(this._connectionSettings);
    } on AuthException catch (e) {
      showConfigErrorDialog("Authentication Error", "Connection failed: ${e.message}");
    } catch (e) {
      log(e.toString());
      showConfigErrorDialog("Connection Error", "Could not connect to the OBS server");
    }
  }

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  final VIXClient client = VIXClient(); //..addRawListener((data) => log(data));

  final focusNode = FocusNode()..requestFocus();

  SourceView sourceViewer = SourceView();

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return RawKeyboardListener(
        focusNode: focusNode,
        onKey: (evt) {
          if (!(evt is RawKeyDownEvent)) return;

          int keyCode = evt.logicalKey.keyId;
          if (0x31 <= keyCode && keyCode <= 0x39) return this.client.handleChangePreview(keyCode - 0x31);

          if (evt.logicalKey == LogicalKeyboardKey.space) {
            client.request(command: "TransitionToProgram", params: {
              "with-transition": {"name": "Fade", "duration": 300}
            });
          }

          if (evt.logicalKey == LogicalKeyboardKey.enter) {
            focusNode.requestFocus();
            client.request(command: "TransitionToProgram", params: {
              "with-transition": {"name": "Cut", "duration": 0}
            });
          }
        },
        child: Scaffold(
          appBar: AppBar(
            // Here we take the value from the MyHomePage object that was created by
            // the App.build method, and use it to set our appbar title.
            title: Text(widget.title),
            actions: [
              PopupMenuButton(
                  onSelected: (Function fn) => fn(),
                  itemBuilder: (context) => [
                        PopupMenuItem(
                          child: Text("Connection Settings"),
                          value: this.showConnectionSettingsPage,
                        ),
                        PopupMenuItem(
                          child: Text("Interface Settings"),
                          value: () => {
                            Navigator.push(
                                context,
                                PageTransition(
                                    type: PageTransitionType.fade,
                                    child: PageViewWrapper(
                                        title: "Vix Interface Settings",
                                        child: Padding(
                                            padding: EdgeInsets.symmetric(horizontal: 15),
                                            child: provideVIXState(SettingsAssignmentView(
                                              prefill: AssignmentSettings(buttons: readVIXState()["buttons"], nBoxes: readVIXState()["nBoxes"]),
                                              saveCallback: (settings) {
                                                SharedPreferences.getInstance().then((prefs) {
                                                  prefs.setInt("vix::nBoxes", settings.nBoxes);
                                                  prefs.setStringList("vix::buttons", settings.buttons.map((s) => s != null ? s : "").toList());
                                                });
                                                updateVIXState((m) {
                                                  m["buttons"] = settings.buttons;
                                                  m["nBoxes"] = settings.nBoxes;
                                                });
                                                if (settings.nBoxes > 0) NBox_funcs.initNBox(this.client, n: settings.nBoxes);
                                                Navigator.pop(context);
                                              },
                                            ))))))
                          },
                        )
                      ])
            ],
          ),
          body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: Padding(
                padding: EdgeInsets.all(15),
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
                  // mainAxisAlignment: MainAxisAlignment.center,
                  // crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(width: 720, height: 480, child: sourceViewer),

                    // provideVIXState(ProgramView(this.client)),
                    // buildVIXProvider((context, data) => SourceView(sourceName: data["activeProgram"])),

                    provideVIXState(PreviewProgramController(
                      onPreviewEvent: this.client.handleChangePreview,
                      onProgramEvent: (idx) {
                        String? targetScene = readVIXState()["buttons"][idx];
                        if (targetScene == null) return;
                        client.request(command: "SetCurrentScene", params: {"scene-name": targetScene});
                      },
                    )),
                    provideVIXState(NBoxController(this.client)),
                    Text(
                      'You have pushed the button this many times:',
                    ),
                    Text(
                      '$_counter',
                      style: Theme.of(context).textTheme.headline4,
                    ),
                  ],
                )),
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: _incrementCounter,
            tooltip: 'Increment',
            child: Icon(Icons.add),
          ), // This trailing comma makes auto-formatting nicer for build methods.
        ));
  }
}
