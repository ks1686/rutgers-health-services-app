import 'package:flutter/material.dart';

import 'shell/app_shell.dart';
import 'theme/cwc_theme.dart';

class CwcApp extends StatelessWidget {
  const CwcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CWC Health App',
      debugShowCheckedModeBanner: false,
      theme: buildCwcTheme(),
      home: const AppShell(),
    );
  }
}
