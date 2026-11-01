# Accessibility and captions

Checked against Help Now, Nearby, My Health, Learn, and More after the
Priority 1 Help Now work. This is the caption strategy for in-app and linked
video (#35).

## Captions

- **Video we host or cache:** ship a WebVTT file next to the tutorial
  (`assets/content/captions/`). How to Use plays those captions on this phone.
  Captions stay available with no internet. Playback starts only when the
  person presses play.
- **Video files:** this build ships none and has no downloader. A
  `downloadUrl` in `how_to.json` is ignored. If a video file is added later,
  it must download only on Wi-Fi, stay on the phone for offline playback, and
  be 90 seconds or less.
- **Video on another site** (a browser or the source app): do not re-host it
  and do not embed a player that strips captions. Use that site's own captions.

## Large text

Body copy on the screens above is at least 18pt before the phone's text-size
setting. Settings adds Match phone, Large (1.25×), or Extra large (1.5×) on
top of that phone setting. It does not replace the phone setting.

Help Now button details, section labels, the emergency-card subtitle, More
row titles, the My Health privacy line, and the wallet card line were 14–16pt.
They are 18pt now.

## Contrast

These pairs meet WCAG 2.1 AA (at least 4.5:1) for the text that uses them:

| Text | Background | Ratio |
| --- | --- | --- |
| White `#FFFFFF` | Scarlet `#CC0033` | 5.81:1 |
| White `#FFFFFF` | Black `#0D0D0D` (911) | 19.44:1 |
| Ink `#21262B` | Surface `#FCFBF9` | 14.75:1 |
| Gray `#5F6A72` | Surface `#FCFBF9` | 5.36:1 |
| Scarlet `#CC0033` | Tint `#FAE7EC` | 4.90:1 |

Filled Help Now details use solid white, not faded white, so the ratio stays
at the figures above. The wallet line on the scarlet card is solid white at
18pt.

## Low-power phones

- The Nearby map stays off until someone turns it on.
- Tutorial captions do not play by themselves, and nothing downloads a video.
- Step goals use a number the person enters. The app does not run a step
  sensor in the background.
- Wellness nudges are in the app. They are not a background alarm.
