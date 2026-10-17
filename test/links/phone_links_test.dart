import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/links/phone_links.dart';

void main() {
  test('digits keep only 0-9', () {
    expect(phoneDigitsOnly('+1 (732) 555-0198'), '17325550198');
  });

  test('tel strips non-digits', () {
    expect(
      phoneTelUri('(732) 555-0198'),
      Uri(scheme: 'tel', path: '7325550198'),
    );
  });

  test('sms strips non-digits', () {
    expect(
      phoneSmsUri('+1-732-555-0142'),
      Uri(scheme: 'sms', path: '17325550142'),
    );
  });
}
