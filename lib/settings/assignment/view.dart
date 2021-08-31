import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:obs_vix/VIXState.dart';
import 'package:obs_vix/VIXUtils.dart';
import 'package:obs_vix/settings/assignment/data.dart';
import 'package:flutter_number_picker/flutter_number_picker.dart';

typedef CallbackType = void Function(AssignmentSettings);

class SettingsAssignmentView extends StatefulWidget {
  final CallbackType? saveCallback;
  final AssignmentSettings? prefill;

  SettingsAssignmentView({Key? key, this.saveCallback, this.prefill}) : super(key: key);

  @override
  _SettingsAssignmentViewState createState() => _SettingsAssignmentViewState(
      saveCallback: this.saveCallback, data: AssignmentSettings(buttons: SceneOrder.from(prefill?.buttons ?? []), nBoxes: prefill?.nBoxes ?? 0));
}

class _SettingsAssignmentViewState extends State<SettingsAssignmentView> {
  final CallbackType? saveCallback;
  final AssignmentSettings data;
  late bool isNboxEnabled;

  _SettingsAssignmentViewState({this.saveCallback, required this.data}) {
    this.isNboxEnabled = this.data.nBoxes > 0;
  }

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);

    // Get scenes, and merge with previously selected scenes (that may no longer exist)
    List sceneList = [...VIX["scenes"] ?? [], ...data.buttons.where((s) => s != null)].toSet().toList();
    sceneList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    List<Widget> _headSub(String head, String sub) => [Text(head, style: TextStyle(fontSize: 24)), Text(sub, style: TextStyle(color: Colors.grey))];

    List<Widget> generateButtonAssignment() => [
          ..._headSub("Button Assignment", "Manage scene button assignments"),
          Column(
              children: this
                  .data
                  .buttons
                  .asMap()
                  .entries
                  .map((entry) => Row(children: [
                        Text('Button ${entry.key + 1} = '),
                        DropdownButton(
                          value: entry.value,
                          hint: Text("Select scene"),
                          items: ['', ...sceneList].cast<String>().map((e) {
                            return DropdownMenuItem(value: e, child: Text(VIXUtils.processLabel(e)));
                          }).toList(),
                          onChanged: (String? s) {
                            setState(() {
                              this.data.buttons[entry.key] = s!.isEmpty ? null : s;
                            });
                          },
                        ),
                        IconButton(
                            onPressed: () {
                              setState(() {
                                this.data.buttons.removeAt(entry.key);
                              });
                            },
                            splashRadius: 20,
                            icon: Icon(Icons.delete))
                      ]))
                  .toList()
                  .cast<Widget>()),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    this.data.buttons.add(null);
                  });
                },
                child: Text("Add button"),
              ))
        ];

    List<Widget> generateNBoxAssignments() {
      return [
        ..._headSub("n-box", "Configure n-box options"),
        Row(children: [
          Text("Enable n-box"),
          Switch(
              value: isNboxEnabled,
              onChanged: (bool? state) {
                if (state == null) return;
                setState(() => isNboxEnabled = state);
              }),
        ]),
        ...(!isNboxEnabled
            ? []
            : [
                Row(
                  children: [
                    Text("n-boxes"),
                    CustomNumberPicker(
                        onValue: (value) {
                          data.nBoxes = value as int;
                        },
                        initialValue: data.nBoxes,
                        maxValue: 8,
                        minValue: 0,
                        step: 1)
                  ],
                )
                // ElevatedButton(onPressed: (){}, child: Text("Initialise"))
              ])
      ];
    }

    return Container(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
        ...generateButtonAssignment(),
        ...generateNBoxAssignments(),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: ElevatedButton(
              onPressed: () =>
                  this.saveCallback?.call(AssignmentSettings(buttons: this.data.buttons, nBoxes: this.isNboxEnabled ? this.data.nBoxes : 0)),
              child: Text("Save"),
            ))
      ]),
      padding: EdgeInsets.symmetric(vertical: 15),
    );
  }
}
