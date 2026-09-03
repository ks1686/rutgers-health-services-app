import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_string_store.dart';

/// Platform Keystore / Keychain backed strings (Android + iOS). PRIV-4.
///
/// Web is not a study-build ship target; this package is used on mobile only.
class PlatformSecureStringStore implements SecureStringStore {
  PlatformSecureStringStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}
