import 'package:obs_vix/NBox_funcs.dart';

abstract class VIXUtils {
  static String processLabel(String? s) {
    if (s == null) return "";
    if (s.isEmpty) return "(none)";

    if (s.startsWith(NBOX_SWITCHER_PREFIX)) return "Box ${s.substring(NBOX_SWITCHER_PREFIX.length)}";
    if (s.startsWith(NBOX_PREFIX)) return "${s.substring(NBOX_PREFIX.length)}-box";
    return s;
  }
}
