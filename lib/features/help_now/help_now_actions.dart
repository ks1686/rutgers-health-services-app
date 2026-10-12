/// The Help Now action catalog.
///
/// Every row here is a real, national or New Jersey service with a verified
/// phone number. Rows open the phone's own dialer through a `tel:` URI, which
/// on Android is ACTION_DIAL: the number is filled in and the person presses
/// call. The app never places a call itself and holds no CALL_PHONE
/// permission.
///
/// The peer warmline and Community Wellness Center numbers are **not** in this
/// list by default. They are placeholders until CSPNJ confirms them, so they
/// are gated behind [showUnconfirmedRows] and hidden for v1.
library;

import 'package:flutter/foundation.dart';

@immutable
class HelpNowAction {
  const HelpNowAction({
    required this.label,
    required this.detail,
    required this.style,
    this.section = HelpNowSection.additional,
    this.callUri,
    this.textUri,
  });

  final String label;
  final String detail;
  final HelpNowStyle style;
  final HelpNowSection section;

  /// `tel:` URI. Fills the dialer; never places the call.
  final Uri? callUri;

  /// `sms:` URI. Opens the message composer with the number filled in.
  final Uri? textUri;
}

enum HelpNowSection { emergency, additional }

enum HelpNowStyle {
  primaryFilled,
  blackOutline,
  neutralOutline,
  emergencyFilled,
}

const _poisonDetail =
    'Swallowed something harmful, or not sure? Call this line. '
    'Call 911 if they cannot breathe or are unconscious.';

final _nineOneOne = HelpNowAction(
  label: '911 Emergency',
  detail: 'Police, fire, or medical emergency',
  style: HelpNowStyle.emergencyFilled,
  section: HelpNowSection.emergency,
  callUri: Uri(scheme: 'tel', path: '911'),
);

final _callNineEightEight = HelpNowAction(
  label: 'Call 988',
  detail: 'Suicide & Crisis Lifeline — 24/7',
  style: HelpNowStyle.primaryFilled,
  callUri: Uri(scheme: 'tel', path: '988'),
);

final _textNineEightEight = HelpNowAction(
  label: 'Text 988',
  detail: 'Suicide & Crisis Lifeline — 24/7',
  style: HelpNowStyle.primaryFilled,
  textUri: Uri(scheme: 'sms', path: '988'),
);

final _poison = HelpNowAction(
  label: 'Poison Control',
  detail: _poisonDetail,
  style: HelpNowStyle.neutralOutline,
  callUri: Uri(scheme: 'tel', path: '18002221222'),
);

final _reachNj = HelpNowAction(
  label: 'ReachNJ',
  detail: 'NJ 24/7 addiction helpline — 1-844-732-2465',
  style: HelpNowStyle.primaryFilled,
  callUri: Uri(scheme: 'tel', path: '18447322465'),
);

final _clearinghouse = HelpNowAction(
  label: 'NJ Self-Help Group Clearinghouse',
  detail: 'Find support groups — 800-367-6274 · njgroups.org',
  style: HelpNowStyle.neutralOutline,
  callUri: Uri(scheme: 'tel', path: '18003676274'),
);

/// HELD BACK until CSPNJ confirms the number and hours. The number below is a
/// placeholder from the original study build, not a working service line.
final _warmlineUnconfirmed = HelpNowAction(
  label: 'NJ Peer Warmline',
  detail: 'Talk with a peer (sample number). Not a contact you saved.',
  style: HelpNowStyle.neutralOutline,
);

/// HELD BACK until the study team confirms the member's own center. The number
/// below is a placeholder from the original study build.
final _wellnessCenterUnconfirmed = HelpNowAction(
  label: 'My Wellness Center',
  detail: 'Sample only. Add the person you ask in More.',
  style: HelpNowStyle.neutralOutline,
);

/// 911 first, then 988 call and text, then the remaining verified lines.
final confirmedHelpNowActions = <HelpNowAction>[
  _nineOneOne,
  _callNineEightEight,
  _textNineEightEight,
  _poison,
  _reachNj,
  _clearinghouse,
];

/// Rows whose numbers are not confirmed yet. Never dial these.
final unconfirmedHelpNowActions = <HelpNowAction>[
  _warmlineUnconfirmed,
  _wellnessCenterUnconfirmed,
];

/// Help Now rows for the screen.
///
/// [showUnconfirmedRows] is false for v1, so the peer warmline and Community
/// Wellness Center rows stay hidden until CSPNJ confirms them.
List<HelpNowAction> helpNowActions({required bool showUnconfirmedRows}) {
  return showUnconfirmedRows
      ? [...confirmedHelpNowActions, ...unconfirmedHelpNowActions]
      : confirmedHelpNowActions;
}
