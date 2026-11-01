import 'package:flutter/material.dart';

/// Shown when the phone refused to save. The form stays open with the typed
/// words, so nothing the person entered is lost.
const kCouldNotSaveMessage =
    'Could not save on this phone. Your words are still here. Try again.';

/// The files in My Health share one size limit.
const kDocumentsFullMessage =
    'Could not save. My Health is full of files. Remove a file or pick a '
    'smaller one. Your words are still here.';

void showCouldNotSave(BuildContext context, {String? message}) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message ?? kCouldNotSaveMessage),
        behavior: SnackBarBehavior.floating,
      ),
    );
}
