import 'dart:io';

import 'package:cwc_health_app/features/help_now/help_now_actions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> labels({bool showUnconfirmedRows = false}) => [
    for (final action in helpNowActions(
      showUnconfirmedRows: showUnconfirmedRows,
    ))
      action.label,
  ];

  test('911 is first; 988 follows; other helplines after', () {
    final rows = labels();
    expect(rows.first, '911 Emergency');
    expect(rows.indexOf('911 Emergency'), lessThan(rows.indexOf('Call 988')));
    expect(rows.indexOf('Call 988'), lessThan(rows.indexOf('Poison Control')));
  });

  test('ReachNJ and Self-Help Group Clearinghouse are listed after 988', () {
    final rows = labels();
    expect(rows, contains('ReachNJ'));
    expect(rows, contains('NJ Self-Help Group Clearinghouse'));
    expect(rows.indexOf('Call 988'), lessThan(rows.indexOf('ReachNJ')));
    expect(
      rows.indexOf('ReachNJ'),
      lessThan(rows.indexOf('NJ Self-Help Group Clearinghouse')),
    );
  });

  test('Poison Control copy says when to use it vs 911', () {
    final poison = helpNowActions(
      showUnconfirmedRows: false,
    ).singleWhere((a) => a.label == 'Poison Control');
    expect(poison.detail.toLowerCase(), contains('swallowed'));
    expect(poison.detail.toLowerCase(), contains('911'));
  });

  test('911 is emergency-styled; other lines are not', () {
    final actions = helpNowActions(showUnconfirmedRows: false);
    final nineOneOne = actions.singleWhere((a) => a.label == '911 Emergency');
    expect(nineOneOne.style, HelpNowStyle.emergencyFilled);
    expect(nineOneOne.section, HelpNowSection.emergency);
    expect(
      actions
          .where((a) => a.section == HelpNowSection.emergency)
          .map((a) => a.label),
      ['911 Emergency'],
    );
  });

  group('unconfirmed rows are held back until CSPNJ confirms them', () {
    test('warmline and wellness center are hidden by default', () {
      final rows = labels();
      expect(rows, isNot(contains('NJ Peer Warmline')));
      expect(rows, isNot(contains('My Wellness Center')));
      // Nothing shipped may carry a 555 placeholder number.
      for (final action in helpNowActions(showUnconfirmedRows: false)) {
        expect(action.detail, isNot(contains('555')));
      }
    });

    test('they are still available behind the flag, without a dialer URI', () {
      final rows = labels(showUnconfirmedRows: true);
      expect(rows, contains('NJ Peer Warmline'));
      expect(rows, contains('My Wellness Center'));
      for (final action in helpNowActions(showUnconfirmedRows: true)) {
        if (action.label != 'NJ Peer Warmline' &&
            action.label != 'My Wellness Center') {
          continue;
        }
        // A tap must not be able to dial a number nobody has verified.
        expect(action.callUri, isNull);
        expect(action.textUri, isNull);
        expect(action.detail.toLowerCase(), contains('sample'));
      }
    });
  });

  group('every shipped row dials with tel: and never auto-places a call', () {
    test('confirmed rows carry a tel: or sms: URI', () {
      final actions = helpNowActions(showUnconfirmedRows: false);
      for (final action in actions) {
        expect(
          action.callUri ?? action.textUri,
          isNotNull,
          reason: '${action.label} has no dialer URI',
        );
      }

      HelpNowAction call(String label) =>
          actions.singleWhere((a) => a.label == label);

      expect(call('911 Emergency').callUri, Uri(scheme: 'tel', path: '911'));
      expect(call('Call 988').callUri, Uri(scheme: 'tel', path: '988'));
      expect(call('Text 988').textUri, Uri(scheme: 'sms', path: '988'));
      expect(
        call('Poison Control').callUri,
        Uri(scheme: 'tel', path: '18002221222'),
      );
      expect(call('ReachNJ').callUri, Uri(scheme: 'tel', path: '18447322465'));
      expect(
        call('NJ Self-Help Group Clearinghouse').callUri,
        Uri(scheme: 'tel', path: '18003676274'),
      );
    });

    test('no row uses a tel: URI that could bypass the dialer', () {
      // `tel:` is ACTION_DIAL on Android: the number is filled in and the
      // person presses call. Nothing in the app may request CALL_PHONE, which
      // would allow ACTION_CALL and a silently placed call.
      for (final action in helpNowActions(showUnconfirmedRows: true)) {
        for (final uri in [action.callUri, action.textUri]) {
          if (uri == null) continue;
          expect(
            uri.scheme,
            anyOf('tel', 'sms'),
            reason: '${action.label} uses an unexpected scheme ${uri.scheme}',
          );
          // No query tricks that could be smuggled through.
          expect(uri.query, isEmpty, reason: action.label);
        }
      }
    });

    test('the Android manifest does not request CALL_PHONE', () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      expect(
        manifest,
        isNot(contains('android.permission.CALL_PHONE')),
        reason:
            'ACTION_DIAL needs no permission. CALL_PHONE would allow the app '
            'to place a call without the person confirming.',
      );
      // It must still be able to resolve a tel: intent on Android 11+.
      expect(manifest, contains('android.intent.action.DIAL'));
      expect(manifest, contains('android:scheme="tel"'));
      expect(manifest, contains('android.permission.USE_BIOMETRIC'));
      expect(manifest, isNot(contains('USE_FINGERPRINT')));
    });

    test('no help-now source file carries a placeholder 555 number', () {
      for (final path in [
        'lib/features/help_now/help_now_actions.dart',
        'lib/features/help_now/help_now_screen.dart',
      ]) {
        expect(
          File(path).readAsStringSync(),
          isNot(contains('555-')),
          reason: '$path still holds a 555 placeholder number',
        );
      }
    });
  });
}
