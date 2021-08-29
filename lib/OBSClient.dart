import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:obs_vix/settings/connection/data.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const uuid = Uuid();
const mIDprefix = "obs-vix::";
String B64_SHA256(String a, String b) =>
    base64Encode(sha256.convert(utf8.encode(a + b)).bytes);

typedef RawCallbackFunction = Function(String data);

class AuthException implements Exception {
  final dynamic message;
  AuthException([this.message]);
  String toString() => "AuthException: ${this.message}";
}

class OBSClient {
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
    _prefix = '$mIDprefix${uuid.v4().substring(0, 8)}::';
  }

  Future<void> _connect(Uri uri, {String? password}) {
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
        // TODO:
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

    this.request(command: "GetVersion").then((r) {
      // Only update the first time
      if (_serverCapabilities != null) return;

      _serverCapabilities = r;
    });

    return this.request(command: "GetAuthRequired").then((r) async {
      if (!r["authRequired"]) return;
      String challenge = r['challenge'];
      String salt = r['salt'];
      if (password == null) throw AuthException("Password required");
      String chalResponse = B64_SHA256(B64_SHA256(password, salt), challenge);

      var response = await this
          .request(command: "Authenticate", params: {"auth": chalResponse});
      if (response["status"] != 'ok') throw AuthException(response["error"]);
      return;
    });
  }

  dynamic get serverCapabilities => this._serverCapabilities;

  Future<void> connect(
      {required String host, required int port, String? password}) {
    Uri? uri = Uri.tryParse('ws://$host:$port');
    if (uri == null) throw Exception("Invalid URI");
    return this._connect(uri, password: password);
  }

  Future<void> connectURI(Uri uri, {String? password}) {
    return this._connect(uri, password: password);
  }

  Future<void> connectObject(ConnectionSettings settings) {
    return this.connect(
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
      Map? params,
      Function(dynamic)? callback}) async {
    var id = uuid.v4();
    Map data = (params != null) ? Map.from(params) : new Map();

    data['request-type'] = command;
    data['message-id'] = _prefix + id;

    this.sendRaw(jsonEncode(data));

    var future = (_messageMap[id] = new Completer()).future;
    return (callback == null) ? future : future.then(callback);
  }
}
