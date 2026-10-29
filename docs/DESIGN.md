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

Colour, spacing and radius live in `design/tokens.json`; `python3 scripts/tokens.py` turns them into `Palette`, `Space`, `Radius` and `PlaceCategory.color`. `placeholder: true` marks a system default no design has set. `darkDerived: true` means the light value is from a design and we derived the dark one; no dark design exists yet.

### Colour

| Token | Light | Dark | Use | Source |
| --- | --- | --- | --- | --- |
| `background` | #F9F9FB | #000000 | Screen and sheet background, icon wells | Today; dark derived |
| `surface` | #FFFFFF | #1C1C1E | Cards | Today; dark derived |
| `surfaceRaised` | #FFFFFF | #2C2C2E | Sheets, cards on surface | placeholder |
| `textPrimary` | #0A0D20 | #F5F5F7 | Body text and numbers | Today; dark derived |
| `textSecondary` | #8B8B8B | #98989F | Times, labels, captions | Today; dark derived. **3.5:1 on white, below AA for small text** (QUESTIONS.md) |
| `textOnHero` | #393939 | #F5F5F7 | Today's headline on the sunrise; voiced words at 70% | Today; dark derived |
| `separator` | #E6E6EB | #38383A | Hairlines, dashed dividers, tile edges | Today; dark derived |
| `cardStroke` | clear | white 12% | Card edge in dark mode, where shadows don't show | derived |
| `gap` | #E3E3E3 | #3A3A3C | Unmapped time (hatched) on the day bar; skeletons | Today; dark derived |
| `accent` | #248FFF | #409CFF | Tint, links, insight charts; the app's AccentColor | Today (week bars); dark derived |
| `live` | #11A94D | #30D158 | The live dot | Today; dark derived |
| `yours` | #6EE36A | #3DBF4A | Wash on the Yours hero stat | Today; dark derived |
| `inverseSurface` | #353535 | #3A3A3C | The confirmation card | Today (hidden layer); dark derived |
| `inverseText` | #FFFFFF | #FFFFFF | Text on `inverseSurface` | Today |
| `glass` | white 70% | #1C1C1E 70% | Controls on the sunrise (the day pill) | Today; dark derived |
| `everythingElse` | #AEAEB2 | #636366 | The chart fold bucket | placeholder |

### Category colours

| Category | Light | Dark | Icon | Status |
| --- | --- | --- | --- | --- |
| Work | #F857CE | #FF6AD5 | 3D building (headline), `building.2.fill` stand-in (rows) | Today; dark derived |
| Home | #99E0FF | #7CCFF7 | 3D house, `house.fill` stand-in | Today; dark derived |
| Food & drink | #23FC97 | #2BE38C | 3D coffee cup, `cup.and.saucer.fill` stand-in | Today; dark derived |
| Transit | #FF9336 | #FF9F45 | `tram.fill` stand-in | Today; dark derived |
| Shopping, Fitness, Errands, Social, Entertainment, Outdoors, Education, Travel, Personal, Other | system colours | | SF Symbol stand-ins (`placeholderSymbol`) | placeholder |

