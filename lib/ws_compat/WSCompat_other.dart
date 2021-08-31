import 'package:web_socket_channel/web_socket_channel.dart';

abstract class WSCompatImplementation {
  static Future<WebSocketChannel> connect(Uri uri) async {
    throw "Not implemented";
  }
}
