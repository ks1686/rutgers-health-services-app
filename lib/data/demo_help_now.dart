class DemoHelpAction {
  const DemoHelpAction({
    required this.label,
    required this.detail,
    required this.style,
  });

  final String label;
  final String detail;
  final DemoHelpStyle style;
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
