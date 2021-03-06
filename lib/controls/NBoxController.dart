import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:obs_vix/NBox_funcs.dart';
import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/VIXUtils.dart';
import 'package:obs_vix/controls/Button.dart';
import 'package:obs_vix/controls/ButtonRow.dart';
import 'package:obs_vix/controls/SourceView.dart';

class NBoxController extends StatefulWidget {
  final OBSClient client;
  const NBoxController(this.client, {Key? key}) : super(key: key);

  @override
  _NBoxControllerState createState() => _NBoxControllerState(this.client);
}

class _NBoxControllerState extends State<NBoxController> {
  final OBSClient client;
  _NBoxControllerState(this.client);

  Map<String, String> activeNBoxSource = {};
  Map<String, SourceView> NBoxSourcePreview = {};

  SourceView getNBoxSourcePreview(String sourceName) {
    if (!NBoxSourcePreview.containsKey(sourceName)) NBoxSourcePreview[sourceName] = SourceView()..init(this.client, sourceName: sourceName);
    return NBoxSourcePreview[sourceName]!;
  }

  int last_n_boxes = 0;

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    final int? n_boxes = VIX["nBoxes"];
    if (n_boxes == null || n_boxes == 0) return Container();
    if (n_boxes > last_n_boxes) NBoxSourcePreview.clear(); // Handle doubly changed n-box count
    last_n_boxes = n_boxes;

    Map<String, List<String>>? sources = VIX["nBoxSources"];
    if (sources == null) return Container();

    Widget generateRow(int idx) {
      var name = "$NBOX_SWITCHER_PREFIX$idx";

      Widget wrap() {
        List<String>? source = sources[name];
        if (source == null)
          return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Missing nbox scene: $name",
                style: TextStyle(color: Colors.red),
              ));

        return source.isNotEmpty
            ? RadioButtonRow(
                buttons: source,
                activeColour: COLOUR.YELLOW,
                activeLabel: activeNBoxSource[name],
                onButtonPress: (idx) {
                  String activeItem = source[idx];

                  for (String sourceName in source) {
                    this.client.request(
                        command: "SetSceneItemRender", params: {"scene-name": name, "source": sourceName, "render": sourceName == activeItem});
                    // this.client.request(
                    //     command: "SetSceneItemProperties",
                    //     params: {"scene-name": source.key, "item": sourceName, "visible": sourceName == activeItem});
                  }
                  getNBoxSourcePreview(name).update(); // Force redraw

                  setState(() {
                    activeNBoxSource[name] = activeItem;
                  });
                },
              )
            : Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "No items in this switcher",
                  style: TextStyle(color: Colors.grey),
                ));
      }

      return Container(
          child: Padding(
              padding: EdgeInsets.only(bottom: 15),
              child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                Padding(padding: EdgeInsets.only(right: 15), child: SizedBox(height: 90, child: getNBoxSourcePreview(name))),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Padding(
                    padding: EdgeInsets.only(bottom: 5),
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "${VIXUtils.processLabel(name)}",
                          style: TextStyle(fontSize: 22),
                        )),
                  ),
                  wrap()
                ])
              ])));
    }

    // Source transition?

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (int i = 1; i <= n_boxes; i++) generateRow(i)]);
  }
}
