# Dwell iOS app: frontend build

Dwell records the places you stop at and for how long, and turns that into an honest breakdown of your time. We are the design agency building the SwiftUI frontend. The client's product owner is Zac.

**Read `docs/brief.md` first.** It is the product source of truth: rules, vocabulary, dial voices, every screen and state.

## Where things are

| Path | What |
| --- | --- |
| `docs/brief.md` | The client's brief, verbatim. Never edit. |
| `docs/SCREENS.md` | Every screen, sheet, state and system surface the brief asks for, with design and build status. **Update it on every page.** |
| `docs/DESIGN.md` | The living design system: tokens, type roles, components, motion, patterns. Filled in as designs arrive. |
| `docs/QUESTIONS.md` | Open questions and design-vs-brief conflicts for the user or the client. |
| `design/tokens.json` | Colour, spacing and radius tokens. Edit here, then run `python3 scripts/tokens.py`. |
| `Dwell.xcodeproj` | The app project. Xcode 26+, iOS 17+, iPhone only. |
| `Dwell/` | The app target: `App/` (entry, tabs), `Features/<Surface>/` (one folder per surface), `Resources/`. |
| `Packages/DwellKit` | Local Swift package. `DwellCore` (Foundation only): models, product rules, sample week, `DwellRepository`. `DwellUI` (SwiftUI): tokens, voice, shared components. |

The project uses synchronized folders: any file added under `Dwell/` or the package's `Sources/` is picked up by Xcode automatically. Never edit `project.pbxproj` to add files. Only touch it to add a target (widgets, Live Activity), and keep its IDs 24-character uppercase hex.

## Stack

- SwiftUI, iOS 17+, native components wherever they exist (`ContentUnavailableView`, `NavigationStack`, sheets, `TabView`).
- Swift 6 with approachable concurrency; the app target and `DwellUI` default to main-actor isolation, `DwellCore` stays nonisolated.
- Swift Charts for every chart: one y-axis, at most 7 named categories plus "Everything else" (`ChartSlice.fold`), tappable or scrubbable, with VoiceOver audio graphs.
- MapKit for maps. No POIs, no routes, ever. Private and personal places are never on any map (`Place.isHiddenFromMaps`).
- SF Symbols for system actions; custom icons for categories (`PlaceCategory.placeholderSymbol` until they arrive).
- Light and dark from day one. Colours come from the asset catalogs via `Palette` and `PlaceCategory.color`, never hardcoded.
- Dynamic Type through accessibility sizes, VoiceOver labels on everything, Reduce Motion with a real fallback for every animation.
- Swift Testing for tests.

## How we work

- The user sends one page at a time as a screenshot or Figma link. Build exactly that page, nothing extra.
- Before writing a page, reuse what exists: check `docs/DESIGN.md` components and `DwellUI`. When a design introduces a reusable piece (card, stat pill, section header, calendar tile, segmented range control, list row, privacy bar), build it in `DwellUI` and add it to the components table.
- When a design sets a colour, size or radius, update `design/tokens.json` (drop `placeholder: true`) and rerun the script; record type and motion decisions in `docs/DESIGN.md`.
- If something in a design conflicts with the brief, stop and tell the user instead of guessing. Log it in `docs/QUESTIONS.md`.
- The user will design about 15–20 screens. Everything else is derived from them. After each page, mark in `docs/SCREENS.md` what the design covered directly and what we derived from it. When the designs are done, report everything still marked missing so nothing is left out of the app.

### Definition of done for a page

1. Previews with the sample week (`.samplePreview(.peace / .plain / .grind)`) for every state: loading, empty, still mapping, stale, failed with retry, and the permission banner where it applies.
2. Light and dark; one accessibility text size (AX3 or larger) checked in previews.
3. Voiced text shown at Peace, Plain and Grind. Numbers identical across all three.
4. VoiceOver labels and, on charts, audio graphs.
5. Every animation has a Reduce Motion alternative; haptics only through `Haptic` (confirm, dial stop, milestone).
6. `docs/SCREENS.md` and `docs/DESIGN.md` updated.
7. One commit for the page, then a short summary: what was built, what was derived, anything you weren't sure about.

## Data: no tracking engine in this repo yet

The repo started empty. The client's tracking engine and app state are "available on request" (brief §2) and are not here. Screens read from `DwellRepository` (in `DwellCore`), which `SampleRepository` implements with the sample week. When the client's engine arrives, write an adapter that conforms to `DwellRepository`; screens should not change.

- Do not change the client's engine or data models without asking first.
- Grow `DwellRepository` one page at a time with only what that page needs.
- `SampleData` is a stand-in week (Brooklyn, Kestriva Labs, Monday 26 October 2026 at 2:47 PM). Replace it with Appendix D, "a real week", when the client sends it.
- Previews and screenshots read `fixedNow` from the environment instead of `Date()`.

## Product rules (never break these)

All of these are in `DwellCore` and covered by tests. Use the helpers instead of reimplementing them.

- The day runs 4 AM to 4 AM (`DwellDay`). The night the clocks change belongs to the day before.
- Gaps are shown honestly ("Dwell was asleep · 22m"), never hidden or filled in (`TimelineEntry.gap`).
- The tone dial (Peace / Calm / Plain / Push / Grind) changes sentences only, never numbers, charts or settings. Voiced text is a `VoicedLine`, shown with `VoiceText`. Character lives in headlines, insights, notifications, empty states, badges and the weekly wrap; never in numbers, axes, timeline rows or settings.
- Never celebrate more than 12h of work in a day (`WorkCeiling`).
- Words: "place" not "location", "visit" not "check-in", never "track". Buttons: "Looks right / Pick another". Sentence case. No exclamation marks except records.
- Privacy line where it applies: "Only you can see this." Share cards go through `SharePolicy`: home is "Home", venue names only with venue-level sharing, private and personal places never appear, scratch maps at city level or above.
- Durations formatted like `9h 32m` (`DurationText.short`), in monospaced digits (`TextRole.data`, `.dataHero`).
- One permission banner at a time, never a modal (`Permissions.banner`).

## Motion and haptics

- Animations are built in code (springs, matched geometry, phase animators). Keep them purposeful: timer ticking, bars filling, cells revealing, records landing. Use `Motion` curves and `.motion(_:value:)`.
- Haptics: a light tap for confirmations and dial stops, one firm impact for records, badges and streaks. Nothing on scroll or tab changes.

## Copy

- Use the brief's copy (Appendix B) where it exists. The client writes the full copy deck.
- Missing copy: write a short placeholder and mark it `[COPY NEEDED]`. No lorem ipsum.

## Checking work

Cloud sessions run on Linux: SwiftUI and the Xcode project cannot build there. What can run:

```bash
cd Packages/DwellKit && swift test
```

If `swift` is missing, download the toolchain (about 1 GB) into the scratchpad:

```bash
curl -sSLO https://download.swift.org/swift-6.2.1-release/ubuntu2404/swift-6.2.1-RELEASE/swift-6.2.1-RELEASE-ubuntu24.04.tar.gz && tar xzf swift-6.2.1-RELEASE-ubuntu24.04.tar.gz
```

Everything in `DwellUI` and `Dwell/` is only compiled when the user builds in Xcode on their Mac. Say plainly which files were not compiled, and keep SwiftUI code to APIs available on iOS 17.

## Git

- `main` holds the setup and finished pages.
- Each page is built on its own branch, one commit per page, then summarised for the user.
- Never commit `.build/`, `DerivedData/` or `xcuserdata/`.
