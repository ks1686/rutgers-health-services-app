# Release signing

The installable Android file is signed with one stable key, so a later build upgrades in place. A debug key is new on every machine, and Android refuses that upgrade.

## Where the key lives

Not in this repo. The repo is public.

| File | Path | In git |
| --- | --- | --- |
| Keystore | `~/.config/cwc-health-app/upload-keystore.jks` | no |
| Password | `~/.config/cwc-health-app/upload-keystore.password` | no |
| Gradle pointer | `android/key.properties` | no (`android/.gitignore`) |

Alias: `upload`. RSA 2048, created 2026-10-12. Certificate SHA-256:

`0D:5E:89:D0:3F:75:E5:B2:C7:30:C0:14:3F:D6:89:2D:BF:CF:CD:7D:4D:B4:9D:CE:71:BC:81:73:91:B6:07:9B`

`android/key.properties` points `storeFile` at the keystore above and reads the password from the password file. Both files are mode `600`.

## What a build does

- **This Mac, key present:** `flutter build apk --release` signs with the upload key.
- **This Mac, key missing:** the release build fails. It does not fall back to the debug key.
- **GitHub Actions (`CI=true`):** no key is available, so the CI release APK stays debug-signed. That artifact proves the app compiles. It is not the file to install. The installable file is built on this Mac.

## If the key is lost

A lost keystore means every later APK is a different app to Android. People uninstall and reinstall, and anything saved on the phone under the old app goes with the uninstall. Back the two files up somewhere that is not this repo and not a chat log. Do not commit them.
