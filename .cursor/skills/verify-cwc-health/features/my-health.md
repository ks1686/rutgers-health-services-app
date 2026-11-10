# My Health medication

My Health starts empty. A member can save a medicine as a memory aid on this device and see it again after the app is opened from closed. The screen is not medical advice.

## Sub-features

- `my-health-empty` shows empty appointments, medicines, and providers after the disclaimer.
- `my-health-add` saves a name, a purpose, and a schedule.
- `my-health-persist` shows that medicine after a reload and a new acknowledgement of the disclaimer.

## How to get to it (user POV)

- Open the app from closed. Choose **I understand**. The app lands on **My Health**.
- Under **Medications**, choose **Add**.
- Enter the medicine, what it is for, and the dose or schedule. Leave the reminder off. Choose **Save**.
- Close the app and open it again. Choose **I understand**. The medicine is still listed.

## Driving it with verify-cwc

Preconditions:

- `verify-cwc doctor` prints `ok: yes`.
- `verify-cwc browser start` is on the disclaimer, in a browser context that does not already list `Example tablet`.
- The reminder switch stays off so this journey does not ask the device for notification permission.

- **Pass the disclaimer.** Run `verify-cwc browser click --role button --name "I understand"`. Run `verify-cwc browser expect-text --text "No medications yet. Tap Add."`.
- **Open the form.** Run `verify-cwc browser click --role button --name "Add" --within-role group --within-name "Medications"`. The heading is **Add medication**.
- **Enter the medicine.** Run `verify-cwc browser fill --role textbox --name "Medication name" --value "Example tablet"`, `verify-cwc browser fill --role textbox --name "What it's for (your words)" --value "Verification fixture"`, and `verify-cwc browser fill --role textbox --name "Dose / schedule" --value "Once a day"`.
- **Save.** Run `verify-cwc browser click --role button --name "Save"`. My Health lists `Example tablet`. Run `verify-cwc browser expect-text --text "Example tablet"`.
- **Reload.** Run `verify-cwc browser reload`. The disclaimer is back. Run `verify-cwc browser click --role button --name "I understand"`. Run `verify-cwc browser expect-text --text "Example tablet"` and `verify-cwc browser expect-text --text "Verification fixture"`.
- **Proof.** Run `verify-cwc browser snapshot --path "$EVIDENCE/my-health/saved.aria.txt" --feature my-health` and `verify-cwc browser screenshot --path "$EVIDENCE/my-health/saved.png"`. Both show `Example tablet` on My Health.

## Gotchas

- Several sections have an **Add** button. Scope the empty Medications add with `--within-role group --within-name "Medications"`. After a medicine exists, that section's accessible name is a button that starts with `Medications` and includes the medicine. A second add uses `--within-role button --within-name "Medications"`.
- The reminder switch is **Remind me on this phone**. Leave it off for this journey.
- `browser reload` keeps the browser origin's storage and shows the disclaimer again, because the acknowledgement is not stored. A brand-new `browser start` on a new context is empty.
- The web build does save a medicine. `SecureHealthStore.write` (`lib/features/my_health/data/secure_health_store.dart:57`) writes `health.v1.snapshot`. On this stand-in that becomes the localStorage key `FlutterSecureStorage.health.v1.snapshot`, and a reload in the same browser shows the medicine. Dose / schedule is multiline (`lib/features/my_health/medication_form_screen.dart:184`). A value that never reaches its controller makes `_save` return at the empty check (`medication_form_screen.dart:49`) before `upsertMedication` (`medication_form_screen.dart:69`). The form stays open, and the storage key stays on the empty record from the first load. The name is still visible in that open form. That is a missed keystroke, not a failed write. `browser fill` types the value and leaves the field so the controller receives it.
- Web storage is the browser origin for this port. It is not Android Keystore or iOS Keychain. A green reload on the web stand-in does not verify the phone keystore. Report the keystore step unverified unless you reopened the app on a phone and saw the same medicine.
- **Set PIN** is on this screen. A PIN locks My Health only. Nearby, Learn, and Help Now stay open. This journey does not set a PIN.
- If storage cannot open, the screen says storage is unavailable instead of the empty lists. That is a failure for this journey.
