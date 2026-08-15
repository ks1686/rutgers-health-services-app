class DemoHelpAction {
  const DemoHelpAction({
    required this.label,
    required this.detail,
    required this.style,
    this.callUri,
    this.textUri,
  });

  final String label;
  final String detail;
  final DemoHelpStyle style;
  final Uri? callUri;
  final Uri? textUri;
}

enum DemoHelpStyle { primaryFilled, blackOutline, neutralOutline }

const demoHelpActions = <DemoHelpAction>[
  DemoHelpAction(
    label: '988 Suicide & Crisis Lifeline',
    detail: 'Call or text 988 — 24/7',
    style: DemoHelpStyle.primaryFilled,
  ),
  DemoHelpAction(
    label: 'NJ Peer Warmline',
    detail: 'Talk with a peer (sample number)',
    style: DemoHelpStyle.primaryFilled,
  ),
  DemoHelpAction(
    label: 'My Wellness Center',
    detail: 'New Brunswick Wellness Center · (732) 555-0177',
    style: DemoHelpStyle.primaryFilled,
  ),
  DemoHelpAction(
    label: '911 Emergency',
    detail: 'Police, fire, or medical emergency',
    style: DemoHelpStyle.blackOutline,
  ),
  DemoHelpAction(
    label: 'Poison Control',
    detail: '1-800-222-1222',
    style: DemoHelpStyle.neutralOutline,
  ),
];

final _liveNationalHelpActions = <DemoHelpAction>[
  DemoHelpAction(
    label: 'Call 988',
    detail: 'Suicide & Crisis Lifeline — 24/7',
    style: DemoHelpStyle.primaryFilled,
    callUri: Uri(scheme: 'tel', path: '988'),
  ),
  DemoHelpAction(
    label: 'Text 988',
    detail: 'Suicide & Crisis Lifeline — 24/7',
    style: DemoHelpStyle.primaryFilled,
    textUri: Uri(scheme: 'sms', path: '988'),
  ),
  DemoHelpAction(
    label: 'NJ Peer Warmline',
    detail: 'Talk with a peer (sample number)',
    style: DemoHelpStyle.primaryFilled,
  ),
  DemoHelpAction(
    label: 'My Wellness Center',
    detail: 'New Brunswick Wellness Center · (732) 555-0177',
    style: DemoHelpStyle.primaryFilled,
  ),
  DemoHelpAction(
    label: '911 Emergency',
    detail: 'Police, fire, or medical emergency',
    style: DemoHelpStyle.blackOutline,
    callUri: Uri(scheme: 'tel', path: '911'),
  ),
  DemoHelpAction(
    label: 'Poison Control',
    detail: '1-800-222-1222',
    style: DemoHelpStyle.neutralOutline,
    callUri: Uri(scheme: 'tel', path: '18002221222'),
  ),
];

/// National 988 / 911 / poison dialers only when [live] is true.
/// Warmline and CWC stay sample either way.
List<DemoHelpAction> helpNowActions({required bool live}) {
  return live ? _liveNationalHelpActions : demoHelpActions;
}
