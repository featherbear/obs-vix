import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsConnection extends StatefulWidget {
  SettingsConnection({Key? key}) : super(key: key);
  @override
  _SettingsConnectionState createState() => new _SettingsConnectionState();
}

class _SettingsConnectionState extends State<SettingsConnection> {
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
                decoration: InputDecoration(
                  labelText: "Hostname / IP Address",
                )),
            new TextFormField(
              enableSuggestions: false,
              autocorrect: false,
              keyboardType: TextInputType.number,
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
            )
          ]),
      padding: const EdgeInsets.all(0.0),
      alignment: Alignment.center,
    );
  }
}
