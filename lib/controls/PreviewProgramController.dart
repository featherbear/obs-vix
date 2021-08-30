import 'package:flutter/widgets.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/controls/Button.dart';

typedef CallbackType = void Function(int);

class PreviewProgramController extends StatefulWidget {
  final CallbackType? onProgramEvent;
  final CallbackType? onPreviewEvent;
  const PreviewProgramController({this.onProgramEvent, this.onPreviewEvent, Key? key}) : super(key: key);

  @override
  _PreviewProgramControllerState createState() =>
      _PreviewProgramControllerState(onProgramEvent: this.onProgramEvent, onPreviewEvent: this.onPreviewEvent);
}

class _PreviewProgramControllerState extends State<PreviewProgramController> {
  final CallbackType? onProgramEvent;
  final CallbackType? onPreviewEvent;
  _PreviewProgramControllerState({this.onProgramEvent, this.onPreviewEvent});

  Button generateButton(int idx, {String? label, COLOUR? colour, CallbackType? onPressEvent}) {
    void Function() cb = () => onPressEvent?.call(idx);

    if (colour == null) return new Button(label: label, onPress: cb);
    return new Button(label: label, onPress: cb, colour: colour);
  }

  List<Widget> generateRowChildren(VIXStateData VIX, String stateKey, COLOUR activeColour, CallbackType? onPressEvent) {
    String target = VIX[stateKey] ?? "";
    List<String?> buttonMaps = VIX["buttons"] ?? [];

    return buttonMaps
        .asMap()
        .entries
        .map((scene) => (scene.value == target)
            ? generateButton(scene.key, label: scene.value, colour: activeColour, onPressEvent: onPressEvent)
            : generateButton(scene.key, label: scene.value, onPressEvent: onPressEvent))
        .toList()
        .cast<Widget>();
  }

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    return Container(
      child: new Column(
        children: [
          new Row(children: generateRowChildren(VIX, "activePreview", COLOUR.GREEN, this.onPreviewEvent)),
          new Row(children: generateRowChildren(VIX, "activeProgram", COLOUR.RED, this.onProgramEvent)),
        ],
      ),
    );
  }
}
