import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/controls/Button.dart';

class PreviewProgramController extends StatefulWidget {
  const PreviewProgramController({Key? key}) : super(key: key);

  @override
  _PreviewProgramControllerState createState() =>
      _PreviewProgramControllerState();
}

class _PreviewProgramControllerState extends State<PreviewProgramController> {
  Button generateButton(int idx, {String? label, COLOUR? colour}) {
    void Function() cb = () {
      log(idx.toString());
    };

    if (colour == null) return new Button(label: label, onPress: cb);
    return new Button(label: label, onPress: cb, colour: colour);
  }

  List<Widget> generateRowChildren(
      VIXStateData VIX, String stateKey, COLOUR activeColour) {
    String target = VIX[stateKey] ?? "";
    List<String?> buttonMaps = VIX["buttons"] ?? [];

    return buttonMaps
        .asMap()
        .entries
        .map((scene) => (scene.value == target)
            ? generateButton(
                scene.key,
                label: scene.value,
                colour: activeColour,
              )
            : generateButton(scene.key, label: scene.value))
        .toList()
        .cast<Widget>();
  }

  @override
  Widget build(BuildContext context) {
s    final VIX = getState(context);

    return Container(
      child: new Column(
        children: [
          new Row(
              children:
                  generateRowChildren(VIX, "activePreview", COLOUR.GREEN)),
          new Row(
              children: generateRowChildren(VIX, "activeProgram", COLOUR.RED)),
          new Text(VIX["activeScene"] ?? "nope")
        ],
      ),
    );
  }
}
