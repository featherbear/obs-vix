import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:obs_vix/settings/connection/data.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

const uuid = Uuid();
const mIDprefix = "obs-vix::";
String B64_SHA256(String a, String b) => base64Encode(sha256.convert(utf8.encode(a + b)).bytes);

typedef ConnectCallbackFunction = Function(OBSClient data);
typedef RawCallbackFunction = Function(String data);
typedef CallbackFunction = Function(dynamic data);

class AuthException implements Exception {
  final dynamic message;
  AuthException([this.message]);
  String toString() => "AuthException: ${this.message}";
}

class ConnectionException implements Exception {
  final dynamic message;
  ConnectionException([this.message]);
  String toString() => "ConnectionException: ${this.message}";
}

class OBSClient {
  WebSocketChannel? _channel;
  dynamic _serverCapabilities;
  late Map<String, Completer> _messageMap;
  late String _prefix;
  Uri? _uri;
  Uri? get uri => _uri;
  bool get isConnected => _channel == null ? false : _channel!.closeCode != null;

  /// Raw callbacks - these do not reset between sessions of the same instance
  List<RawCallbackFunction> _rawCallbacks = [];
  List<RawCallbackFunction> _rawCallbacksSnoop = [];

  ConnectCallbackFunction? _connectCallback;
  Map<String, List<CallbackFunction>> _callbacks = new Map();

  void close() {
    _channel?.sink.close();
  }

  void _init() {
    _channel = null;
    this._serverCapabilities = null;
    _messageMap = new Map();
    _prefix = '$mIDprefix${uuid.v4().substring(0, 8)}::';
  }

  void setConnectCallback(ConnectCallbackFunction cb) {
    this._connectCallback = cb;
  }

  Future<OBSClient> _connect(Uri uri, {String? password}) async {
    this.close();
    this._init();

    _uri = uri;
    _channel = IOWebSocketChannel(await WebSocket.connect(_uri.toString(), headers: {"User-Agent": "obs-vix"}));
    _channel!.stream.listen((event) {
      _alertRawListeners(event, snoop: true);

      var obj = jsonDecode(event);
      if (obj['message-id'] == null) {
        // Event
        _alertListener(obj["update-type"], obj);
        _alertRawListeners(event);
      } else {
        // Request
        if (!(obj['message-id'] as String).startsWith(_prefix)) return;

        String id = (obj['message-id'] as String).substring(_prefix.length);
        if (_messageMap.containsKey(id)) {
          Completer c = _messageMap[id]!;
          _messageMap.remove(id);
          c.complete(obj);
        }

        _alertRawListeners(event);
      }
    });

    this.request(command: "GetVersion").then((r) {
      // Only update the first time
      if (_serverCapabilities != null) return;

      _serverCapabilities = r;
    });

    return this.request(command: "GetAuthRequired").then((r) async {
      if (!r["authRequired"]) return this;
      String challenge = r['challenge'];
      String salt = r['salt'];
      if (password == null) throw AuthException("Password required");
      String chalResponse = B64_SHA256(B64_SHA256(password, salt), challenge);

      var response = await this.request(command: "Authenticate", params: {"auth": chalResponse});
      if (response["status"] != 'ok') throw AuthException(response["error"]);
      return this;
    }).then((client) {
      log("OBS client connected to ${this.uri.toString()}");
      Future.sync(() => this._connectCallback?.call(client));
      return this;
    });
  }

  dynamic get serverCapabilities => this._serverCapabilities;

  Future<OBSClient> connect({required String host, required int port, String? password}) {
    Uri? uri = Uri.tryParse('ws://$host:$port');
    if (uri == null) throw Exception("Invalid URI");
    return this._connect(uri, password: password);
  }

  Future<OBSClient> connectURI(Uri uri, {String? password}) {
    return this._connect(uri, password: password);
  }

  Future<OBSClient> connectObject(ConnectionSettings settings) {
    return this.connect(host: settings.host, port: settings.port, password: settings.password);
  }

  void addEventListener(String eventName, CallbackFunction callback) {
    if (!_callbacks.containsKey(eventName)) _callbacks[eventName] = [];
    if (_callbacks[eventName]!.contains(callback)) return;
    _callbacks[eventName]!.add(callback);
  }

  void removeEventListener(String eventName, CallbackFunction callback) {
    if (!_callbacks.containsKey(eventName)) return;
    _callbacks[eventName]!.remove(callback);
  }

  void addRawListener(RawCallbackFunction callback, {bool snoop = false}) {
    if (_rawCallbacks.contains(callback) || _rawCallbacksSnoop.contains(callback)) {
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

  void _alertListener(String eventName, dynamic data) {
    if (!_callbacks.containsKey(eventName)) return;
    _callbacks[eventName]!.forEach((fn) => fn(data));
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

  Future<dynamic> request({required String command, Map? params, Function(dynamic)? callback}) async {
    var id = uuid.v4();
    Map data = (params != null) ? Map.from(params) : new Map();

    data['request-type'] = command;
    data['message-id'] = _prefix + id;

    this.sendRaw(jsonEncode(data));

    var future = (_messageMap[id] = new Completer()).future;
    return (callback == null) ? future : future.then(callback);
  }
}