**Contrast and colour vision still to check (brief §12).** Home (#99E0FF) and Food & drink (#23FC97) are about 1.5:1 against white, below the 3:1 WCAG asks of graphics; the legend's names carry them for now. Food & drink green and Transit orange sit close for deuteranopia. Logged in QUESTIONS.md.

The design uses two icon styles per category: **3D illustrations** (grayscale, soft, in the headline and hero stats) and **flat duotone glyphs** (the Solar set, in timeline rows). Only work, home and food & drink have 3D art so far (`Images.xcassets/categoryIcon`); `CategoryIcon` falls back to the glyph for the rest.

### Spacing and radius

`Space`: xxs 2 · xs 4 · s 8 · m 12 · l 16 · **screen 20** · xl 24 · xxl 32 · xxxl 48. The Today design confirms the 4-pt scale and adds 20 for screen margins.

`Radius` (Today): s 8 (chart bars) · m 13 (day pill) · l 16 (hero tiles, day bar box, banners) · xl 20 (cards, confirmation card) · xxl 32 (the sheet's top corners).

Elevation: cards take one soft shadow (black 6%, radius 16, y 6); the confirmation card a cool glow (cyan 18%, radius 20, y 9). In dark mode the card edge (`cardStroke`) stands in for the shadow.

### Type

SF Pro Rounded throughout (`Font.Design.rounded`, a system font, so Dynamic Type works). Medium for anything that leads, regular for supporting text, tracking −2% of the size. Each size is the design's at the default text size and scales with Dynamic Type relative to the nearest system style (`@ScaledMetric`). Roles in `DwellUI/Tokens/Typography.swift`; `.textRole(_:weight:)` applies one.

| Role | Size | Weight | Scales with | Use |
| --- | --- | --- | --- | --- |
| `voiceHero` | 24 | medium | title2 | Today's headline |
| `voice` | 22 | medium | title3 | Insight sentences |
| `dataHero` | 40 | medium, mono digits | largeTitle | The live timer; an insight's lone number |
| `dataStat` | 16 | medium, mono digits | callout | Hero stat numbers |
| `data` | 14 | regular, mono digits | subheadline | Durations in rows |
| `title` | 20 | medium | title3 | Section titles |
| `body` | 16 | medium | callout | Place names, the live caption |
| `label` | 16 | medium | callout | Buttons, the day pill |
| `caption` | 14 | regular | subheadline | Times, topic labels, stat labels, weekday labels, banners |
| `footnote` | 12 | regular | caption | Legends, badges, small buttons |

The design sets the day pill in SN Pro; we use SF Pro Rounded (one use, not worth a bundled face).

### Motion

`Motion.standard`, `.reveal`, `.landing` (springs) and `.reduced` (cross-fade). `.motion(_:value:)` swaps to `.reduced` under Reduce Motion; where the change is spatial, the transition swaps too.

| Moment | Animation | Reduce Motion alternative | Haptic |
| --- | --- | --- | --- |
| MO-01 Live timer ticking | Ticks on the minute the visit started; digits roll (`.numericText`) with `Motion.standard` | Digits cross-fade | none |
| MO-02 Day bar filling | Ticks grow from the baseline and fade in on appear, `Motion.reveal` | Fade in only, no growth | none |
| MO-05 Insight arrival | Deck pages: the card slides out the way you swiped and the next slides in, `Motion.standard` | Cross-fade | none |
| MO-06 Confirmation accepted | The card drops below the tab bar and fades | Fade | light (`Haptic.confirm`) |
| Dial re-render | Voiced words cross-fade; the headline's words reflow with `Motion.standard` | Cross-fade | none here (the dial's own stops are MO-11) |
| Day card "View more" | Rows expand in place, `Motion.standard` | Cross-fade | none |

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
| `VoiceText` | `DwellUI/Voice/Environment.swift` | Any `VoicedLine`; cross-fades when the dial moves | Setup | Built |
| `VoicedSentenceView` | `Components/VoicedSentenceView.swift` | A `VoicedSentence`: voiced words at 70% ink, data runs at full ink with a 3D category icon and mono digits; wraps word by word; one VoiceOver label | Today headline | Built |
| `FlowLayout` | `Components/FlowLayout.swift` | Leading / centre / trailing; wraps like text | Today | Built |
| `CategoryIcon` | `Components/CategoryIcon.swift` | `.illustration` (3D art, glyph fallback) / `.glyph`; `nil` category draws a pin | Today | Built; art for 3 of 14 categories |
| `.card()` | `Components/Card.swift` | Surface, radius xl, soft shadow; hairline in dark | Today | Built |
| `DashedDivider` | `Components/Card.swift` | 1 pt, dash 3/3, `separator` | Today | Built |
| `Sheen` | `Components/Card.swift` | Two blurred diagonal streaks; white on dark, separator on light | Today | Built |
| `SoftButtonStyle` (`.soft`) | `Components/Card.swift` | Full-width capsule with sheen and edge; pressed | Today ("View more") | Built |
| `SectionHeader` | `Components/Card.swift` | Icon + title (header trait) + optional trailing control | Today ("This week", "Your day") | Built |
| `DayBarView` | `Components/DayBarView.swift` | Ticks 4 pt wide, 2 pt apart, 32 tall, count from width; categories in display order, ≤ 7 + Everything else, unmapped hatched last; legend ↔ callout on tap or press-and-slide; empty (no ticks); grows in; audio graph | Today | Built (Swift Charts) |
| `StatTile` | `Components/StatTile.swift` | Number, label, icon, tint wash; stacks at AX sizes (by the caller) | Today (hero stats) | Built |
| `InsightCard` | `Components/InsightCard.swift` | Topic + share, voiced sentence, then a week chart or a lone number | Today | Built |
| `WeekBarsChart` | `Components/InsightCard.swift` | Seven bars, weekday labels, zero days as a faint sliver; per-bar VoiceOver, audio graph | Today | Built (Swift Charts) |
| `VisitRow` | `Components/TimelineRow.swift` | Icon well, span, place, duration, chevron; badges Approximate / Private / WFH; "Review this place"; duration moves under the name at AX sizes | Today ("Your day") | Built |
| `TimelineNote` | `Components/TimelineRow.swift` | Slim transit row; gap row with a dashed outline | Today (derived) | Built |
| `ConfirmationCard` | `Components/ConfirmationCard.swift` | Dark card, art, voiced question, Looks right (white pill) / Pick another (underlined) | Today (hidden Figma layer) | Built |
| `NoticeBanner` | `Components/NoticeBanner.swift` | Symbol, message, action; stacks at AX sizes. Permission banner and stale line | Today (derived) | Built |
| `Avatar` | `Components/NoticeBanner.swift` | Round image or person glyph | Today | Built |
| `Art` | `Tokens/Art.swift` | Raster art in `Images.xcassets`: sunrise, calendar, confirm art, sample avatar, category illustrations | Today | Built |

Still expected from the brief: calendar tiles, the segmented range control, the privacy bar, the dial, calendar match rows.

## Patterns

- **States.** Every screen designs loading, empty, still mapping ("what we're waiting for and how long"), stale (banner over usable content), failed with retry. Permissions are a banner on top, not a state.
- **Voice vs data.** Voiced sentences use `voice` roles through `VoiceText`; numbers use `data` roles and never change with the dial. Where a sentence carries data (Today's headline), `VoicedSentence` slots the data in as runs: the same runs at every dial position, set in full ink with an icon, while the voiced words sit back at 70%.
- **Privacy line.** "Only you can see this." / "Your map is private to you." where it applies.
- **Screen anatomy (Today).** A full-bleed illustration runs under the status bar behind the header (avatar left, a glass pill right, the headline), then a sheet with 32-pt top corners scrolls over it. On the sheet: white cards with 20-pt corners, separated by dashed hairlines with 20 pt above and below.
- **Floating asks.** A question for the user (the confirmation card) floats above the tab bar as a dark card, not inline, and leaves when answered.
- **Stand-ins.** Missing art uses an SF Symbol marked `[ICON NEEDED]` in code; missing copy is marked `[COPY NEEDED]`; pages and sheets without a design open `PendingView` ("Waiting for the design.").

## Change log

| Date | Design | What changed |
| --- | --- | --- |
| 2026-10-29 | Setup | Placeholder tokens, type roles, motion, haptics |
| 2026-10-29 | Today (Figma 69:81) | Colours for background, surface, text, separators, accent, live, work/home/food & drink/transit; radius scale; screen margin; SF Pro Rounded type scale; card, divider, sheen, soft button, section header, day bar, stat tile, insight card and week chart, timeline rows, confirmation card, banner, avatar; motion for MO-01, 02, 05, 06 |
