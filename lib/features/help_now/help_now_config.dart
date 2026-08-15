/// Compile-time flag for live 988 / 911 / Poison Control dialers.
///
/// Defaults keep meeting APKs on demo snackbars. Do not invent NJ warmline
/// or CWC numbers when this is on.
class HelpNowConfig {
  const HelpNowConfig({required this.helpNowLive});

  final bool helpNowLive;

  static HelpNowConfig fromEnvironment() {
    return const HelpNowConfig(
      helpNowLive: bool.fromEnvironment('HELP_NOW_LIVE', defaultValue: false),
    );
  }
}
