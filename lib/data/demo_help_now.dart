class DemoHelpAction {
  const DemoHelpAction({
    required this.label,
    required this.detail,
    required this.style,
    this.section = HelpNowSection.additional,
    this.callUri,
    this.textUri,
  });

  final String label;
  final String detail;
  final DemoHelpStyle style;
  final HelpNowSection section;
  final Uri? callUri;
  final Uri? textUri;
}

enum HelpNowSection { emergency, additional }

enum DemoHelpStyle {
  primaryFilled,
  blackOutline,
  neutralOutline,
  emergencyFilled,
}

const _poisonDetail =
    'Swallowed something harmful, or not sure? Call this line. '
    'Call 911 if they cannot breathe or are unconscious.';

const _nineOneOne = DemoHelpAction(
  label: '911 Emergency',
  detail: 'Police, fire, or medical emergency',
  style: DemoHelpStyle.emergencyFilled,
  section: HelpNowSection.emergency,
);

const _nineEightEight = DemoHelpAction(
  label: '988 Suicide & Crisis Lifeline',
  detail: 'Call or text 988 — 24/7',
  style: DemoHelpStyle.primaryFilled,
);

const _poison = DemoHelpAction(
  label: 'Poison Control',
  detail: _poisonDetail,
  style: DemoHelpStyle.neutralOutline,
);

const _reachNj = DemoHelpAction(
  label: 'ReachNJ',
  detail: 'NJ 24/7 addiction helpline — 1-844-732-2465',
  style: DemoHelpStyle.primaryFilled,
);

const _clearinghouse = DemoHelpAction(
  label: 'NJ Self-Help Group Clearinghouse',
  detail: 'Find support groups — 800-367-6274 · njgroups.org',
  style: DemoHelpStyle.neutralOutline,
);

const _warmline = DemoHelpAction(
  label: 'NJ Peer Warmline',
  detail: 'Talk with a peer (sample number)',
  style: DemoHelpStyle.primaryFilled,
);

const _wellnessCenter = DemoHelpAction(
  label: 'My Wellness Center',
  detail: 'New Brunswick Wellness Center · (732) 555-0177',
  style: DemoHelpStyle.primaryFilled,
);

/// Demo catalog: 911 first, then 988, then remaining helplines.
const demoHelpActions = <DemoHelpAction>[
  _nineOneOne,
  _nineEightEight,
  _poison,
  _reachNj,
  _clearinghouse,
  _warmline,
  _wellnessCenter,
];

final _liveNationalHelpActions = <DemoHelpAction>[
  DemoHelpAction(
    label: _nineOneOne.label,
    detail: _nineOneOne.detail,
    style: _nineOneOne.style,
    section: HelpNowSection.emergency,
    callUri: Uri(scheme: 'tel', path: '911'),
  ),
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
    label: _poison.label,
    detail: _poison.detail,
    style: _poison.style,
    callUri: Uri(scheme: 'tel', path: '18002221222'),
  ),
  DemoHelpAction(
    label: _reachNj.label,
    detail: _reachNj.detail,
    style: _reachNj.style,
    callUri: Uri(scheme: 'tel', path: '18447322465'),
  ),
  DemoHelpAction(
    label: _clearinghouse.label,
    detail: _clearinghouse.detail,
    style: _clearinghouse.style,
    callUri: Uri(scheme: 'tel', path: '18003676274'),
  ),
  _warmline,
  _wellnessCenter,
];

/// National 911 / 988 / poison plus verified NJ lines when [live] is true.
/// Warmline and CWC stay sample either way (#24).
List<DemoHelpAction> helpNowActions({required bool live}) {
  return live ? _liveNationalHelpActions : demoHelpActions;
}
