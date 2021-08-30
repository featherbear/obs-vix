import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_vix/settings/connection/data.dart';

class SettingsConnectionView extends StatefulWidget {
  final void Function(ConnectionSettings settings)? saveCallback;
  final ConnectionSettings? prefill;

  SettingsConnectionView({Key? key, this.prefill, this.saveCallback})
      : super(key: key);
  @override
  _SettingsConnectionViewState createState() =>
      new _SettingsConnectionViewState(
          prefill: this.prefill, saveCallback: saveCallback);
}

class _SettingsConnectionViewState extends State<SettingsConnectionView> {
  final void Function(ConnectionSettings settings)? saveCallback;
  final ConnectionSettings? prefill;

  _SettingsConnectionViewState({this.prefill, this.saveCallback}) {
    if (this.prefill == null) return;
    hostnameController.text = this.prefill!.host;
    portController.text = this.prefill!.port.toString();
    passwordController.text = this.prefill!.password?.toString() ?? "";
  }

  var hostnameController = TextEditingController();
  var portController = TextEditingController();
  var passwordController = TextEditingController();

  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return new Container(
      child: new Column(
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            new TextField(
                enableSuggestions: false,
                autocorrect: false,
                controller: hostnameController,
                decoration: InputDecoration(
                  labelText: "Hostname / IP Address",
                )),
            new TextFormField(
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.number,
              controller: portController,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5)
              ],
              decoration: InputDecoration(labelText: 'Port'),
              autovalidateMode: AutovalidateMode.onUserInteraction,
              validator: (String? s) {
                const errMsg = "Enter a port between 1 and 65535";
                if (s == null) return errMsg;
                var value = int.tryParse(s);
                if (value == null) return errMsg;
                if (!(1 <= value && value <= 65535)) return errMsg;
                return null;
              },
            ),
            new TextField(
              obscureText: _isObscure,
              enableSuggestions: false,
              autocorrect: false,
              controller: passwordController,
              decoration: InputDecoration(
                  labelText: 'Password',
                  suffixIcon: IconButton(
                      icon: Icon(
                          _isObscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      })),
            ),
            new Padding(
                padding: EdgeInsets.all(15),
                child: new ElevatedButton(
                  onPressed: () {
                    // TODO: Validation

                    this.saveCallback?.call(new ConnectionSettings(
                        host: hostnameController.text,
                        port: int.tryParse(portController.text) ?? 4444,
                        password: passwordController.text));
                  },
                  child: new Text("Save"),
                ))
          ]),
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
    );
  }
}
