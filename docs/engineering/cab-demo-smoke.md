# CAB demo smoke (before Oct 14, 2026)

Use the **demo release APK**, artifact `cwc-demo-apk-live-nearby-<sha>`.

That build is `LIVE_NEARBY=true` and `HELP_NOW_LIVE=false`. Do not install the flag-off compile APK. Help Now buttons do not dial. Nearby Call, Text, and Directions do.

Uninstall any older CWC Health App first. Each Actions runner signs with a new debug key, so an in-place upgrade can fail.

## Path

Do this on a phone with a network connection. Stop if a step does not match.

1. Open the app. First launch shows **Before you continue**. Tap **I understand**. The app lands on **My Health** (Appointments, medicines, providers). Help Now is in the header.
2. Open **Nearby**. Confirm the unvetted line **They are not checked by our team.** The list is live places for the remembered town (default New Brunswick), not the sample **Main Street Pharmacy** list. Wait for rows. If the network fails, the screen says the list is unavailable. That is a fail for this smoke.
3. On one live card, tap **Call**, then back out of the dialer without placing the call. Tap **Text**, then back out. Tap **Directions**, then back out. A card with no phone shows **Phone not listed** and still has Directions.
4. Open **Learn**. Count six tiles: Physical Health, Mental Health, Stress Management, Nutrition, Preventive Care, Sleep. There is no Medications tile and no Exercise tile. Open Physical Health and one short note. The note names a source.
5. Open **Help Now** from the header. **911 Emergency** is first. The page says the buttons are demo-only and do not place calls. Do not expect the dialer. Leave with the back button. The bottom tabs are still there.
6. Open **More**, then **Ask a Peer**. The peer screen is full screen and the bottom tabs are gone. Back returns to More and the tabs.

## Pass

Every step above matched, and Call, Text, and Directions each opened the phone's own app once.

## Not this smoke

- Real 911, 988, or warmline calls (`HELP_NOW_LIVE` is off).
- iPhone. There is no iOS build in CI.
- A flag-off APK. Nearby would show the fake New Brunswick list.
