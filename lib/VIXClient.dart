import 'dart:developer';

import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXState.dart';

class VIXClient extends OBSClient {
  VIXClient() {
    this
      ..addEventListener("StudioModeSwitched", (data) {
        if (!data["new-state"]) this.request(command: "EnableStudioMode");
      })
      ..addEventListener("SwitchScenes", (data) {
        updateVIXState((m) {
          m["activeProgram"] = data["scene-name"];
        });
      })
      ..addEventListener("PreviewSceneChanged", (data) {
        updateVIXState((m) {
          m["activePreview"] = data["scene-name"];
        });
      })
      ..addEventListener("TransitionBegin", (resp) {
        updateVIXState((m) {
          // m["activePreview"] = data["from-scene"]; // Don't need to apply the preview, should be handled when PreviewSceneChange is received

          m["activeProgram"] = resp["to-scene"];
        });
      })
      ..addEventListener("ScenesChanged", (resp) {
        // `scenes` doesn't appear inside the object?
        // obs-websocket 4.8.0
        // obs-studio-version 27.0.1
        // _updateScenes().then((scenes) => updateVIXState((m) => m["scenes"] = scenes));

        updateVIXState((m) => m["scenes"] = __sceneResponseParser(resp));
      });
    // ..addEventListener("SceneItemVisibilityChanged", (data) async {
    //   // SceneItemAdded
    //   // SourceOrderChanged
    // });

    this.setConnectCallback((client) async {
      Map updates = {};

      await Future.wait([
        this.request(command: "EnableStudioMode"),
        this.request(command: "GetCurrentScene").then((data) {
          updates["activeProgram"] = data["name"];
        }),
        this.request(command: "GetPreviewScene").then((data) {
          updates["activePreview"] = data["name"];
        }),
        _updateScenes().then((scenes) => updates["scenes"] = scenes)
      ]);

      updateVIXState((data) => data.addEntries(updates.entries));
    });
  }
  Future<List<String>> _updateScenes() => this.request(command: "GetSceneList").then(__sceneResponseParser);

  List<String> __sceneResponseParser(dynamic resp) =>
      resp["scenes"].map((dynamic e) => (e["name"])).where((name) => !(name as String).startsWith("vix::nbox::switcher::")).toList().cast<String>();

  void handleChangePreview(int idx) {
    List<String?>? buttons = readVIXState()["buttons"];
    if (buttons == null) return; // Check if un-init
    if (buttons.length <= idx) return; // Check if valid

    String? targetScene = buttons[idx];
    if (targetScene == null) return; // Check if valid scene

    this.request(command: "SetPreviewScene", params: {"scene-name": targetScene});
  }

  void initNBox({int n = 3}) async {
    // Get all nbox scenes with nbox sources
    Map<String, List<String>> sceneSources = {
      for (var sceneObj
          in ((await this.request(command: "GetSceneList"))["scenes"] as List).where((scene) => (scene as Map)["name"].startsWith("vix::nbox::")))
        sceneObj["name"]: (sceneObj["sources"] as List)
            .where((source) => (source as Map)["name"].startsWith("vix::nbox::"))
            .map((source) => source["name"])
            .toList()
            .cast<String>()
    };

    // the largest n-box needs `n` switcher scenes
    for (int i = 1; i <= n; i++) {
      String nbox_switcher_sceneName = "vix::nbox::switcher::$i";
      if (sceneSources.containsKey(nbox_switcher_sceneName)) continue;

      // TODO: Link switcher items?

      await this.request(command: "CreateScene", params: {"sceneName": nbox_switcher_sceneName});
      sceneSources[nbox_switcher_sceneName] = [];
    }

    log(sceneSources.toString());
    // each n-box needs to contain n switchers
    for (int i = 1; i <= n; i++) {
      String nbox_sceneName = "vix::nbox::$i";

      if (!sceneSources.containsKey(nbox_sceneName)) {
        await this.request(command: "CreateScene", params: {"sceneName": nbox_sceneName});
        sceneSources[nbox_sceneName] = [];
      }

      for (int j = 1; j <= i; j++) {
        String nbox_switcher_sceneName = "vix::nbox::switcher::$j";
        if (sceneSources[nbox_sceneName]!.contains(nbox_switcher_sceneName)) continue;

        this.request(command: "AddSceneItem", params: {"sceneName": nbox_sceneName, "sourceName": nbox_switcher_sceneName});

        // TODO: Tiling algorithm?
      }
    }
  }
}
