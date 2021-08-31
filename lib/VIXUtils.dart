abstract class VIXUtils {
  static String processLabel(String? s) {
    if (s == null) return "";
    if (s.isEmpty) return "(none)";

    const String nboxPrefix = "vix::nbox::";
    if (s.startsWith(nboxPrefix)) return "${s.substring(nboxPrefix.length)}-box";
    return s;
  }
}
