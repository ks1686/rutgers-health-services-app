import 'package:flutter/widgets.dart';

/// Every route that shows My Health has a name that starts with this, so
/// auto-lock can close those and leave Help Now and the rest open.
const kMyHealthRoutePrefix = 'my-health';

/// Settings for a My Health route, such as `my-health/form`.
RouteSettings myHealthRoute(String name) =>
    RouteSettings(name: '$kMyHealthRoutePrefix/$name');

bool isMyHealthRouteName(String? name) =>
    name != null && name.startsWith(kMyHealthRoutePrefix);

/// Keeps the app's route stack so auto-lock can remove only My Health
/// screens.
///
/// A route counts as My Health when its name starts with
/// [kMyHealthRoutePrefix], or when it is a dialog, picker, or sheet opened
/// straight over a My Health route, such as a delete confirmation over a
/// form. A dialog opened from Help Now stays with Help Now.
class HealthRouteObserver extends NavigatorObserver {
  final List<Route<dynamic>> _stack = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final at = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute == null) {
      if (at >= 0) _stack.removeAt(at);
    } else if (at >= 0) {
      _stack[at] = newRoute;
    } else {
      _stack.add(newRoute);
    }
  }

  /// My Health routes on the stack, bottom first.
  List<Route<dynamic>> get healthRoutes {
    final found = <Route<dynamic>>[];
    var belowIsHealth = false;
    for (final route in _stack) {
      final health =
          isMyHealthRouteName(route.settings.name) ||
          (route is PopupRoute && belowIsHealth);
      if (health) found.add(route);
      belowIsHealth = health;
    }
    return found;
  }

  /// Removes every My Health route, top first, and leaves the others.
  void closeHealthRoutes() {
    for (final route in healthRoutes.reversed) {
      if (route.isActive) route.navigator?.removeRoute(route);
    }
  }
}
