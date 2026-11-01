import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hides sensitive UI from app-switcher / screenshots (PRIV-4).
///
/// Android: FLAG_SECURE while My Health is open. iOS: this channel is a
/// no-op; instead AppDelegate.swift (AppSwitcherCover) covers every screen
/// with a plain view whenever the app stops being active, so the app switcher
/// snapshot shows nothing personal.
class PreviewProtection {
  PreviewProtection._();

  static const _channel = MethodChannel(
    'org.rutgers.cwc.cwc_health_app/preview_protection',
  );

  static bool _enabled = false;

  static bool get isEnabled => _enabled;

  /// Injected in tests — skips the platform channel.
  static Future<void> Function(bool enabled)? debugOverride;

  @visibleForTesting
  static void debugReset() {
    _enabled = false;
    debugOverride = null;
  }

  static Future<void> setSecure(bool enabled) async {
    if (_enabled == enabled) return;
    _enabled = enabled;
    final override = debugOverride;
    if (override != null) {
      await override(enabled);
      return;
    }
    if (kIsWeb) return;
    try {
      await _channel.invokeMethod<void>('setSecure', {'enabled': enabled});
    } on MissingPluginException {
      // Desktop/test hosts without the channel — ignore.
    } on PlatformException {
      // Best-effort privacy aid; do not crash My Health.
    }
  }
}
