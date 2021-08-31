import 'dart:html'; // ignore: avoid_web_libraries_in_flutter
import 'package:web_socket_channel/html.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

abstract class WSCompatImplementation {
  static Future<WebSocketChannel> connect(Uri uri) async {
    return HtmlWebSocketChannel(WebSocket(uri.toString()));
  }
}
