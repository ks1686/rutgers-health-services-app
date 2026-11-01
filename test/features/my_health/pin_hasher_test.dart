import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import 'package:cwc_health_app/features/my_health/data/pin_hasher.dart';

String _hex(List<int> bytes) =>
    bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

List<int> _key(String stored) => base64Decode(stored.split(r'$')[3]);

void main() {
  test('matches the published PBKDF2-HMAC-SHA256 test vectors', () async {
    final salt = utf8.encode('salt');
    final one = await const PinHasher(
      iterations: 1,
      runInBackground: false,
    ).hash('password', salt: salt);
    expect(
      _hex(_key(one)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    final many = await const PinHasher(
      iterations: 4096,
      runInBackground: false,
    ).hash('password', salt: salt);
    expect(
      _hex(_key(many)),
      'c5e478d59288c841aa530db6845c4c8d962893a001ce4e11a4963873aa98134a',
    );
  });

  test('the app default is 100,000 rounds with a 16-byte salt', () async {
    const real = PinHasher(runInBackground: false);
    expect(real.iterations, 100000);
    final stored = await real.hash('2468');
    final parts = stored.split(r'$');
    expect(parts[0], 'pbkdf2-sha256');
    expect(parts[1], '100000');
    expect(base64Decode(parts[2]), hasLength(16));
    expect(await real.verify('2468', stored), isTrue);
    expect(await real.verify('2469', stored), isFalse);
    expect(real.needsUpgrade(stored), isFalse);
  });

  test('a PIN saved by an older build still matches and needs upgrade', () {
    const hasher = PinHasher(iterations: 10, runInBackground: false);
    final legacy = PinHasher.legacyHash('1234');
    expect(legacy, hasLength(8));
    expect(PinHasher.isLegacy(legacy), isTrue);
    expect(hasher.needsUpgrade(legacy), isTrue);
    expect(hasher.verify('1234', legacy), completion(isTrue));
    expect(hasher.verify('4321', legacy), completion(isFalse));
  });

  test('a damaged saved value never matches', () async {
    const hasher = PinHasher(iterations: 10, runInBackground: false);
    expect(await hasher.verify('1234', r'pbkdf2-sha256$x$y$z'), isFalse);
    expect(await hasher.verify('1234', r'pbkdf2-sha256$10$%%%$abc'), isFalse);
    expect(await hasher.verify('1234', r'pbkdf2-sha256$10'), isFalse);
  });

  test('fewer rounds than the current setting asks for an upgrade', () async {
    const old = PinHasher(iterations: 10, runInBackground: false);
    const now = PinHasher(iterations: 20, runInBackground: false);
    expect(now.needsUpgrade(await old.hash('1234')), isTrue);
  });
}
