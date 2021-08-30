import 'package:flutter/widgets.dart';

typedef VIXStateData = Map;

VIXStateData _data = new Map();
int lastItem = 0;

class VIXState extends InheritedWidget {
  Map get data => _data;
  final int version;

  VIXState({required Widget child, required this.version, Key? key})
      : super(child: child, key: key);

  static VIXState? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<VIXState>();
  }

  @override
  bool updateShouldNotify(VIXState old) {
    return this.version != old.version;
  }
}

class _VIXStateProvider extends StatefulWidget {
  static VIXState of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<VIXState>()!;

  const _VIXStateProvider({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  _VIXStateProviderState createState() => _VIXStateProviderState();
}

class _VIXStateProviderState extends State<_VIXStateProvider> {
  int _count = lastItem;
  _VIXStateProviderState() {
    _stateUpdaters.add(() {
      if (!this.mounted) return false;
      setState(() {
        _count = lastItem;
      });
      return true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VIXState(child: widget.child, version: _count);
  }
}

Widget provideVIXState(Widget widget, {Key? key}) {
  return _VIXStateProvider(
    child: widget,
    key: key,
  );
}

List<bool Function()> _stateUpdaters = [];

void updateVIXState(void Function(Map) fn) {
  fn(_data);
  lastItem++;
  _stateUpdaters.retainWhere((cb) => cb());
}

VIXStateData readVIXState() => _data;
VIXStateData getVIXState(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<VIXState>()!.data;
