/// Compile-time flags for the Help Now screen.
///
/// [liveCalls] turns the helpline rows into real `tel:` / `sms:` launches.
/// It defaults to **on** for v1. `tel:` on Android resolves to ACTION_DIAL,
/// which fills the number and waits for the person to press call, so the app
/// never places a call by itself. iOS shows its own confirm prompt for `tel:`.
/// The app holds no CALL_PHONE permission and must not request one.
///
/// [showUnconfirmedRows] reveals the peer warmline and Community Wellness
/// Center rows. They stay **off** until CSPNJ confirms the numbers and hours;
/// the numbers currently in the catalog are placeholders and must not be
/// dialed. See AGENTS.md section 7.
class HelpNowConfig {
  const HelpNowConfig({
    this.liveCalls = true,
    this.showUnconfirmedRows = false,
  });

  /// Whether tapping a helpline row opens the phone's own dialer.
  final bool liveCalls;

  /// Whether to show rows whose phone numbers are not yet confirmed by CSPNJ.
  final bool showUnconfirmedRows;

  static HelpNowConfig fromEnvironment() {
    return const HelpNowConfig(
      liveCalls: bool.fromEnvironment('HELP_NOW_LIVE', defaultValue: true),
      showUnconfirmedRows: bool.fromEnvironment(
        'HELP_NOW_UNCONFIRMED',
        defaultValue: false,
      ),
    );
  }
}
