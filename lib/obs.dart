import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:uuid/uuid.dart';
import 'package:obs_vix/settings/connection/data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const uuid = Uuid();
const mIDprefix = "obs-vix::";
String uuidv4() => uuid.v4();

typedef RawCallbackFunction = Function(String data);

class OBSInstance {
  WebSocketChannel? _channel;
  dynamic _serverCapabilities;
  late Map<String, Completer> _messageMap;
  late String _prefix;

  /// Raw callbacks - these do not reset between sessions of the same instance
  List<RawCallbackFunction> _rawCallbacks = [];
  List<RawCallbackFunction> _rawCallbacksSnoop = [];

  void close() {
    _channel?.sink.close();
  }

  void _init() {
    _channel = null;
    this._serverCapabilities = null;
    _messageMap = new Map();
    _prefix = '$mIDprefix${uuidv4().substring(0, 8)}::';
  }

  void _connect(Uri uri) {
    this.close();
    this._init();

    _channel = WebSocketChannel.connect(uri);

    _channel!.stream.listen((event) {
      // log(event);
      _alertRawListeners(event, snoop: true);

      var obj = jsonDecode(event);
      if (obj['message-id'] == null) {
        // Event
        _alertRawListeners(event);
      } else {
        // Request

        if (!(obj['message-id'] as String).startsWith(_prefix)) return;
        _alertRawListeners(event);

        String id = (obj['message-id'] as String).substring(_prefix.length);
        if (_messageMap.containsKey(id)) {
          Completer c = _messageMap[id]!;
          _messageMap.remove(id);
          c.complete(obj);
        }
      }
    });

    this.request(command: "GetVersion");

    log("Connected");
  }

  void connect({required String host, required int port, String? password}) {
    Uri? uri = Uri.tryParse('ws://$host:$port');
    if (uri == null) throw Exception("Invalid URI");
    this._connect(uri);
  }

  void connectURI(Uri uri) {
    this._connect(uri);
  }

  void connectObject(ConnectionSettings settings) {
    this.connect(
        host: settings.host, port: settings.port, password: settings.password);
  }

  void addRawListener(RawCallbackFunction callback, {bool snoop = false}) {
    if (_rawCallbacks.contains(callback) ||
        _rawCallbacksSnoop.contains(callback)) {
      return;
    }
    if (snoop) {
      _rawCallbacksSnoop.add(callback);
    } else {
      _rawCallbacks.add(callback);
    }
  }

  void removeRawListener(RawCallbackFunction callback) {
    _rawCallbacks.remove(callback);
    _rawCallbacksSnoop.remove(callback);
  }

  void _alertRawListeners(String data, {bool snoop = false}) {
    if (snoop) {
      _rawCallbacksSnoop.forEach((fn) => fn(data));
    } else {
      _rawCallbacks.forEach((fn) => fn(data));
    }
  }

  void sendRaw(String s) {
    _channel?.sink.add(s);
  }

  Future<dynamic> request(
      {required String command,
      Map? options,
      Function(dynamic)? callback}) async {
    var id = uuidv4();
    Map data = (options != null) ? Map.from(options) : new Map();

    data['request-type'] = command;
    data['message-id'] = _prefix + id;

    this.sendRaw(jsonEncode(data));

    var future = (_messageMap[id] = new Completer()).future;
    return (callback == null) ? future : future.then(callback);
  }
}
