import 'package:flutter/widgets.dart';
import 'package:obs_vix/controls/Button.dart';

const double PAD_SIZE = 15;

typedef CallbackType = void Function(int);

class RadioButtonRow extends StatelessWidget {
  final List<String?> buttons;
  final COLOUR activeColour;
  final CallbackType? onButtonPress;
  final String activeLabel;
  const RadioButtonRow({required this.buttons, required this.activeColour, required this.activeLabel, this.onButtonPress, Key? key})
      : super(key: key);

  List<Widget> generateRowChildren(List<String?> buttons, String activeLabel, COLOUR activeColour, CallbackType? onPressEvent) {
    return buttons
        .asMap()
        .entries
        .map((scene) => (scene.value == activeLabel)
            ? padIt(generateButton(scene.key, label: scene.value, colour: activeColour, onPressEvent: onPressEvent))
            : padIt(generateButton(scene.key, label: scene.value, onPressEvent: onPressEvent)))
        .toList()
        .cast<Widget>();
  }

  Widget generateButton(int idx, {String? label, COLOUR? colour, CallbackType? onPressEvent}) {
    void Function() cb = () => onPressEvent?.call(idx);

    if (colour == null) return new Button(label: label, onPress: cb);
    return new Button(label: label, onPress: cb, colour: colour);
  }

  Widget padIt(Widget widget) {
    return Padding(padding: EdgeInsets.only(right: PAD_SIZE), child: widget);
  }

  @override
  Widget build(BuildContext context) {
    return new Row(children: generateRowChildren(this.buttons, activeLabel, this.activeColour, this.onButtonPress));
  }
}
