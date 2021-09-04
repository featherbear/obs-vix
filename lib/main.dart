import 'dart:async';
import 'dart:developer';
import 'dart:math' as Math;
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vix :: OBS Vision Mixer',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: MyHomePage(title: 'Vix :: OBS Vision Mixer'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
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
      NBox_funcs.initNBox(this.client);

      {
        /* Preview and Program feed */
        setState(() {
          previewSourceViewer.init(this.client);
          programSourceViewer.init(this.client);
        });
        {
          this.client
            ..addEventListener("SwitchScenes", (data) {
              programSourceViewer.updateSource(data["scene-name"]);
            })
            ..addEventListener("PreviewSceneChanged", (data) {
              previewSourceViewer.updateSource(data["scene-name"]);
            });
        }
      }

      _tryConnect();
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
      var VIX = readVIXState();
      previewSourceViewer.updateSource(VIX["activePreview"] ?? VIX["activeProgram"]);
      programSourceViewer.updateSource(VIX["activeProgram"]);
    } on AuthException catch (e) {
      showConfigErrorDialog("Authentication Error", "Connection failed: ${e.message}");
    } catch (e) {
      log(e.toString());
      showConfigErrorDialog("Connection Error", "Could not connect to the OBS server");
    }
  }

  final VIXClient client = VIXClient(); //..addRawListener((data) => log(data));

  final focusNode = FocusNode()..requestFocus();

  SourceView previewSourceViewer = SourceView();
  SourceView programSourceViewer = SourceView();

  @override
  Widget build(BuildContext context) {
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
                                                  if (settings.nBoxes > 0) {
                                                    NBox_funcs.createNBoxes(this.client, n: settings.nBoxes).then((_) {
                                                      NBox_funcs.getNBoxSources(this.client)
                                                          .then((nBoxSources) => updateVIXState((m) => m["nBoxSources"] = nBoxSources));
                                                    });
                                                  }
                                                  ;
                                                  Navigator.pop(context);
                                                },
                                              ))))))
                            },
                          )
                        ])
              ],
            ),
            body: Center(
              child: Padding(
                  padding: EdgeInsets.only(top: 15, left: 15, right: 15),
                  child: Column(
                    children: <Widget>[
                      Padding(
                          padding: EdgeInsets.only(bottom: 15),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, crossAxisAlignment: CrossAxisAlignment.center, children: [
                            Container(
                                // color: Colors.blue[200],
                                child: Column(children: [
                              SizedBox(width: Math.min(MediaQuery.of(context).size.width * 0.40, 480), child: previewSourceViewer),
                              Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Text("PREVIEW"))
                            ])),
                            Container(
                                // color: Colors.green[200],
                                child: Column(children: [
                              SizedBox(width: Math.min(MediaQuery.of(context).size.width * 0.40, 480), child: programSourceViewer),
                              Padding(padding: EdgeInsets.symmetric(vertical: 5), child: Text("PROGRAM"))
                            ]))
                          ])),

                      // provideVIXState(ProgramView(this.client)),
                      // buildVIXProvider((context, data) => SourceView(sourceName: data["activeProgram"])),
                      provideVIXState(PreviewProgramController(
                        onPreviewEvent: this.client.handleChangePreview,
                        onProgramEvent: (idx) {
                          String? targetScene = readVIXState()["buttons"][idx];
                          if (targetScene == null) return;

                          String? oldPreviewScene = readVIXState()["activePreview"];
                          client.request(command: "SetCurrentScene", params: {"scene-name": targetScene}).then((_) {
                            // When the program is changed, the preview updates to the old program - not what we want!
                            // The "Swap Preview/Output Scenes After Transitioning" would fix this issue, but we want to keep this on like a normal vision mixer
                            if (oldPreviewScene != null)
                              client.addEventListener("PreviewSceneChanged", (data) {
                                client.request(command: "SetPreviewScene", params: {"scene-name": oldPreviewScene}).then((_) {});
                              }, once: true);
                          });
                        },
                      )),

                      Expanded(
                        child: ListView(
                          children: [provideVIXState(NBoxController(this.client))],
                        ),
                      ),
                    ],
                  )),
            )));
  }
}
