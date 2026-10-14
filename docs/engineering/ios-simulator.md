# iOS Simulator

The study build runs on the iOS Simulator. There is no iOS job in GitHub Actions. This Mac has Xcode; the simulator build is local only.

## Build

```bash
scripts/smoke.sh --ios
```

That runs the usual gates, then `flutter build ios --simulator --no-codesign`.

On this Mac, copied engine files keep the `com.apple.provenance` extended attribute. Flutter's prepare script calls `codesign` without `--strip-disallowed-xattrs`, and the build dies with `Exited with status code 255`. `scripts/smoke.sh --ios` puts a short `codesign` wrapper first on `PATH` for that one build. The wrapper only adds the flag when the command is actually signing.

Xcode itself calls `/usr/bin/codesign` by absolute path. A plugin rebuild (for example `flutter test integration_test` on a simulator) can still fail the same way. The simulator app produced by `flutter build ios --simulator` is the file to install.

## Install and open

Boot a simulator, then install the app that the build just produced:

```bash
xcrun simctl boot "iPhone 18 Pro"
flutter install -d "iPhone 18 Pro"
xcrun simctl launch booted org.rutgers.cwc.cwcHealthApp
```

Bundle id is `org.rutgers.cwc.cwcHealthApp`. Android's application id keeps an underscore (`org.rutgers.cwc.cwc_health_app`). Apple rejects underscores in a bundle id, so the two ids are not identical on purpose.

iOS deployment target is 15. `geolocator` and `file_picker` require it. `ios/Podfile` sets `platform :ios, '15.0'`.

The app icon set is the Flutter template set, including the 1024px store icon. Replacing the artwork is a design decision, not a missing asset.

`Info.plist` already has `NSLocationWhenInUseUsageDescription` and `LSApplicationQueriesSchemes` for `tel`, `sms`, and `geo`. The document picker does not need a photo-library string.

## What the simulator can and cannot prove

Each time the app is opened from closed, **Before you continue** shows, then **I understand**. Tabs, empty My Health, Learn, and More behave as on Android.

A Help Now tap uses `tel:`. The simulator has no cell radio, so it cannot place the call. Do not treat a simulator dialer sheet as proof that a phone would dial. That check stays on Android, where the tap fills the number and the member presses call.

## TestFlight

Shipping through TestFlight needs a paid Apple Developer Program membership. This repo does not enroll in that program and does not create an Apple distribution certificate. The simulator build is not a TestFlight build.
