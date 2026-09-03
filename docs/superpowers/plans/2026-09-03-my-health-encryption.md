# My Health encryption + drop web (2026-09-03)

**Goal:** PRIV-4 — encrypt My Health at rest with platform Keystore/Keychain; hide My Health from Android app-switcher while that tab is open; remove Flutter web as a ship/demo path.

**Done in this branch:**
- `flutter_secure_storage` + `SecureHealthStore` / `HealthStoreFactory` with one-time migration off plaintext prefs
- Android `FLAG_SECURE` via MethodChannel when My Health tab is active
- Removed `web/` and CI `Compile web` job; docs/AGENTS/README point at Android demos

**Out of scope:** iOS app-switcher blur polish; biometrics; encrypting Nearby cache (non-PHI).
