import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:obs_vix/VIXUtils.dart';

enum COLOUR { RED, GREEN, YELLOW, BLANK }

class Button extends StatelessWidget {
  static Color resolveColourEnum(COLOUR colour) {
    switch (colour) {
      case COLOUR.RED:
        return Colors.red;
      case COLOUR.GREEN:
        return Colors.green;
      case COLOUR.YELLOW:
        return Colors.yellow;
      case COLOUR.BLANK:
        return Colors.grey;
    }
  }

  final COLOUR colour;
  final String? label;
  final void Function()? onPress;

  const Button({this.onPress, this.label, this.colour = COLOUR.BLANK, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 65,
        width: 65,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(primary: resolveColourEnum(this.colour)),
          child: Text(VIXUtils.processLabel(label)),
          onPressed: onPress,
        ));
  }
}
