import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/my_health/data/health_launchers.dart';

void main() {
  test('portal requires http(s)', () {
    expect(healthPortalUri('https://clinic.example/portal')?.scheme, 'https');
    expect(healthPortalUri('http://clinic.example/portal')?.scheme, 'http');
    expect(healthPortalUri('ftp://bad'), isNull);
    expect(healthPortalUri('not a url'), isNull);
    expect(healthPortalUri(null), isNull);
    expect(healthPortalUri(''), isNull);
  });
}
