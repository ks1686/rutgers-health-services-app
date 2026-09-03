import 'package:flutter/widgets.dart';

import 'data/health_controller.dart';

/// Provides [HealthController] to My Health, Wallet, and More (Erase).
class HealthScope extends InheritedNotifier<HealthController> {
  const HealthScope({
    super.key,
    required HealthController controller,
    required super.child,
  }) : super(notifier: controller);

  static HealthController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HealthScope>();
    assert(scope != null, 'HealthScope not found');
    return scope!.notifier!;
  }

  static HealthController? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<HealthScope>()?.notifier;
  }
}
