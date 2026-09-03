import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'features/my_health/data/health_controller.dart';
import 'features/my_health/data/prefs_health_store.dart';
import 'features/my_health/health_scope.dart';
import 'shell/app_shell.dart';
import 'theme/cwc_theme.dart';
import 'widgets/link_launcher.dart';

class CwcApp extends StatefulWidget {
  const CwcApp({super.key, this.healthController, this.linkLauncher});

  /// Injected in tests. When null, uses on-device SharedPreferences.
  final HealthController? healthController;
  final LinkLauncher? linkLauncher;

  @override
  State<CwcApp> createState() => _CwcAppState();
}

class _CwcAppState extends State<CwcApp> {
  HealthController? _owned;
  HealthController? _health;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final injected = widget.healthController;
    if (injected != null) {
      _health = injected;
      if (!_health!.ready) await _health!.load();
      if (mounted) setState(() => _booting = false);
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    _owned = HealthController(PrefsHealthStore(prefs));
    _health = _owned;
    await _health!.load();
    if (mounted) setState(() => _booting = false);
  }

  @override
  void dispose() {
    _owned?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_booting || _health == null) {
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
        return HealthScope(
          controller: _health!,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: AppShell(linkLauncher: widget.linkLauncher),
    );
  }
}
