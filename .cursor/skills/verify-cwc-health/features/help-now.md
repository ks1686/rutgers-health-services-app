# Help Now

Help Now is the header button on every screen, including the care disclaimer path after **I understand**. 911 is the first row. A tap fills the number and the member places the call. The app does not dial by itself. NJ Peer Warmline and My Wellness Center stay hidden until CSPNJ confirms them.

## Sub-features

- `help-now-open` opens Help Now from the header.
- `help-now-911-first` shows 911 before the other rows.
- `help-now-tap` hands 911 to the phone.
- `help-now-hidden-rows` leaves the unconfirmed warmline and wellness-center rows off the page.

## How to get to it (user POV)

- From any tab, choose **Help Now** in the header.
- On the Help Now page, choose **911 Emergency**. On a phone, the dialer opens with 911 filled in. Leave without placing the call.
- Choose **Back** to return to the previous screen.

## Driving it with verify-cwc

Preconditions:

- `verify-cwc doctor` prints `ok: yes`.
- The browser session has passed **I understand** and a header with **Help Now** is showing.
- `HELP_NOW_LIVE` is true (the launch default).
- `HELP_NOW_UNCONFIRMED` is false (the launch default).

- **Open Help Now.** Run `verify-cwc browser click --role button --name "Help Now"`. The heading is **Help Now**. The page says `You're not alone` and `This app never dials for you.` Run `verify-cwc browser expect-text --text "You're not alone"` and `verify-cwc browser expect-text --text "This app never dials for you."`.
- **911 is first.** The 911 button's accessible name is `Call 911, emergency. Opens your phone dialer.` The later rows are `Call 988. Opens your phone dialer.`, `Text 988. Opens your phone messages.`, `Call Poison Control. Opens your phone dialer.`, `Call ReachNJ. Opens your phone dialer.`, and `Call NJ Self-Help Group Clearinghouse. Opens your phone dialer.` Run `verify-cwc browser expect-text` for the 911 name. Run `verify-cwc browser expect-absent --text "NJ Peer Warmline"` and `verify-cwc browser expect-absent --text "My Wellness Center"`.
- **Tap 911 on the web stand-in.** Run `verify-cwc browser click --role button --name "Call 911, emergency. Opens your phone dialer." --expect-open tel:911`. The command fails if this tap did not call `window.open` with `tel:911`. Do not place the call.
- **Back.** Run `verify-cwc browser click --role button --name "Back"`. The Help Now heading is gone and the previous screen is back.
- **Proof.** Before the 911 tap, run `verify-cwc browser snapshot --path "$EVIDENCE/help-now/page.aria.txt" --feature help-now` and `verify-cwc browser screenshot --path "$EVIDENCE/help-now/page.png"`. The artifacts show **911** above the other rows.

## Gotchas

- The visible label is **911 Emergency**. The accessible name is the longer sentence above, because the button replaces its child text with that spoken label. Click the spoken name.
- On Chrome, this tap calls `window.open('tel:911')` and the **Dial this number** dialog stays hidden, because the open is accepted. Do not require that dialog on the web stand-in. If it does appear, it shows **911** and **Close**. Close it. Do not copy the number into a real dialer.
- Android opens the phone dialer with 911 filled in (`ACTION_DIAL`). iOS shows its own confirm sheet. Neither was run by the web helper. A green `--expect-open` result does not verify the dialer. Report the dialer step unverified unless you saw 911 in the phone dialer and left without calling.
- The emergency card switch reads **Show my emergency card here**. Leave it off. The default is off.
- Warmline and wellness-center rows appear only when launch passed `HELP_NOW_UNCONFIRMED=true`. This helper does not pass that flag. Those rows have no number.
