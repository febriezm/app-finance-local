import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/app_providers.dart';
import 'app_lock_screen.dart';

class AppLockListener extends ConsumerStatefulWidget {
  final Widget child;

  const AppLockListener({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<AppLockListener> createState() => _AppLockListenerState();
}

class _AppLockListenerState extends ConsumerState<AppLockListener> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final notifier = ref.read(appLockControllerProvider.notifier);
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.inactive) {
      notifier.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      notifier.onAppResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    final lockState = ref.watch(appLockControllerProvider);

    if (lockState.isAppLockEnabled && !lockState.isUnlocked) {
      return const AppLockScreen();
    }

    return widget.child;
  }
}
