# More

More is a plain list. It opens how-to steps, Ask a Peer, Helper Mode, the agreement, notifications, settings, the privacy page, and erase. Session questions stay hidden unless the research flag is on.

## Sub-features

- `more-list` shows the v1 rows and hides **Session questions**.
- `more-privacy` opens **How This App Protects You** and says personal information stays on the phone.
- `more-erase-cancel` asks before deleting and leaves data in place when the member chooses **Cancel**.

## How to get to it (user POV)

- Open the app from closed. Choose **I understand**.
- Choose the **More** tab.
- Choose **How This App Protects You**. Read that information stays on this phone. Choose **Back**.
- Choose **Erase My Information**. Read the confirmation. Choose **Cancel**.

## Driving it with verify-cwc

Preconditions:

- `verify-cwc doctor` prints `ok: yes`.
- The browser session has passed **I understand**.
- Launch did not pass `SHOW_SESSION_QUESTIONS=true`.

- **Open More.** Run `verify-cwc browser click --role tab --name "More"`. The rows are **How to Use This App**, **Ask a Peer**, **Helper Mode**, **About this app**, **Using this app (agreement)**, **Notifications**, **Settings**, **How This App Protects You**, and **Erase My Information**. Run `verify-cwc browser expect-text` for **Ask a Peer**, **How This App Protects You**, and **Erase My Information**. Run `verify-cwc browser expect-absent --text "Session questions"`.
- **Privacy page.** Run `verify-cwc browser click --role button --name "How This App Protects You"`. The heading matches that name. Run `verify-cwc browser expect-text --text "They are not uploaded."` and `verify-cwc browser expect-text --text "Help Now"`.
- **Back.** Run `verify-cwc browser click --role button --name "Back"`. The More list is showing.
- **Cancel erase.** Run `verify-cwc browser click --role button --name "Erase My Information"`. A dialog says `Erase my information?` and has **Cancel** and **Erase**. Run `verify-cwc browser expect-text --text "Erase my information?"`. Run `verify-cwc browser click --role button --name "Cancel"`. Run `verify-cwc browser expect-text --text "Erase My Information"` and `verify-cwc browser expect-absent --text "Your information was erased from this phone."`.
- **Proof.** Run `verify-cwc browser snapshot --path "$EVIDENCE/more/list.aria.txt" --feature more` and `verify-cwc browser screenshot --path "$EVIDENCE/more/list.png"` while the More list is visible, after **Cancel**. The artifacts show **How This App Protects You** and **Erase My Information**, and they do not show **Session questions**.

## Gotchas

- **Erase** in the dialog really deletes on-device data. This journey stops at **Cancel**. Do not click **Erase** unless the feature under test is erasure itself, and then prove a record is gone from My Health.
- **Session questions** is absent in the v1 helper launch. Seeing that row means the process was started with `SHOW_SESSION_QUESTIONS=true`.
- **Ask a Peer** uses contacts the member saves in the app. The empty screen is a separate journey. This file only checks that the row is on the list.
- Pushed pages hide the bottom tabs. **Back** returns to More and the tabs. The accessible name of that control is **Back**.
- The privacy page describes phone storage. On the web stand-in the same sentences render. They do not prove Keystore or Keychain.
