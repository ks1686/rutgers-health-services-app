import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards the native privacy settings that the privacy pages promise.
void main() {
  test('H3 Android backup is off and both backup rule files exist', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('android:allowBackup="false"'));
    expect(
      manifest,
      contains('android:dataExtractionRules="@xml/data_extraction_rules"'),
    );
    expect(manifest, contains('android:fullBackupContent="@xml/backup_rules"'));

    final extraction = File(
      'android/app/src/main/res/xml/data_extraction_rules.xml',
    ).readAsStringSync();
    expect(extraction, contains('<cloud-backup>'));
    expect(extraction, contains('<device-transfer>'));
    expect(extraction, isNot(contains('<include')));
    final legacy = File('android/app/src/main/res/xml/backup_rules.xml')
        .readAsStringSync();
    expect(legacy, isNot(contains('<include')));
    for (final domain in ['root', 'file', 'database', 'sharedpref']) {
      expect(extraction, contains('domain="$domain" path="."'));
      expect(legacy, contains('domain="$domain" path="."'));
    }
  });

  test('H4 iOS location prompt says the location goes to the map service', () {
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final match = RegExp(
      r'<key>NSLocationWhenInUseUsageDescription</key>\s*<string>([^<]*)</string>',
    ).firstMatch(plist);
    expect(match, isNotNull);
    final text = match!.group(1)!;
    expect(text, contains('map service'));
    expect(text.toLowerCase(), isNot(contains('never')));
    expect(text.toLowerCase(), isNot(contains('stays on your phone')));
  });

  test('M4 iOS covers the app switcher snapshot without replacing Flutter '
      'scene callbacks', () {
    final app = File('ios/Runner/AppDelegate.swift').readAsStringSync();
    expect(app, contains('AppSwitcherCover.shared.start()'));
    expect(app, contains('UIScene.willDeactivateNotification'));
    expect(app, contains('UIScene.didActivateNotification'));
    final scene = File('ios/Runner/SceneDelegate.swift').readAsStringSync();
    // Overriding these in Swift would hide FlutterSceneDelegate's own
    // versions, which drive AppLifecycleState and the My Health auto-lock.
    expect(scene, isNot(contains('sceneWillResignActive')));
    expect(scene, isNot(contains('sceneDidBecomeActive')));
  });
}
