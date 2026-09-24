import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

import 'health_models.dart';

/// A file the person chose on this phone. Not yet saved.
class PickedPaperFile {
  const PickedPaperFile({required this.name, required this.bytes});

  final String name;
  final Uint8List bytes;
}

class PaperFileTooLarge implements Exception {
  PaperFileTooLarge(this.bytes);
  final int bytes;
}

/// Rejects an empty or oversized file before it is stored with My Health.
PickedPaperFile? paperFileFromBytes({
  required String name,
  required Uint8List bytes,
}) {
  if (bytes.isEmpty) return null;
  if (bytes.length > HealthDocument.maxFileBytes) {
    throw PaperFileTooLarge(bytes.length);
  }
  return PickedPaperFile(name: name, bytes: bytes);
}

/// Opens the phone's file picker. Returns null if the person cancels.
Future<PickedPaperFile?> pickPaperFileFromPhone() async {
  final file = await FilePicker.pickFile(
    dialogTitle: 'Choose a paper from this phone',
  );
  if (file == null) return null;
  final knownLength = file.lengthSync();
  if (knownLength != null && knownLength > HealthDocument.maxFileBytes) {
    throw PaperFileTooLarge(knownLength);
  }
  final bytes = await file.readAsBytes();
  return paperFileFromBytes(name: file.name, bytes: bytes);
}
