import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:obs_vix/settings/connection/data.dart';

class SettingsConnection extends StatefulWidget {
  final void Function(ConnectionSettings settings)? saveCallback;

  SettingsConnection({Key? key, this.saveCallback}) : super(key: key);
  @override
  _SettingsConnectionState createState() =>
      new _SettingsConnectionState(saveCallback: saveCallback);
}

class _SettingsConnectionState extends State<SettingsConnection> {
  final void Function(ConnectionSettings settings)? saveCallback;

  _SettingsConnectionState({this.saveCallback});

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
            new ElevatedButton(
              onPressed: () {
                this.saveCallback?.call(new ConnectionSettings(
                    host: hostnameController.text,
                    port: int.tryParse(portController.text) ?? 1,
                    password: passwordController.text));
              },
              child: null,
            )
          ]),
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
    );
  }
}
