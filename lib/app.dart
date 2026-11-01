import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/more/more_screen.dart';
import 'features/my_health/data/biometric_unlock.dart';
import 'features/my_health/data/health_controller.dart';
import 'features/nearby/data/nearby_favorites.dart';
import 'features/nearby/data/nearby_repository.dart';
import 'features/my_health/data/health_store.dart';
import 'features/my_health/data/health_store_factory.dart';
import 'features/my_health/data/local_reminder_scheduler.dart';
import 'features/my_health/health_scope.dart';
import 'features/onboarding/disclaimer_screen.dart';
import 'features/settings/app_preferences.dart';
import 'features/settings/shared_preferences_store.dart';
import 'shell/app_shell.dart';
import 'theme/cwc_theme.dart';
import 'widgets/link_launcher.dart';

class CwcApp extends StatefulWidget {
  const CwcApp({
    super.key,
    this.healthController,
    this.linkLauncher,
    this.nearbyRepository,
    this.showSessionQuestions = kShowSessionQuestions,
    this.disclaimerAcknowledged = false,
    this.openSharedPreferences,
    this.openHealthStore,
  });

  /// Injected in tests to simulate a phone whose app storage will not open.
  final Future<SharedPreferences> Function()? openSharedPreferences;

  /// Injected in tests. Gets the app preferences when they opened, else null.
  final Future<HealthStore> Function(SharedPreferences? prefs)? openHealthStore;

  /// Injected in tests. When null, opens Keystore/Keychain-backed store.
  final HealthController? healthController;
  final LinkLauncher? linkLauncher;

  /// Injected in tests. Nearby is always live, so widget tests supply a stub
  /// instead of letting the tab reach the network.
  final NearbyRepository? nearbyRepository;

  /// Default off. Research builds set SHOW_SESSION_QUESTIONS. Tests may pass true.
  final bool showSessionQuestions;

  /// Tests pass true to open the tabs directly. A real launch leaves this
  /// false: the care warning is for this process only, so closing the app
  /// shows it again. It is not stored on the phone.
  final bool disclaimerAcknowledged;

  @override
  State<CwcApp> createState() => _CwcAppState();
}

class _CwcAppState extends State<CwcApp> {
  HealthController? _owned;
  HealthController? _health;
  AppPreferences? _prefs;
  NearbyFavoriteStore? _favorites;
  bool _booting = true;
  late bool _disclaimerAck;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Never leaves the app on a dead screen. If settings or My Health
  /// storage fail to open, the tabs still load: settings fall back to memory
  /// for this session and My Health shows a "storage unavailable" notice.
  /// Help Now, Nearby, and Learn keep working (H1).
  Future<void> _bootstrap() async {
    _disclaimerAck = widget.disclaimerAcknowledged;
    SharedPreferences? shared;
    try {
      shared =
          await (widget.openSharedPreferences ??
              SharedPreferences.getInstance)();
    } catch (e) {
      if (kDebugMode) debugPrint('App settings storage failed to open: $e');
    }
    if (shared != null) {
      _prefs = AppPreferences.fromStore(SharedPreferencesStore(shared));
      _favorites = PrefsNearbyFavoriteStore(shared);
    } else {
      _prefs = AppPreferences.fromStore(MemoryPreferenceStore());
      _favorites = MemoryNearbyFavoriteStore();
    }
    _prefs!.addListener(_onPreferencesChanged);

    final injected = widget.healthController;
    if (injected != null) {
      _health = injected;
      await _health!.setRemindersSuppressed(_prefs!.helperHiding);
      if (!_health!.ready) await _health!.load();
      if (mounted) setState(() => _booting = false);
      return;
    }
    HealthStore store;
    try {
      final open =
          widget.openHealthStore ??
          (prefs) => HealthStoreFactory.openSecure(prefs: prefs);
      store = await open(shared);
    } catch (e) {
      if (kDebugMode) debugPrint('My Health storage failed to open: $e');
      store = const UnavailableHealthStore();
    }
    _owned = HealthController(
      store,
      reminders: LocalReminderScheduler(),
      biometrics: LocalAuthBiometricAuthenticator(),
    );
    _health = _owned;
    try {
      await _health!.setRemindersSuppressed(_prefs!.helperHiding);
    } catch (_) {
      // Reminders are best effort. My Health still opens.
    }
    await _health!.load();
    if (mounted) setState(() => _booting = false);
  }

  void _onPreferencesChanged() {
    final hiding = _prefs?.helperHiding ?? false;
    _health?.setRemindersSuppressed(hiding);
  }

  @override
  void dispose() {
    _prefs?.removeListener(_onPreferencesChanged);
    _prefs?.dispose();
    _favorites?.dispose();
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_booting) {
      return MaterialApp(
        title: 'CWC Health App',
        debugShowCheckedModeBanner: false,
        theme: buildCwcTheme(),
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return MaterialApp(
      title: 'CWC Health App',
      debugShowCheckedModeBanner: false,
      theme: buildCwcTheme(),
      // Wrap every route (including pushed forms / wallet) in HealthScope.
      builder: (context, child) {
        final preferences = _prefs!;
        return ListenableBuilder(
          listenable: preferences,
          builder: (context, _) {
            final media = MediaQuery.of(context);
            return AppPreferencesScope(
              preferences: preferences,
              child: NearbyFavoritesScope(
                store: _favorites!,
                child: HealthScope(
                  controller: _health!,
                  child: MediaQuery(
                    data: media.copyWith(
                      textScaler: combineTextScaler(
                        media.textScaler,
                        preferences.textSize,
                      ),
                    ),
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
            );
          },
        );
      },
      home: _disclaimerAck
          ? AppShell(
              linkLauncher: widget.linkLauncher,
              nearbyRepository: widget.nearbyRepository,
              showSessionQuestions: widget.showSessionQuestions,
            )
          : DisclaimerScreen(
              launcher: widget.linkLauncher,
              onAcknowledged: _acknowledgeDisclaimer,
            ),
    );
  }

  void _acknowledgeDisclaimer() {
    setState(() => _disclaimerAck = true);
  }
}
