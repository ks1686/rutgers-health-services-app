import 'package:cwc_health_app/data/demo_help_now.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<String> labels(bool live) => [
    for (final action in helpNowActions(live: live)) action.label,
  ];

  test('911 is first; 988 follows; other helplines after', () {
    final demo = labels(false);
    expect(demo.first, '911 Emergency');
    expect(
      demo.indexOf('911 Emergency'),
      lessThan(demo.indexOf('988 Suicide & Crisis Lifeline')),
    );
    expect(
      demo.indexOf('988 Suicide & Crisis Lifeline'),
      lessThan(demo.indexOf('Poison Control')),
    );
  });

  test('ReachNJ and Self-Help Group Clearinghouse are listed after 988', () {
    final demo = labels(false);
    expect(demo, contains('ReachNJ'));
    expect(demo, contains('NJ Self-Help Group Clearinghouse'));
    expect(
      demo.indexOf('988 Suicide & Crisis Lifeline'),
      lessThan(demo.indexOf('ReachNJ')),
    );
    expect(
      demo.indexOf('ReachNJ'),
      lessThan(demo.indexOf('NJ Self-Help Group Clearinghouse')),
    );
  });

  test('Poison Control copy says when to use it vs 911', () {
    final poison = helpNowActions(
      live: false,
    ).singleWhere((a) => a.label == 'Poison Control');
    expect(poison.detail.toLowerCase(), contains('swallowed'));
    expect(poison.detail.toLowerCase(), contains('911'));
  });

  test('911 is emergency-styled; other lines are not', () {
    final actions = helpNowActions(live: false);
    final nineOneOne = actions.singleWhere((a) => a.label == '911 Emergency');
    expect(nineOneOne.style, DemoHelpStyle.emergencyFilled);
    expect(nineOneOne.section, HelpNowSection.emergency);
    expect(
      actions
          .where((a) => a.section == HelpNowSection.emergency)
          .map((a) => a.label),
      ['911 Emergency'],
    );
  });

  test(
    'live national and verified NJ numbers fill the dialer; warmline stays sample',
    () {
      final live = helpNowActions(live: true);
      Uri? call(String label) => live
          .cast<DemoHelpAction?>()
          .firstWhere((a) => a!.label == label, orElse: () => null)
          ?.callUri;

      expect(call('911 Emergency'), Uri(scheme: 'tel', path: '911'));
      expect(call('Poison Control'), Uri(scheme: 'tel', path: '18002221222'));
      expect(call('ReachNJ'), Uri(scheme: 'tel', path: '18447322465'));
      expect(
        call('NJ Self-Help Group Clearinghouse'),
        Uri(scheme: 'tel', path: '18003676274'),
      );

      expect(
        live.where((a) => a.label == 'Call 988').single.callUri,
        Uri(scheme: 'tel', path: '988'),
      );
      expect(
        live.where((a) => a.label == 'Text 988').single.textUri,
        Uri(scheme: 'sms', path: '988'),
      );

      expect(call('NJ Peer Warmline'), isNull);
      expect(call('My Wellness Center'), isNull);
    },
  );
}
