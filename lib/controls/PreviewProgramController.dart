import 'package:flutter/widgets.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/controls/Button.dart';
import 'package:obs_vix/controls/ButtonRow.dart';

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

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);
    var buttons = VIX["buttons"] ?? [];
    return Container(
      child: new Column(
        children: [
          new Padding(
              padding: EdgeInsets.only(bottom: PAD_SIZE),
              child: RadioButtonRow(
                  buttons: buttons, activeColour: COLOUR.GREEN, activeLabel: VIX["activePreview"], onButtonPress: this.onPreviewEvent)),
          new Padding(
              padding: EdgeInsets.only(bottom: PAD_SIZE),
              child:
                  RadioButtonRow(buttons: buttons, activeColour: COLOUR.RED, activeLabel: VIX["activeProgram"], onButtonPress: this.onProgramEvent))
        ],
      ),
    );
  }
}
