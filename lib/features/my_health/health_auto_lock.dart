import 'dart:async';

import 'package:flutter/widgets.dart';

import 'data/health_controller.dart';

/// Locks My Health again after the app has been in the background (H5).
///
/// Without this, a PIN unlocked My Health until the app was killed. A short
/// trip away, such as picking a file or checking the dialer, keeps it open.
/// Longer than [grace] and the PIN is needed again. Locking checks the time
/// on return as well as with a timer, because a phone can pause timers for
/// an app in the background.
class HealthAutoLock extends StatefulWidget {
  const HealthAutoLock({
    super.key,
    required this.controller,
    required this.child,
    this.grace = defaultGrace,
    this.clock = DateTime.now,
  });

  static const defaultGrace = Duration(seconds: 30);

  final HealthController controller;
  final Widget child;
  final Duration grace;
  final DateTime Function() clock;

  @override
  State<HealthAutoLock> createState() => _HealthAutoLockState();
}

class _HealthAutoLockState extends State<HealthAutoLock>
    with WidgetsBindingObserver {
  DateTime? _leftAt;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        if (_leftAt != null) return;
        _leftAt = widget.clock();
        _timer?.cancel();
        _timer = Timer(widget.grace, _lock);
      case AppLifecycleState.resumed:
        final left = _leftAt;
        _leftAt = null;
        _timer?.cancel();
        _timer = null;
        if (left != null && widget.clock().difference(left) >= widget.grace) {
          _lock();
        }
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
        break;
    }
  }

  void _lock() {
    _timer = null;
    widget.controller.lock();
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
