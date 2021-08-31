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

  Widget generateButton(int idx, {String? label, COLOUR? colour, CallbackType? onPressEvent}) {
    void Function() cb = () => onPressEvent?.call(idx);

    if (colour == null) return new Button(label: label, onPress: cb);
    return new Button(label: label, onPress: cb, colour: colour);
  }

  final double PAD_SIZE = 15;
  Widget padIt(Widget widget) {
    return Padding(padding: EdgeInsets.only(right: PAD_SIZE), child: widget);
  }

  List<Widget> generateRowChildren(VIXStateData VIX, String stateKey, COLOUR activeColour, CallbackType? onPressEvent) {
    String target = VIX[stateKey] ?? "";
    List<String?> buttonMaps = VIX["buttons"] ?? [];

    return buttonMaps
        .asMap()
        .entries
        .map((scene) => (scene.value == target)
            ? padIt(generateButton(scene.key, label: scene.value, colour: activeColour, onPressEvent: onPressEvent))
            : padIt(generateButton(scene.key, label: scene.value, onPressEvent: onPressEvent)))
        .toList()
        .cast<Widget>();
  }

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    return Container(
      child: new Column(
        children: [
          new Padding(
              padding: EdgeInsets.only(bottom: PAD_SIZE),
              child: new Row(children: generateRowChildren(VIX, "activePreview", COLOUR.GREEN, this.onPreviewEvent))),
          new Row(children: generateRowChildren(VIX, "activeProgram", COLOUR.RED, this.onProgramEvent)),
        ],
      ),
    );
  }
}
