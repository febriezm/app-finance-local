import 'package:flutter/material.dart';

class AppLifecycleObserver with WidgetsBindingObserver {
  final void Function(AppLifecycleState state)? onStateChanged;

  AppLifecycleObserver({this.onStateChanged});

  void start() {
    WidgetsBinding.instance.addObserver(this);
  }

  void stop() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    onStateChanged?.call(state);
  }
}
