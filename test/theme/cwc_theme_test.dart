import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/theme/cwc_theme.dart';

void main() {
  test('theme body is at least 18', () {
    final theme = buildCwcTheme();
    expect(theme.textTheme.bodyMedium!.fontSize! >= 18, isTrue);
    expect(theme.textTheme.bodyLarge!.fontSize! >= 18, isTrue);
    expect(theme.textTheme.bodySmall!.fontSize! >= 18, isTrue);
  });
}
