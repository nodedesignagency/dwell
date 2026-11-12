# Dwell

iOS app that records the places you stop at and for how long, and turns that into an honest breakdown of your time. *Screen time, but for real life.*

This repo is the SwiftUI frontend. Product source of truth: [`docs/brief.md`](docs/brief.md). How we build: [`CLAUDE.md`](CLAUDE.md).

## Open it

Needs Xcode 26 or later.

```bash
open Dwell.xcodeproj
```

Pick an iPhone simulator and run. With no signing team set, it runs in the simulator; to run on a phone, choose your team under Signing & Capabilities.

Or build and launch in the simulator without opening Xcode:

```bash
./scripts/run.sh                  # the booted iPhone simulator, or the newest one
./scripts/run.sh "iPhone 18 Pro"  # a simulator by name
DWELL_SKY=night ./scripts/run.sh  # force Today's sky: sunrise, day, sunset or night
DWELL_STATE=empty ./scripts/run.sh  # a state: loading, empty, firstDay, firstPlace, weeklyWrap, failed, offline,
                                    # transit, lastSeen, locationDenied, whenInUse, preciseOff,
                                    # motionDenied
DWELL_OPEN=places ./scripts/run.sh  # open Your places (You → Your places)
```

`DWELL_OPEN` and `DWELL_STATE` combine: `DWELL_OPEN=places DWELL_STATE=firstDay` is Your places with nothing mapped yet, `firstPlace` with one place, `loading`, `failed` and `offline` its other states.

`firstDay` is the install day before the first stop ("Getting started"); `firstPlace` is the install day a few minutes after the first place was mapped (at home for 28m, nothing else yet). `weeklyWrap` is the usual Monday with last week's wrap ready and not opened yet. Every state runs on the same clock.

Today's sky follows the clock. Running again with a different `DWELL_SKY` plays the change between the two skies, as the app does when the phase changes since you last looked.

Until the client's tracking engine is connected, the app runs on the sample week: its clock starts at Monday 26 October 2026, 2:47 PM in New York, and ticks on from there.

## Test the core rules

```bash
cd Packages/DwellKit && swift test
```

## Change design tokens

Edit `design/tokens.json`, then:

```bash
python3 scripts/tokens.py
```

## Docs

- [`docs/SCREENS.md`](docs/SCREENS.md): every screen and state, with design and build status
- [`docs/DESIGN.md`](docs/DESIGN.md): the design system as it grows
- [`docs/QUESTIONS.md`](docs/QUESTIONS.md): open questions
