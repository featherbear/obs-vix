import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class WSCompatImplementation {
  static Future<WebSocketChannel> connect(Uri uri) async {
    return IOWebSocketChannel(await WebSocket.connect(uri.toString(), headers: {"User-Agent": "obs-vix"}));
  }
}
