# Dwell design system

The living record of the design system, built up one design at a time. Everything here starts as a placeholder (system defaults) and is replaced as the user's designs set it. Each page updates this file.

## Principles (from the brief)

- **Where you are, first.** The live place and timer are the heartbeat; the map is home; the scratch-off is the reason to go somewhere new.
- **Report, don't grade.** "9h 40m at work", never "You worked too much". Gaps are gaps. Approximate looks approximate. A frozen timer says "last seen".
- **Voice is separate from data.** Character lives in headlines, insights, notifications, empty states, badges and the weekly wrap, and never in numbers, axes, timeline rows or settings. The two look different on the page.
- **Every open teaches you something.** Today shows a fresh, specific fact before the user scrolls.
- **Fun means motion with purpose.** No mascots, no confetti on every action, no exclamation marks (records may have one), no streak anxiety, no dark patterns.
- **Private by default, visibly.** "Only you can see this." where it applies.
- **Colour is never the only carrier of meaning.** Categories always pair colour with an icon or a name.

## Tokens

Colour, spacing and radius live in `design/tokens.json`; `python3 scripts/tokens.py` turns them into `Palette`, `Space`, `Radius` and `PlaceCategory.color`. Values marked `placeholder: true` are stand-ins.

### Colour

| Token | Use | Status |
| --- | --- | --- |
| `background` | Screen background | placeholder |
| `surface` | Cards and grouped rows | placeholder |
| `surfaceRaised` | Sheets, cards on surface | placeholder |
| `textPrimary` | Body text and numbers | placeholder |
| `textSecondary` | Captions, labels, units | placeholder |
| `separator` | Hairlines | placeholder |
| `gap` | Gaps on the day bar and timeline | placeholder |
| `accent` | Tint and primary actions; also the app's AccentColor | placeholder |

### Category colours

Fourteen categories, light and dark, all placeholder (iOS system colours). Before they are final they need a contrast check and a colour-vision check (brief §12), and each category needs its custom icon.

| Category | Colour | Icon |
| --- | --- | --- |
| Work, Home, Food & drink, Shopping, Fitness, Errands, Social, Entertainment, Outdoors, Education, Transit, Travel, Personal, Other | placeholder | SF Symbol stand-ins (`placeholderSymbol`) |

"Everything else", the chart fold bucket, also needs a colour of its own. It is not a category.

### Spacing and radius

`Space`: xxs 2 · xs 4 · s 8 · m 12 · l 16 · xl 24 · xxl 32 · xxxl 48 (placeholder 4-pt scale)
`Radius`: s 8 · m 12 · l 20 · xl 28 (placeholder)

### Type

Roles in `DwellUI/Tokens/Typography.swift`. All scale with Dynamic Type; data roles use monospaced digits.

| Role | Use | Current |
| --- | --- | --- |
| `voiceHero` | The hero insight sentence | Title 2, semibold (placeholder) |
| `voice` | Insight sentences, empty states, lens readings | Body (placeholder) |
| `dataHero` | Hero stats, live timer | Large Title, semibold, mono digits (placeholder) |
| `data` | Durations, times, percentages | Body, mono digits (placeholder) |
| `title` | Section titles | Title 3, semibold (placeholder) |
| `body` | Everything else | Body (placeholder) |
| `label` | Buttons, chips, row labels | Subheadline, medium (placeholder) |
| `caption` | Fine print, privacy lines | Caption (placeholder) |

The brief prefers system fonts for body text. A display face is allowed if it earns its place.

### Motion

`Motion.standard`, `.reveal`, `.landing` (springs) and `.reduced` (cross-fade). Each motion moment (SCREENS.md, MO-01 to MO-11) gets a row here when designed:

| Moment | Animation | Reduce Motion alternative | Haptic |
| --- | --- | --- | --- |
| | | | |

### Haptics

| `Haptic` | When | Feel |
| --- | --- | --- |
| `.confirm` | Confirmation accepted, scratch cell uncovered | Light impact |
| `.dialStop` | The dial passes a named stop | Selection tick |
| `.milestone` | Record lands, badge unlocks, streak extends | One firm impact |

Nothing on scrolling, tab changes, ticking timers or chart scrubbing. No sounds by default.

## Components

Each reusable piece, added the first time a design uses it. Build it in `DwellUI` and reuse it everywhere.

| Component | File | Variants and states | First used | Status |
| --- | --- | --- | --- | --- |
| `VoiceText` | `DwellUI/Voice/Environment.swift` | Any `VoicedLine`, follows the dial | Setup | Built, unstyled |
| | | | | |

Expected from the brief, waiting for designs: cards, stat pills, section headers, calendar tiles, the segmented range control, list rows, the privacy bar, the day bar, timeline rows, the confirmation card, the permission banner, the dial.

## Patterns

- **States.** Every screen designs loading, empty, still mapping ("what we're waiting for and how long"), stale (banner over usable content), failed with retry. Permissions are a banner on top, not a state.
- **Voice vs data.** Voiced sentences use `voice` roles through `VoiceText`; numbers use `data` roles and never change with the dial.
- **Privacy line.** "Only you can see this." / "Your map is private to you." where it applies.

## Change log

| Date | Design | What changed |
| --- | --- | --- |
| 2026-10-29 | Setup | Placeholder tokens, type roles, motion, haptics |
