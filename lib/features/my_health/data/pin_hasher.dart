import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Turns a My Health PIN into a slow, salted hash (H5).
///
/// PBKDF2 with HMAC-SHA256, a random 16-byte salt per PIN, and 100,000
/// rounds by default. A 4-digit PIN has only 10,000 choices, so speed is the
/// only thing that slows a guesser who copies the saved record. Stored as
/// `pbkdf2-sha256$<rounds>$<salt base64>$<hash base64>` so the round count
/// can go up later without breaking saved PINs.
///
/// Older builds saved an 8-character FNV-1a hex value. [verify] still
/// accepts that once, and [needsUpgrade] tells the controller to replace it.
class PinHasher {
  const PinHasher({
    this.iterations = defaultIterations,
    this.runInBackground = true,
  });

  static const defaultIterations = 100000;
  static const scheme = 'pbkdf2-sha256';
  static const _saltBytes = 16;
  static const _keyBytes = 32;

  /// The hasher a [HealthController] uses when none is passed in.
  ///
  /// Tests swap this for a fast, same-thread hasher in flutter_test_config.
  static PinHasher standard = const PinHasher();

  final int iterations;

  /// Hash on a background isolate so the lock screen keeps drawing.
  final bool runInBackground;

  Future<String> hash(String pin, {List<int>? salt}) async {
    final useSalt = salt ?? _randomSalt();
    final key = await _derive(pin, useSalt, iterations);
    return '$scheme\$$iterations\$${base64Encode(useSalt)}\$${base64Encode(key)}';
  }

  Future<bool> verify(String pin, String stored) async {
    if (isLegacy(stored)) {
      return _constantTimeEquals(
        utf8.encode(legacyHash(pin)),
        utf8.encode(stored),
      );
    }
    final parts = stored.split(r'$');
    if (parts.length != 4 || parts[0] != scheme) return false;
    final rounds = int.tryParse(parts[1]);
    if (rounds == null || rounds < 1) return false;
    final List<int> salt;
    final List<int> expected;
    try {
      salt = base64Decode(parts[2]);
      expected = base64Decode(parts[3]);
    } on FormatException {
      return false;
    }
    final actual = await _derive(pin, salt, rounds);
    return _constantTimeEquals(actual, expected);
  }

  /// True for a saved value from before PBKDF2, or with fewer rounds.
  bool needsUpgrade(String stored) {
    if (isLegacy(stored)) return true;
    final parts = stored.split(r'$');
    final rounds = parts.length == 4 ? int.tryParse(parts[1]) : null;
    return rounds == null || rounds < iterations;
  }

  static bool isLegacy(String stored) => !stored.startsWith('$scheme\$');

  /// The old 32-bit FNV-1a value. Only read, never written.
  static String legacyHash(String pin) {
    final bytes = utf8.encode('cwc-health-pin-v1:$pin');
    var hash = 0x811c9dc5;
    for (final b in bytes) {
      hash ^= b;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<List<int>> _derive(String pin, List<int> salt, int rounds) {
    final job = _Pbkdf2Job(pin, Uint8List.fromList(salt), rounds);
    if (!runInBackground) return Future.value(_pbkdf2(job));
    return compute(_pbkdf2, job);
  }

  static List<int> _randomSalt() {
    final random = Random.secure();
    return List<int>.generate(_saltBytes, (_) => random.nextInt(256));
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}

class _Pbkdf2Job {
  const _Pbkdf2Job(this.pin, this.salt, this.rounds);
  final String pin;
  final Uint8List salt;
  final int rounds;
}

/// PBKDF2-HMAC-SHA256 (RFC 8018) for one 32-byte block.
List<int> _pbkdf2(_Pbkdf2Job job) {
  final hmac = Hmac(sha256, utf8.encode(job.pin));
  final first = Uint8List(job.salt.length + 4)
    ..setAll(0, job.salt)
    ..[job.salt.length + 3] = 1;
  var u = hmac.convert(first).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < job.rounds; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < PinHasher._keyBytes; j++) {
      out[j] ^= u[j];
    }
  }
  return out;
}
