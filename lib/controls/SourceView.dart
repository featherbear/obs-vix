import 'dart:async';
import 'dart:developer';

import 'package:flutter/widgets.dart';
import 'package:obs_vix/OBSClient.dart';
import 'package:obs_vix/VIXState.dart';

class SourceView extends StatefulWidget {
  late _SourceViewState child;

  SourceView({Key? key}) {
    child = _SourceViewState(this);
  }

  OBSClient? client;
  String? sourceName;

  void init(OBSClient client, {String? sourceName}) {
    this.client = client;
    this.sourceName = sourceName;
    this.child.notify();
  }

  void updateSource(String sourceName) {
    this.sourceName = sourceName;
    this.child.notify();
  }

  @override
  _SourceViewState createState() => child;
}

class _SourceViewState extends State<SourceView> {
  final SourceView parent;

  _SourceViewState(this.parent);

  Image? _image;
  Timer? _timer;

  _stop() {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
      _timer = null;
    }
  }

  _requestUpdate() {
    _stop();
    this.parent.client!.request(command: "TakeSourceScreenshot", params: {"sourceName": parent.sourceName, "embedPictureFormat": "jpg"}).then((r) {
      if (!this.mounted) return _stop();

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
    _stop();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _requestUpdate();
    });
  }

  notify() {
    if (this.parent.client == null || this.parent.sourceName == null) return;
    _requestUpdate();
  }

  @override
  void dispose() {
    _stop();
  }

  @override
  Widget build(BuildContext context) {
    return Container(child: this._image ?? null);
  }
}
