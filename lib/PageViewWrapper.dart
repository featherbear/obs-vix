import 'package:flutter/material.dart';

class PageViewWrapper extends StatelessWidget {
  final Widget child;
  final String? title;
  const PageViewWrapper({required this.child, this.title, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          // Here we take the value from the MyHomePage object that was created by
          // the App.build method, and use it to set our appbar title.
          title: Text(this.title ?? ""),
        ),
        body: Center(
            // Center is a layout widget. It takes a single child and positions it
            // in the middle of the parent.
            child: this.child));
  }
}
