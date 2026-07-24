import 'package:flutter/material.dart';

void showDemoOnlySnackBar(BuildContext context, [String? action]) {
  final message = action == null ? 'Demo only' : 'Demo only — $action';
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ),
  );
}
