import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/my_health/data/health_launchers.dart';

void main() {
  test('tel strips non-digits', () {
    expect(
      healthTelUri('(732) 555-0198'),
      Uri(scheme: 'tel', path: '7325550198'),
    );
  });

  test('sms strips non-digits', () {
    expect(
      healthSmsUri('(732) 555-0198'),
      Uri(scheme: 'sms', path: '7325550198'),
    );
  });

  test('portal requires http(s)', () {
    expect(healthPortalUri('https://clinic.example/portal')?.scheme, 'https');
    expect(healthPortalUri('http://clinic.example/portal')?.scheme, 'http');
    expect(healthPortalUri('ftp://bad'), isNull);
    expect(healthPortalUri('not a url'), isNull);
    expect(healthPortalUri(null), isNull);
    expect(healthPortalUri(''), isNull);
  });
}
