# Learn a topic

Learn lets a member read short offline notes. The Learn tab lists six topics. Opening Physical Health shows a team-written note, then a MedlinePlus article. The care disclaimer comes first on every cold start.

## Sub-features

- `learn-disclaimer` shows **Before you continue** and opens My Health after **I understand**.
- `learn-topics` lists six topics and does not list Medications or Exercise.
- `learn-topic` opens Physical Health and shows the team source line.
- `learn-article` opens **A checkup when you feel okay** and shows the MedlinePlus source.
- `learn-help-now` keeps **Help Now** on the article header.

## How to get to it (user POV)

- Open the app from closed. Read **Before you continue**. Choose **I understand**.
- Choose the **Learn** tab.
- Choose **Physical Health**.
- Choose **A checkup when you feel okay**.

## Driving it with verify-cwc

Preconditions:

- `verify-cwc doctor` prints `ok: yes`.
- `verify-cwc browser start` has just opened the disclaimer.
- Set `EVIDENCE` to the evidence directory from launch.

- **Disclaimer.** Confirm the warning and continue. Run `verify-cwc browser expect-text --text "Before you continue"` and `verify-cwc browser expect-text --text "I understand"`. Then run `verify-cwc browser screenshot --path "$EVIDENCE/learn/disclaimer.png"` and `verify-cwc browser click --role button --name "I understand"`. The header reads **My Health** and **Help Now** is present.
- **Land on My Health.** Run `verify-cwc browser expect-text --text "My Health"` and `verify-cwc browser expect-text --text "No appointments yet. Tap Add."`.
- **Open Learn.** Run `verify-cwc browser click --role tab --name "Learn"`. The six topic buttons are **Physical Health Everyday care for your body.**, **Mental Health Support for your mind and mood.**, **Stress Management Small steps that can take the edge off.**, **Nutrition Simple ideas for eating well.**, **Preventive Care Screenings and shots that help.**, and **Sleep Rest, on its own.** Run `verify-cwc browser expect-text` once for each of those names. Run `verify-cwc browser expect-absent --text "Medications"` and `verify-cwc browser expect-absent --text "Exercise"`.
- **Open Physical Health.** Run `verify-cwc browser click --role button --name "Physical Health Everyday care for your body."`. The heading is **Physical Health** and the note says `From: CWC Health App team`. Run `verify-cwc browser expect-text --text "From: CWC Health App team"`.
- **Open the checkup note.** Run `verify-cwc browser click --role button --name "A checkup when you feel okay A regular visit can catch problems early."`. The heading is **A checkup when you feel okay**. Run `verify-cwc browser expect-text --text "From: MedlinePlus"` and `verify-cwc browser expect-text --text "Help Now"`.
- **Proof.** Bring the source line on screen and save both artifacts. Run `verify-cwc browser scroll-into-view --text "From: MedlinePlus"`, then `verify-cwc browser snapshot --path "$EVIDENCE/learn/article.aria.txt" --feature learn`, then `verify-cwc browser screenshot --path "$EVIDENCE/learn/article.png"`. The snapshot contains `From: MedlinePlus`, the article heading, and **Help Now**. The screenshot shows the same note.

## Gotchas

- Topic and article buttons use the title plus the summary as one accessible name. A click on the title alone fails the exact match.
- **Medications** is a My Health section. `expect-absent` for that word must run after the Learn tab is visible, or the My Health section keeps the assertion failing until the tab changes.
- The source line can sit below the fold. `scroll-into-view` wheels the Flutter list. Scrolling the HTML document does nothing.
- Learn notes are bundled in `assets/content/learn.json`. This journey does not need a network.
- **Read more on MedlinePlus** leaves the app. Do not tap it for this proof.
- Android and iOS show the same labels without the web accessibility placeholder. A web pass does not by itself verify a simulator.
