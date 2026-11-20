# Nearby places

Nearby lists live pharmacies, clinics, urgent care, and hospitals for the remembered town. The default town is New Brunswick. The list is public map data and is not checked by the study team. There is no sample place list.

## Sub-features

- `nearby-town` shows the remembered town and **Use my location**.
- `nearby-list` shows place cards after the lookup, with **Call**, **Text** or **Phone not listed**, **Directions**, and **Save**.
- `nearby-disclaimer` shows the unvetted-maps notice and the insurance sentence.
- `nearby-filter` filters the same list with **Pharmacy**, **Clinic**, **Urgent care**, and **Hospital**.

## How to get to it (user POV)

- Open the app from closed. Choose **I understand**.
- Choose the **Nearby** tab.
- Wait until the loading line is gone.
- Read the notice that the places are not checked by the team.
- Read a place card. Call, Text, and Directions are on the card. This journey does not press them.

## Driving it with verify-cwc

Preconditions:

- `verify-cwc doctor` prints `ok: yes`.
- The browser session has passed **I understand**.
- The machine can reach the OpenStreetMap Overpass servers the app uses. A blocked or timing-out lookup is a failed run.

- **Open Nearby.** Run `verify-cwc browser click --role tab --name "Nearby"`. The loading line is `Finding places near New Brunswick…`. Run `verify-cwc browser expect-text --text "Finding places near New Brunswick"`.
- **Wait for places.** Poll until a place card replaces the loading line. Run `verify-cwc browser expect-text --text "They are not checked by our team."` with the default 10 second budget. If the lookup is slow, run the same command again. The pass text is that sentence, plus at least one place name, **Use my location**, and the town control whose accessible name contains `New Brunswick`.
- **Coverage sentence.** Run `verify-cwc browser expect-text --text "insurance or walk-ins"`. The full sentence uses a curly apostrophe in "someone's". Match the substring.
- **Filters.** Run `verify-cwc browser expect-text --text "Pharmacy"` and `verify-cwc browser expect-text --text "See these on a map"`. Leave the map switch off. Map tiles are a separate connection.
- **Proof.** Run `verify-cwc browser snapshot --path "$EVIDENCE/nearby/list.aria.txt" --feature nearby` and `verify-cwc browser screenshot --path "$EVIDENCE/nearby/list.png"`. The artifacts show the town, the unvetted notice, and at least one place name.

## Gotchas

- `We could not load places right now.` plus **Try again** means the lookup failed. Report that failure and the network error. Do not change the expected sentence to the error text to make the run pass.
- On 2026-11-10 a Linux run of this app got HTTP 504 from `https://overpass.kumi.systems/api/interpreter`, then the member-facing failure line above. That run did not verify the place list.
- **Use my location** needs a device location fix. The web stand-in has no GPS grant unless the browser context allows it. This journey uses the remembered town. Denying location on a phone returns to that town. It does not empty the tab.
- The town control's accessible role on the web stand-in is a checkbox named like `New Brunswick ▾`, not a button. Click it only when the journey is changing town.
- Place **Call** and **Text** open `tel:` and `sms:`. **Directions** opens `geo:`. This helper refuses those clicks. Do not treat a web `window.open` as proof a phone opened Maps or the dialer.
- Category chips filter the cards already loaded. Panning the map does not fetch a new list.
