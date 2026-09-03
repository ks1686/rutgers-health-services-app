import 'package:cwc_health_app/platform/preview_protection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(PreviewProtection.debugReset);

  test('setSecure toggles and skips duplicate calls', () async {
    final calls = <bool>[];
    PreviewProtection.debugOverride = (enabled) async {
      calls.add(enabled);
    };

    await PreviewProtection.setSecure(true);
    await PreviewProtection.setSecure(true);
    await PreviewProtection.setSecure(false);

    expect(calls, [true, false]);
    expect(PreviewProtection.isEnabled, isFalse);
  });
}
