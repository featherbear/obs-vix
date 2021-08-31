import 'package:obs_vix/OBSClient.dart';

const NBOX_PREFIX = "vix::nbox::";
const NBOX_SWITCHER_PREFIX = "vix::nbox::switcher::";

abstract class NBox_funcs {
  static Future<Map<String, List<String>>> getNBoxSources(OBSClient client, {String? scene}) async {
    if (scene == null) {
      return client.request(command: "GetSceneList").then((dynamic resp) => {
            for (var obj in resp["scenes"].where((obj) => (obj["name"] as String).startsWith("vix::nbox::switcher::")))
              obj["name"]: obj["sources"].map((s) => s["name"]).toList().cast<String>()
          });
    } else {
      if (!scene.startsWith(NBOX_SWITCHER_PREFIX)) return {};
      return {
        scene: await client.request(
            command: "GetSceneItemList",
            params: {"sceneName": scene}).then((resp) => resp["sceneItems"].map((s) => s["sourceName"]).toList().cast<String>())
      };
    }
  }

  static Future initNBox(OBSClient client, {required int n}) async {
    // Get all nbox scenes with nbox sources
    Map<String, List<String>> sceneSources = {
      for (var sceneObj
          in ((await client.request(command: "GetSceneList"))["scenes"] as List).where((scene) => (scene as Map)["name"].startsWith(NBOX_PREFIX)))
        sceneObj["name"]: (sceneObj["sources"] as List)
            .where((source) => (source as Map)["name"].startsWith(NBOX_PREFIX))
            .map((source) => source["name"])
            .toList()
            .cast<String>()
    };

    // the largest n-box needs `n` switcher scenes
    for (int i = 1; i <= n; i++) {
      String nbox_switcher_sceneName = "$NBOX_SWITCHER_PREFIX$i";
      if (sceneSources.containsKey(nbox_switcher_sceneName)) continue;

      // TODO: Link switcher items?

      await client.request(command: "CreateScene", params: {"sceneName": nbox_switcher_sceneName});
      sceneSources[nbox_switcher_sceneName] = [];
    }

    // each n-box needs to contain n switchers
    for (int i = 1; i <= n; i++) {
      String nbox_sceneName = "$NBOX_PREFIX$i";

      if (!sceneSources.containsKey(nbox_sceneName)) {
        await client.request(command: "CreateScene", params: {"sceneName": nbox_sceneName});
        sceneSources[nbox_sceneName] = [];
      }

      for (int j = 1; j <= i; j++) {
        String nbox_switcher_sceneName = "$NBOX_SWITCHER_PREFIX$j";
        if (sceneSources[nbox_sceneName]!.contains(nbox_switcher_sceneName)) continue;

        await client.request(command: "AddSceneItem", params: {"sceneName": nbox_sceneName, "sourceName": nbox_switcher_sceneName});

        // TODO: Tiling algorithm?
      }
    }
  }
}
