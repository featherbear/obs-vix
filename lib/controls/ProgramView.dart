import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXState.dart';

class ProgramView extends StatefulWidget {
  final OBSClient client;
  const ProgramView(this.client, {Key? key}) : super(key: key);

  @override
  _ProgramViewState createState() => _ProgramViewState(this.client);
}

class _ProgramViewState extends State<ProgramView> {
  final OBSClient client;
  String? source;
  Image? _image;
  Timer? _timer;

  _requestUpdate() {
    this.client.request(command: "TakeSourceScreenshot", params: {"embedPictureFormat": "jpg"}).then((r) {
      setState(() {
        this._image = Image.memory(
          UriData.parse(r["img"]).contentAsBytes(),
          gaplessPlayback: true,
        );
      });

      _restartTimer();
    });
  }

  _restartTimer() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _requestUpdate();
    });
  }

  _ProgramViewState(this.client);

  @override
  Widget build(BuildContext context) {
    final VIX = getVIXState(context);
    if (source != VIX["activeProgram"]) {
      source = VIX["activeProgram"];
      _requestUpdate();
    }

    return Container(child: this._image ?? null);
  }
}
