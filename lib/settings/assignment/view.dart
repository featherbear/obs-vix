import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_vix/VIXState.dart';

typedef SceneOrder = List<String?>;
typedef CallbackType = void Function(SceneOrder);

class SettingsAssignmentView extends StatefulWidget {
  final CallbackType? saveCallback;
  final SceneOrder _buttons;

  @override
  SettingsAssignmentView({Key? key, this.saveCallback, SceneOrder? buttons})
      : this._buttons = SceneOrder.from(buttons ?? []),
        super(key: key);

  // : super(key: key);

  @override
  _SettingsAssignmentViewState createState() => _SettingsAssignmentViewState(saveCallback: this.saveCallback, buttons: this._buttons);
}

class _SettingsAssignmentViewState extends State<SettingsAssignmentView> {
  final CallbackType? saveCallback;
  SceneOrder? buttons;

  _SettingsAssignmentViewState({this.saveCallback, this.buttons});

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    // Get scenes, and merge with previously selected scenes (that may no longer exist)
    List<String> sceneList = VIX["scenes"] ?? [];
    if (this.buttons != null) {
      sceneList = [...sceneList, ...this.buttons!.where((s) => s != null).cast<String>()].toSet().toList();
    }

    return Container(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Column(
                children: this
                        .buttons
                        ?.asMap()
                        .entries
                        .map((entry) => Row(children: [
                              Text('Button ${entry.key + 1} = '),
                              DropdownButton(
                                value: entry.value,
                                hint: Text("Select scene"),
                                items: ['', ...sceneList].cast<String>().map((e) {
                                  return DropdownMenuItem(value: e, child: Text(e.isNotEmpty ? e : "(none)"));
                                }).toList(),
                                onChanged: (String? s) {
                                  setState(() {
                                    this.buttons![entry.key] = s!.isEmpty ? null : s;
                                  });
                                },
                              )
                            ]))
                        .toList()
                        // new Text(
                        //     '${entry.key + 1}. ${entry.value ?? "(empty)"}'))
                        // .toList()
                        .cast<Widget>() ??
                    []),
            Padding(
                padding: EdgeInsets.all(15),
                child: ElevatedButton(
                  onPressed: () {
                    if (this.buttons == null) this.buttons = [];

                    setState(() {
                      this.buttons!.add(null);
                    });
                  },
                  child: Text("Add button"),
                )),
            Padding(
                padding: EdgeInsets.all(15),
                child: ElevatedButton(
                  onPressed: () {
                    this.saveCallback?.call(this.buttons ?? []);
                  },
                  child: Text("Save"),
                ))
          ]),
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
    );
  }
}
