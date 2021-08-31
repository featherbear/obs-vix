import 'package:web_socket_channel/web_socket_channel.dart';

import 'WSCompat_other.dart'
    if (dart.library.io) 'WSCompat_io.dart'
    if (dart.library.html) 'WSCompat_web.dart';

abstract class WSCompat {
  static Future<WebSocketChannel> connect(Uri uri) async {
    return WSCompatImplementation.connect(uri);
  }
}
