import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/my_health/data/health_controller.dart';
import 'features/my_health/data/health_store_factory.dart';
import 'features/my_health/health_scope.dart';
import 'features/onboarding/disclaimer_prefs.dart';
import 'features/onboarding/disclaimer_screen.dart';
import 'shell/app_shell.dart';
import 'theme/cwc_theme.dart';
import 'widgets/link_launcher.dart';

class CwcApp extends StatefulWidget {
  const CwcApp({super.key, this.healthController, this.linkLauncher});

  /// Injected in tests. When null, opens Keystore/Keychain-backed store.
  final HealthController? healthController;
  final LinkLauncher? linkLauncher;

  @override
  State<CwcApp> createState() => _CwcAppState();
}

class _CwcAppState extends State<CwcApp> {
  HealthController? _owned;
  HealthController? _health;
  bool _booting = true;
  bool _disclaimerAck = false;
  String? _bootError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final injected = widget.healthController;
    final prefs = await SharedPreferences.getInstance();
    _disclaimerAck = prefs.getBool(disclaimerAckPref) ?? false;
    if (injected != null) {
      _health = injected;
      if (!_health!.ready) await _health!.load();
      if (mounted) setState(() => _booting = false);
      return;
    }
    try {
      final store = await HealthStoreFactory.openSecure();
      _owned = HealthController(store);
      _health = _owned;
      await _health!.load();
    } catch (e) {
      _bootError = 'Could not open secure My Health storage.';
    }
    if (mounted) setState(() => _booting = false);
  }

  @override
  void dispose() {
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
    if (_health == null) {
      return MaterialApp(
        title: 'CWC Health App',
        debugShowCheckedModeBanner: false,
        theme: buildCwcTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                _bootError ?? 'My Health storage is unavailable.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }
    return MaterialApp(
      title: 'CWC Health App',
      debugShowCheckedModeBanner: false,
      theme: buildCwcTheme(),
      // Wrap every route (including pushed forms / wallet) in HealthScope.
      builder: (context, child) {
        return HealthScope(
          controller: _health!,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: _disclaimerAck
          ? AppShell(linkLauncher: widget.linkLauncher)
          : DisclaimerScreen(
              launcher: widget.linkLauncher,
              onAcknowledged: _acknowledgeDisclaimer,
            ),
    );
  }

  Future<void> _acknowledgeDisclaimer() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(disclaimerAckPref, true);
    if (mounted) setState(() => _disclaimerAck = true);
  }
}
