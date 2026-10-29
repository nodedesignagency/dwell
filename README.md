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
```

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
