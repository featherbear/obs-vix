import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_vix/VIXState.dart';

typedef SceneOrder = List<String?>;
typedef CallbackType = void Function(SceneOrder);

class SettingsAssignmentView extends StatefulWidget {
  final CallbackType? saveCallback;

  SettingsAssignmentView({Key? key, this.saveCallback}) : super(key: key);
  @override
  _SettingsAssignmentViewState createState() =>
      new _SettingsAssignmentViewState(saveCallback: saveCallback);
}

class _SettingsAssignmentViewState extends State<SettingsAssignmentView> {
  final CallbackType? saveCallback;
  SceneOrder? buttons;

  _SettingsAssignmentViewState({this.saveCallback, this.buttons});

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    return new Container(
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new Column(
                children: this
                        .buttons
                        ?.asMap()
                        .entries
                        .map((entry) => new Row(children: [
                              new Text('Button ${entry.key + 1} = '),
                              new DropdownButton(
                                value: entry.value,
                                hint: Text("Select scene"),
                                items: ['', ...(VIX["scenes"] ?? [])]
                                    .cast<String>()
                                    .map((e) {
                                  return DropdownMenuItem(
                                      value: e,
                                      child: Text(e.isNotEmpty ? e : "(none)"));
                                }).toList(),
                                onChanged: (String? s) {
                                  setState(() {
                                    this.buttons![entry.key] =
                                        s!.isEmpty ? null : s;
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
            new ElevatedButton(
              onPressed: () {
                if (this.buttons == null) this.buttons = [];

                setState(() {
                  this.buttons!.add(null);
                });
              },
              child: new Text("Add button"),
            ),
            new ElevatedButton(
              onPressed: () {
                this.saveCallback?.call(this.buttons ?? []);
              },
              child: new Text("Save"),
            )
          ]),
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
    );
  }
}
