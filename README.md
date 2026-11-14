# Dwell

iOS app that records the places you stop at and for how long, and turns that into an honest breakdown of your time. *Screen time, but for real life.*

This repo is the SwiftUI frontend. Product source of truth: [`docs/brief.md`](docs/brief.md). How we build: [`CLAUDE.md`](CLAUDE.md).

## Open it

Needs Xcode 26 or later, with its Metal Toolchain (the weekly wrap's postcard draws its stripes with a Metal shader). Xcode 26 doesn't install it by default; once per Mac:

```bash
xcodebuild -downloadComponent MetalToolchain
```

or Xcode → Settings → Components → Metal Toolchain → Get.

```bash
open Dwell.xcodeproj
```

Pick an iPhone simulator and run. With no signing team set, it runs in the simulator; to run on a phone, choose your team under Signing & Capabilities.

Or build and launch in the simulator without opening Xcode:

```bash
./scripts/run.sh                  # the booted iPhone simulator, or the newest one
./scripts/run.sh "iPhone 18 Pro"  # a simulator by name
DWELL_SKY=night ./scripts/run.sh  # force Today's sky: sunrise, day, sunset or night
DWELL_STATE=empty ./scripts/run.sh  # a state: loading, empty, firstDay, firstPlace, weeklyWrap, isThisHome, failed,
                                    # offline, transit, lastSeen, locationDenied, whenInUse, preciseOff,
                                    # motionDenied
DWELL_OPEN=you ./scripts/run.sh     # open You
DWELL_OPEN=places ./scripts/run.sh  # open Your places (You → Your places)
DWELL_OPEN=time ./scripts/run.sh    # open the Time tab
DWELL_OPEN=wrap ./scripts/run.sh    # open last week's wrap over Today
DWELL_OPEN=wrap3 ./scripts/run.sh   # open the wrap on one of its pages, 1 to 7 (3 Weekends, 7 the postcard)
DWELL_OPEN=insight ./scripts/run.sh # open the Insights page (Today → the office-time insight)
DWELL_OPEN=onboarding ./scripts/run.sh  # first run: My world, Your places, See where it all goes, Start my day
DWELL_OPEN=onboarding2 ./scripts/run.sh # onboarding on one of its pages, 1 to 4 (2 Your places, 4 Start my day)
DWELL_OPEN=onboarding5 ./scripts/run.sh # account setup over Start my day: 5 Save your world, 6 the birthday, 7 One last thing
DWELL_OPEN=under16 ./scripts/run.sh     # Account setup stopped (notInRegion: Not in your region yet)
DWELL_OPEN=tone ./scripts/run.sh        # Today with Set your tone over it, as onboarding hands over
DWELL_FRESH=1 ./scripts/run.sh     # forget what's been seen, so first-sight animations (View more's streaks sweeping away) play again
```

Time opens on the week being lived, which on the sample's Monday afternoon is one day so far; tap the dates (or Week → the pill) and pick Oct 19 – 25 for a full week like the design. Behind the sample week are seven generated weeks back to the install day (31 August), so weeks, months and the year have something to compare.

`DWELL_OPEN` and `DWELL_STATE` combine: `DWELL_OPEN=places DWELL_STATE=firstDay` is Your places with nothing mapped yet, `firstPlace` with one place, `loading`, `failed` and `offline` its other states. The same goes for You: `DWELL_OPEN=you DWELL_STATE=firstDay` has no streaks and every badge locked, `firstPlace` one place and one cell.

`DWELL_STATE=weeklyWrap` shows Today's invite; "Let's go" opens the wrap from it, growing out of the card (iOS 18 and later). `DWELL_OPEN=wrap` opens it at launch instead.

Onboarding shows only when asked for: the sample account finished it long ago. Its pages swipe or move on with their buttons; Start my day's Allow location asks iOS for real, so to see the question again reset the simulator's location answers (Settings → General → Transfer or Reset iPhone → Reset → Reset Location & Privacy). `DWELL_STATE=isThisHome` slides "Is this home?" up over Today, as after the first night. `DWELL_OPEN=tone` opens Today with "Set your tone" over it, as when onboarding finishes; it shows once, then Today stops asking (run it again to see it again).

After Start my day comes account setup: Save your world, the birthday, One last thing, then Today with Set your tone. Continue with Apple signs the sample account in without Apple's sheet (which needs the client's Apple team); a birthday under 16 stops setup, and the stop has no way back. `DWELL_STATE=offline DWELL_OPEN=onboarding5` shows a failed sign-in. Continue with phone number, the no-data preview and Welcome back (after I already have an account) wait for their designs; "Go to Today" ends onboarding there.

`firstDay` is the install day before the first stop ("Getting started"); `firstPlace` is the install day a few minutes after the first place was mapped (at home for 28m, nothing else yet). `weeklyWrap` is the usual Monday with last week's wrap ready and not opened yet. Every state runs on the same clock.

Today's sky follows the clock. Running again with a different `DWELL_SKY` plays the change between the two skies, as the app does when the phase changes since you last looked.

Until the client's tracking engine is connected, the app runs on the sample week: its clock starts at Monday 26 October 2026, 2:47 PM in New York, and ticks on from there.

## Check before pushing

Cloud chats can't compile SwiftUI, so they read for the mistakes that have broken the build (missing imports, main-actor functions passed as values; CLAUDE.md lists them) before every push:

```bash
python3 scripts/check-swift.py
```

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
