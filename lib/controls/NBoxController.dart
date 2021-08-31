import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/VIXUtils.dart';
import 'package:obs_vix/controls/Button.dart';
import 'package:obs_vix/controls/ButtonRow.dart';

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

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    Map<String, List<String>>? sources = VIX["nBoxSources"];
    if (sources == null) return Container();

    // Source transition?

    return Container(
        color: Colors.red,
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: sources.entries
                .map((source) => Container(
                    color: Colors.green,
                    child: Padding(
                        padding: EdgeInsets.only(bottom: 15),
                        child: Column(
                          // crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Container(
                              color: Colors.blue,
                              child: Padding(
                                  padding: EdgeInsets.only(bottom: 5),
                                  child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        "${VIXUtils.processLabel(source.key)}",
                                        style: TextStyle(fontSize: 24),
                                      ))),
                            ),
                            source.value.isNotEmpty
                                ? RadioButtonRow(
                                    buttons: source.value,
                                    activeColour: COLOUR.YELLOW,
                                    activeLabel: activeNBoxSource[source.key],
                                    onButtonPress: (idx) {
                                      String activeItem = source.value[idx];
                                      setState(() {
                                        activeNBoxSource[source.key] = activeItem;
                                      });
                                      for (String sourceName in source.value) {
                                        this.client.request(
                                            command: "SetSceneItemRender",
                                            params: {"scene-name": source.key, "source": sourceName, "render": sourceName == activeItem});
                                        // this.client.request(
                                        //     command: "SetSceneItemProperties",
                                        //     params: {"scene-name": source.key, "item": sourceName, "visible": sourceName == activeItem});
                                      }
                                    },
                                  )
                                : Align(alignment: Alignment.centerLeft, child: Text("No items in this switcher"))
                          ],
                        ))))
                .toList()));
  }
}
