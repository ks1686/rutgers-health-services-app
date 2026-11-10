# Help Now

Help Now is the header button on every screen, including the care disclaimer path after **I understand**. 911 is the first row. On a phone, a member can press a row to fill a number and then place the call themselves. This verification run does not press a row. NJ Peer Warmline and My Wellness Center stay hidden until CSPNJ confirms them.

## Sub-features

- `help-now-open` opens Help Now from the header.
- `help-now-911-first` shows 911 before the other rows, by name and order.
- `help-now-hidden-rows` leaves the unconfirmed warmline and wellness-center rows off the page.

## How to get to it (user POV)

- From any tab, choose **Help Now** in the header.
- On the Help Now page, read the rows. 911 is first. This verification does not press 911 or any other row.
- Choose **Back** to return to the previous screen.

## Driving it with verify-cwc

Preconditions:

- `verify-cwc doctor` prints `ok: yes`.
- The browser session has passed **I understand** and a header with **Help Now** is showing.
- Launch passed `HELP_NOW_LIVE=false` (the helper default) and `HELP_NOW_UNCONFIRMED=false`.

- **Open Help Now.** Run `verify-cwc browser click --role button --name "Help Now"`. The heading is **Help Now**. The page says `You're not alone` and `Calling is turned off in this build.` Run `verify-cwc browser expect-text --text "You're not alone"` and `verify-cwc browser expect-text --text "Calling is turned off in this build."`.
- **Row names and order.** Do not click a row. Run:

```bash
verify-cwc browser expect-order \
  --text "Call 911, emergency. Opens your phone dialer." \
  --text "Call 988. Opens your phone dialer." \
  --text "Text 988. Opens your phone messages." \
  --text "Call Poison Control. Opens your phone dialer." \
  --text "Call ReachNJ. Opens your phone dialer." \
  --text "Call NJ Self-Help Group Clearinghouse. Opens your phone dialer."
```

  Run `verify-cwc browser expect-absent --text "NJ Peer Warmline"` and `verify-cwc browser expect-absent --text "My Wellness Center"`.
- **No phone open.** Run `verify-cwc browser opens`. The output is `(none)`. There is no `tel:` or `sms:` line.
- **Back.** Run `verify-cwc browser click --role button --name "Back"`. The Help Now heading is gone and the previous screen is back.
- **Proof.** Before Back, run `verify-cwc browser snapshot --path "$EVIDENCE/help-now/page.aria.txt" --feature help-now` and `verify-cwc browser screenshot --path "$EVIDENCE/help-now/page.png"`. The artifacts show **911** above the other rows.

## Gotchas

- The visible label is **911 Emergency**. The accessible name is the longer sentence. This recipe checks the spoken name and does not click it.
- The helper refuses a click whose name is a phone or text row, including 911 and 988. Do not press those rows.
- `HELP_NOW_LIVE=false` changes the sentence on the page. The app code behind the row still has a phone URL. The helper drops `tel:` and `sms:` `window.open` calls so a press cannot hand the number to the system. This run does not press the row.
- The emergency card switch reads **Show my emergency card here**. Leave it off. The default is off.
- Warmline and wellness-center rows appear only when launch passed `HELP_NOW_UNCONFIRMED=true`. This helper does not pass that flag. Those rows have no number.
