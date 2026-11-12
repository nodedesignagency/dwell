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
| `textOnHero` | #393939 | #F5F5F7 | Today's headline on the sky; voiced words at 70%. The header resolves it by the sky (light ink at sunset and night), not the system scheme | Today; dark derived |
| `separator` | ink 10% | white 12% | Dashed dividers (sections, timeline rows, inside the day bar), hairlines, tile edges | Today (Figma); dark derived |
| `outline` | ink 5% | white 8% | Border of a framed group inside a card: the day bar box | Today (Figma); dark derived |
| `cardStroke` | clear | white 12% | Card edge in dark mode, where shadows don't show | derived |
| `gap` | #E3E3E3 | #3A3A3C | Skeletons; the dashed outline of a gap row | derived |
| `unmapped` | #DADADA 80% | #5E5E63 80% | Unmapped ticks and swatch: outline and stripes | Today (Figma); dark derived |
| `accent` | #248FFF | #409CFF | Tint, links, insight charts; the app's AccentColor | Today (week bars); dark derived |
| `live` | #11A94D | #30D158 | The live dot | Today; dark derived |
| `yours` | #6EE36A | #3DBF4A | Wash on the Yours hero stat | Today; dark derived |
| `inverseSurface` | #252537 | #2A2A3E | The confirmation card (navy) | Today (Figma card, 12 Nov); dark derived |
| `inverseGlow` | #FAEFD5 | #FAEFD5 | The warm light along the confirmation card's top edge | Today (Figma card; read from the screenshot) |
| `inverseText` | #FFFFFF | #FFFFFF | Text on `inverseSurface` | Today |
| `tabBar` | white 20% | #1C1C1E 20% | Tint over the tab bar's glass | Today (Figma); dark derived |
| `tabPill` | white 80% | #3A3A3C 80% | The selected tab's pill | Today (Figma); dark derived |
| `tabPillStroke` | #F6F6F6 | #48484A | The selected tab's pill border | Today (Figma); dark derived |
| `tabBarStroke` | ink 10% | white 12% | The tab bar's border | Today (user, 12 Nov); dark derived |
| `tabInactive` | #747474 | #8E8E93 | Labels of the tabs not selected | Today (Figma); dark derived |
| `step` | #3E64F6 | #5C7EFF | Getting started: the step numbers and their tags | Today (Figma "Getting Started"); dark derived |
| `wrapCentre` | #67D7FF | #67D7FF | The weekly wrap invite: the middle of its radial fill | Today "Weekly Wrap" (Figma); same in dark |
| `wrapEdge` | #00A3F3 | #00A3F3 | The weekly wrap invite: the edge of its radial fill | Today "Weekly Wrap" (Figma); same in dark |
| `glass` | white 70% | #1C1C1E 70% | Controls on the sky (the day pill, kept light in every sky) | Today; dark derived |
| `field` | #FAFAFB | #1C1C1E | The search field's fill: the page's grey, lit a little, raised by its shadow | Your places (read from the screenshot); dark derived |
| `fieldIcon` | #6C6C6C | #AEAEB2 | The search field's magnifier | Your places (read from the screenshot); dark derived |
| `placeholder` | #9A9BA3 | #6E6E73 | The search field's placeholder ("Search places") | Your places (read from the screenshot); dark derived |
| `everythingElse` | #AEAEB2 | #636366 | The chart fold bucket | placeholder |

### Category colours

| Category | Light | Dark | Icon | Status |
| --- | --- | --- | --- | --- |
| Work | #FA51D0 | #FF6AD5 | 3D building (headline), `building.2.fill` stand-in (rows) | Today (Figma); dark derived |
| Home | #99E0FF | #7CCFF7 | 3D house, `house.fill` stand-in | Today; dark derived |
| Food & drink | #23FC97 | #2BE38C | 3D coffee cup, `cup.and.saucer.fill` stand-in | Today; dark derived |
| Transit | #FF9336 | #FF9F45 | `tram.fill` stand-in | Today; dark derived |
| Shopping, Fitness, Errands, Social, Entertainment, Outdoors, Education, Travel, Personal, Other | system colours | | SF Symbol stand-ins (`placeholderSymbol`) | placeholder |

**Contrast and colour vision still to check (brief §12).** Home (#99E0FF) and Food & drink (#23FC97) are about 1.5:1 against white, below the 3:1 WCAG asks of graphics; the legend's names carry them for now. Food & drink green and Transit orange sit close for deuteranopia. Logged in QUESTIONS.md.

Each category also has a **glint** (`PlaceCategory.glint`, `categoryGlint` in the colour catalog): the light tint its day bar ticks catch along their top edge. Work's is from Figma (#FFB8ED on #FA51D0); the rest are derived the same way, 60% of the way to white.

The design uses two icon styles per category: **3D illustrations** (grayscale, soft, in the headline and hero stats) and **flat duotone glyphs** (the Solar set, in timeline rows). Only work, home and food & drink have 3D art so far (`Images.xcassets/categoryIcon`); `CategoryIcon` falls back to the glyph for the rest.

### Sky

Today's header is a sky drawn in code (`SkyView`), not an image: four phases by the clock, from the user's four sky images. Colours live in `design/tokens.json` under `sky` (a top-to-bottom gradient, a horizon band where the sky has one, the sun or moon's lit and shaded colour, its glow); the generator turns them into `SkyPhase.colors`. The sky follows the time of day, not light or dark mode, and the header's text follows the sky.

| Phase | From | Sky | Body | Stars | Header ink |
| --- | --- | --- | --- | --- | --- |
| Sunrise | 5 AM | Blue → lilac → pink → gold, lilac band below the horizon | Half sun on the horizon, centred, peeking over the sheet | none | dark |
| Day | 10 AM | Deep blue → pale blue → cream → yellow | Small bright sun, top right, wide soft glow | none | dark |
| Sunset | 5 PM | Indigo → violet → coral → orange, purple band | Half sun on the horizon, orange | some, faint | light |
| Night | 8 PM | Navy → teal → mint | Thin crescent moon, top right, faint glow | all | light |

Positions are shares of the header (the horizon sits 26 pt above the sky's bottom edge, 6 pt under the sheet's top), so the scene holds at any height and at AX sizes. `-DwellSky night` at launch (`DWELL_SKY=night ./scripts/run.sh`) or `\.skyPhase` in previews forces a phase.

### Spacing and radius

`Space`: xxs 2 · xs 4 · s 8 · m 12 · l 16 · **screen 20** · xl 24 · xxl 32 · xxxl 48. The Today design confirms the 4-pt scale and adds 20 for screen margins.

`Radius` (Today): s 8 (chart bars) · m 13 (day pill) · box 14 (the day bar box) · l 16 (hero tiles, banners) · xl 20 (cards, confirmation card) · xxl 32 (the sheet's top corners). Your places adds **control 12** (the back button and the filter chips, measured from the screenshot) and confirms xl 20 for its list card and the screen margin of 16 for a pushed page.

Elevation: cards take one soft shadow (black 6%, radius 16, y 6), cast by the card's shape only: boxes and tiles inside a card (the day bar box, the hero tiles) have none and sit on the same white; the confirmation card no drop shadow, but a warm light along its top edge (`inverseGlow` from 15% at the edge to about 1% at the bottom, read from the screenshot; the design's five inner shadows replace it once their values are in). In dark mode the card edge (`cardStroke`) stands in for the shadow. The search field (Your places) is raised off the page rather than set on a card: its fill is close to the page's grey, lit by a 1-pt white line along its top that fades by the middle, with two shadows below, black 6% (radius 2, y 2) and 5% (radius 12, y 8). Those values are our estimate from the screenshot until the Figma ones arrive. Back button and chips: white, no shadow, no border (the card edge in dark).

### Type

SF Pro Rounded throughout (`Font.Design.rounded`, a system font, so Dynamic Type works). Medium for anything that leads, regular for supporting text. Tracking −2% of the size, except the "View more" button at −1% and the day pill at 0 (`.textRole(_:weight:tracking:)`); the tab bar keeps the system's own spacing. Each size is the design's at the default text size and scales with Dynamic Type relative to the nearest system style (`@ScaledMetric`). Roles in `DwellUI/Tokens/Typography.swift`; `.textRole(_:weight:)` applies one.

| Role | Size | Weight | Scales with | Use |
| --- | --- | --- | --- | --- |
| `voiceDisplay` | 32 | medium | largeTitle | The weekly wrap invite's title (measured from the screenshot) |
| `voiceHero` | 24 | medium | title2 | Today's headline |
| `voice` | 22 | medium | title3 | Insight sentences |
| `pageTitle` | 24 | medium | title2 | A pushed page's title: "Your places". Plain words, the size of Today's headline |
| `dataHero` | 40 | medium, mono digits | largeTitle | An insight's lone number; the live timer, which uses proportional digits like the design (QUESTIONS.md) |
| `dataStat` | 16 | medium, proportional digits (as in the design; see QUESTIONS.md, design vs brief 11) | callout | Hero stat numbers |
| `data` | 14 | regular, mono digits | subheadline | Durations in rows |
| `title` | 20 | medium | title3 | Section titles |
| `body` | 16 | medium | callout | Place names, the live caption. Regular weight for a page header's facts ("41 places • 640h mapped") |
| `label` | 16 | medium | callout | Buttons, the day pill |
| `action` | 18 | medium | body | The button on a feature card: "Let's go" (measured from the screenshot) |
| `caption` | 14 | regular | subheadline | Times, topic labels, stat labels, weekday labels, banners; a place's facts ("Work • 48 visits"), list section labels set in capitals ("FAVOURITES"), the search field. Medium weight on filter chips |
| `footnote` | 12 | regular | caption | Legends, badges, small buttons |
| `tab` | 12, line height 16 | medium selected, regular otherwise; tracking 0 | footnote | Tab bar labels |

The design sets the day pill in SN Pro; we use SF Pro Rounded (one use, not worth a bundled face).

### Motion

`Motion.standard`, `.reveal`, `.landing` (springs) and `.reduced` (cross-fade). `.motion(_:value:)` swaps to `.reduced` under Reduce Motion; where the change is spatial, the transition swaps too.

| Moment | Animation | Reduce Motion alternative | Haptic |
| --- | --- | --- | --- |
| MO-01 Live timer ticking | Ticks on the minute the visit started; digits roll (`.numericText`) with `Motion.standard` | Digits cross-fade | none |
| Icon shuffle (Getting started) | The 3D icons (`Art.firstStopIcons`: house, office, café, place pin, cells; new category art joins by itself) turn on their vertical axis like a coin, a new one every 0.7 s: each half turn (`Motion.flip`, 0.5 s, cubic 0.6 / 0 / 0.4 / 1, perspective 0.5) gathers speed as the icon turns away and eases off as the next turns to face you; the swap lands edge-on, so only one icon ever shows; a little blur follows the turn (none facing you, 3 pt edge-on, where it's fastest); it rests facing you for 0.2 s | The house, still | none |
| Live dot | The dot (8) alone, no halo at rest, keeping the halo's 14-pt footprint and centred on the caption's capitals. While the timer runs (at a place or in transit), a disc of its colour spreads from the dot's size to 26 pt and fades from 40% to nothing, `Motion.pulse` (1.6 s ease-out), on a loop | Still dot | none |
| Weekly wrap rays | The invite's sixteen white rays turn like the hero tiles': a full circle every 24 s, `Motion.spin`, on a loop (the same component; the design shows no motion of its own) | Rays hold still | none |
| Hero tile rays | The sixteen rays behind each hero tile's icon turn a full circle every 24 s, `Motion.spin` (linear), on a loop; the coloured disc stays put | Rays hold still | none |
| MO-02 Day bar filling | Ticks grow from the baseline and fade in on appear, `Motion.reveal` | Fade in only, no growth | none |
| MO-05 Insight arrival | Deck pages: the card slides out the way you swiped and the next slides in, `Motion.standard` | Cross-fade | none |
| Confirmation arrives | Slides up from behind the tab bar and fades in, `Motion.arrive` (0.5 s spring, no bounce). The animation is scoped to the card: nothing else on Today animates when it loads | Fade | none |
| Confirmation waiting | While the card shows, its two streaks of light sweep across it left to right on a steady loop (`Motion.sweep`, 2.4 s linear), from just off the leading edge to just off the trailing one | Streaks rest where the design draws them | none |
| MO-06 Confirmation accepted | The card drops below the tab bar and fades | Fade | light (`Haptic.confirm`) |
| MO-12 Sky phase change | When the phase changes, live or since the last open (the old sky shows for 0.5 s first): skies cross-fade while the sun and moon travel, `Motion.skyChange` (2.6 s ease-in-out). Night → sunrise: the moon climbs away, the sun rises to the horizon. Sunrise → day: the sun arcs up to the top right and shrinks. Day → sunset: it sinks back to the horizon. Sunset → night: it drops below, the moon comes down, stars come out | `Motion.skyFade` (0.8 s cross-fade), bodies fade in place | none |
| MO-13 Sky settles on open | Every launch and every return from the background: the sun or moon lifts into place (a quarter of its radius), its glow blooms, stars appear one by one 90 ms apart, `Motion.skySettle` (1.4 s ease-out) | Fade only | none |
| Dial re-render | Voiced words cross-fade; the headline's words reflow with `Motion.standard` | Cross-fade | none here (the dial's own stops are MO-11) |
| Day card "View more" | Rows expand in place, `Motion.standard` | Cross-fade | none |
| Your places: a chip changes the list | Rows reorder, come and go in place, `Motion.standard`; typing in search doesn't animate | Cross-fade | none |
| Sheet over the header | Scroll-driven: the header holds still while the sheet rises over it; overscroll shows the sky's last colour running on below it | None needed: it moves only with the finger | none |

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
| `VoicedSentenceView` | `Components/VoicedSentenceView.swift` | A `VoicedSentence`: voiced words at 70% ink, data runs at full ink with a 3D category icon and mono digits; wraps word by word, runs included, icon kept on the run's first word; one VoiceOver label | Today headline | Built |
| `FlowLayout` | `Components/FlowLayout.swift` | Leading / centre / trailing; wraps like text | Today | Built |
| `CategoryIcon` | `Components/CategoryIcon.swift` | `.illustration` (3D art, glyph fallback) / `.glyph` (Solar bold duotone vectors, drawn as templates so the second tone stays 50% of the ink; SF Symbol fallback); `nil` category draws a pin | Today | Built; art and glyphs for 3 of 14 categories (work, home, food & drink) |
| `.card()` | `Components/Card.swift` | Surface, radius xl, soft shadow; hairline in dark | Today | Built |
| `DashedDivider` | `Components/Card.swift` | 1 pt, dash 3/3, `separator` | Today | Built |
| `Sheen` | `Components/Card.swift` | Two blurred diagonal streaks; white on dark, separator on light | Today | Built |
| `SoftButtonStyle` (`.soft`) | `Components/Card.swift` | Full-width capsule with sheen and edge; pressed | Today ("View more") | Built |
| `SectionHeader` | `Components/Card.swift` | Icon + title (header trait) + optional trailing control ("This week": the design's 22-pt arrows, 8 apart, their 44-pt tap areas overlapping) | Today ("This week", "Your day") | Built |
| `DayBarView` | `Components/DayBarView.swift` | The day so far, in a box (radius 14, padding 8, gap 10, white, ink-5% border). Ticks 4 × 32 capsules, 2 pt apart, count from width; categories in display order, ≤ 7 + Everything else; unmapped last (gaps only, never the hours still to come) as hollow capsules with 45° stripes, outline and stripes #DADADA 80%; each tick and swatch carries five stacked inner shadows in its category's glint (x 0, spread 0; y 13 / 8 / 5 / 2 / 1, blur 4 / 3 / 3 / 2 / 1, opacity 1 / 5 / 18 / 30 / 35%); legend ↔ callout on tap or press-and-slide; empty (no ticks); grows in; audio graph. SwiftUI shapes, not Swift Charts: Charts doesn't draw inner shadows, and the bar's VoiceOver and audio graph are its own | Today | Built |
| `StatTile` | `Components/StatTile.swift` | Number, label, icon; behind the icon a 271.55-pt glow: a 133.98-pt disc of the tint fading in from the left (50%, blur 66.82) under sixteen ink rays (radial 50% → 0, fill 15%, layer 20%, as in Figma; 15% ink at the centre was tried on 12 Nov and read too heavy), clipped to the tile; stacks at AX sizes (by the caller) | Today (Figma) | Built |
| `InsightCard` | `Components/InsightCard.swift` | Topic + share and the voiced sentence 4 apart, then (12 below) a week chart or a lone number | Today | Built |
| `WeekBarsChart` | `Components/InsightCard.swift` | Seven bars, weekday labels, zero days as a faint sliver; per-bar VoiceOver, audio graph | Today | Built (Swift Charts) |
| `VisitRow` | `Components/TimelineRow.swift` | Icon well (32, round, #F9F9FB, ink-5% border inside, glyph 18), 8 to the span (14, grey) over the place (16 medium) 4 apart, centred on the well with the space above the span's capitals and below the place's baseline trimmed, so the two lines span the well and the row is 32-33 tall (Figma); then the design's clock (14), duration and chevron (8 × 14), grey; badges Approximate / Private / WFH; "Review this place"; duration moves under the name at AX sizes | Today ("Your day") | Built |
| `TimelineNote` | `Components/TimelineRow.swift` | Transit and gaps shaped like a visit row: well (tram; for a gap a moon in a dashed well), span over "In transit" or "Dwell was asleep" (the gap's words grey), clock and duration, no chevron | Today (derived from the visit row, 12 Nov) | Built |
| `LiveDot`, `LiveLabel` | `Components/LiveDot.swift` | The live dot (8 in a 14 footprint) with its pulse; `LiveLabel` sets it by a line of 16-pt text, centred on its capitals | Today (live caption, "Mapping right now.") | Built |
| `IconShuffle` | `Components/IconShuffle.swift` | Images turning in one spot like a coin, swapping edge-on; first image under Reduce Motion | Today (Getting started) | Built; the design's icon set to come |
| `StepRow` | `Components/StepRow.swift` | Numbered checklist step: 32-pt blue disc ("01", 14, white; lit along its bottom and top), 12 to a white card (radius 20, card shadow) with the tag (12 medium, `step`, in capitals), title (16) and detail (14, grey), lines 6 apart, padding 16 × 12; a dashed line behind the row at the disc's centre | Today (Getting started) | Built |
| `WaitingCard` | `Components/WaitingCard.swift` | What a section is waiting for and how long: art 64 square (`Art.Illustration.chart` on Today), 24 below the card's top, 6 to the title (`voice`, 22), 4 to the line (`body`, 16, grey), 18 to the bottom, centred, 161 tall; both lines voiced (empty states follow the dial); one VoiceOver element. Measured from the screenshot | Today ("Waiting for your insights", after a few minutes) | Built |
| `ConfirmationCard` | `Components/ConfirmationCard.swift` | Navy card (65 tall, radius 20, padding 16): the place's category art 32, 12 to a grey voiced question (12, white 75%) over the visit in white (14: duration semibold, monospaced; place regular; wraps to two lines), then Looks right (white pill, 16 × 8, darker along the top) and Pick another (underlined), both 12 semibold, 8 apart, on the same row; buttons under the text at AX sizes; sheen and top light | Today (Figma card, 12 Nov) | Built; inner shadow values pending |
| `NoticeBanner` | `Components/NoticeBanner.swift` | Symbol, message, action; stacks at AX sizes. Permission banner and stale line | Today (derived) | Built |
| `Avatar` | `Components/NoticeBanner.swift` | Round image or person glyph | Today | Built |
| `DwellTabBar` | `Dwell/App/DwellTabBar.swift` | Four tabs, sliding pill, frosted bar; see Patterns | Today (Figma tabPills) | Built |
| `Art` | `Tokens/Art.swift` | Art in `Images.xcassets`: the day pill's calendar, sample avatar, category illustrations (`categoryIcon/`), timeline glyphs (`glyph/`, SVG), hero tile art (`heroIcon/`), section header art (`icon/thisWeek`, `icon/yourDay` (also Your places' header), `icon/gettingStarted`), other 3D art (`illustration/place`, `cells`, `clock`, `chart`; the chart not on a screen yet), the Getting started shuffle's list (`firstStopIcons`: house, every other category with art, place pin, cells), tab icons (`tab/`, with dark versions derived by inverting the tones), line icons as templates (`glyph/clock`, `glyph/chevron`, `icon/arrow`, mirrored for back), the old confirm illustration (unused since the new card) | Today | Built |
| `WeeklyWrapCard` | `Components/WeeklyWrapCard.swift` | The weekly wrap invite: 224 tall (grows at AX sizes), radius 20, radial fill `wrapCentre` → `wrapEdge` (centred 53.7% down, reaching 46% each way), the card shadow; centred: the week (`caption`, white 90%), 2 to the voiced title (`voiceDisplay`, white, at most 280 wide so it breaks after "your"), 12 to "Let's go" (`action`, ink, white capsule 20 × 8, 44-pt tap target). Behind: the glow component in white (rays: radial 50% → 0, fill 30%, layer 50%, turning; Ellipse 39: drawn as the ramp it makes through the card, white 24% → 12% left to right). Always the light scheme, so the card and its ink stay the same in dark mode | Today ("Weekly Wrap") | Built |
| `.card(fill:)` | `Components/Card.swift` | A card with its own fill and the same shadow and dark edge as every card | Today ("Weekly Wrap") | Built |
| `IconWell` | `Components/RowParts.swift` | A row's round glyph well (32, page grey, ink-5% border; dashed for a gap), moved out of the timeline row so place rows share it | Today; Your places | Built |
| `DurationTrail` | `Components/RowParts.swift` | The design's clock (14), a duration as written ("57m", "186h") and the chevron (8 × 14), grey; moved out of the timeline row | Today; Your places | Built |
| `DotLine` | `Components/RowParts.swift` | Facts with a 3-pt dot between them ("Work • 48 visits"; 8 to each dot under a place, 12 under a page title); takes the font and colour it's given; wraps between facts; one VoiceOver label | Your places | Built |
| `PlaceRow` | `Components/PlaceRow.swift` | Well, 8 to the name (16 medium) over its facts (14, grey) 4 apart, centred on the well; the `DurationTrail` on the name's baseline at the trailing edge; 4 below; the time moves under the facts at AX sizes; one VoiceOver label ("Kestriva Labs, Work, 31 visits, 148 hours") | Your places (screenshot) | Built |
| `SectionLabel` | `Components/PlaceRow.swift` | A list section's label: 14, grey, set in capitals, read as words; header trait | Your places ("FAVOURITES", "ALL PLACES") | Built |
| `PageHeader` | `Components/PageHeader.swift` | A pushed page's 3D art (40), 10 to the title (`pageTitle`) over a `DotLine` of facts (16 regular, grey) 2 apart, centred on the art | Your places | Built |
| `BackButton` | `Components/Controls.swift` | 40 square, white, radius 12, the design's arrow (22) turned round (flips for right-to-left); 44 to tap; pops the page. The app turns the edge swipe back on under it (`Dwell/App/SwipeBack.swift`) | Your places | Built |
| `FilterChip` | `Components/Controls.swift` | 32 tall, white, radius 12, filter glyph (12, SF Symbol) 6 from the label (14 medium), 10 across; on: navy (`inverseSurface`) with white words (derived). A label for a `Menu` or `Button` | Your places ("Most time", "All categories", "Favourites") | Built; on look derived |
| `SearchField` | `Components/Controls.swift` | 44 capsule raised off the page (see Elevation), magnifier (14, `fieldIcon`) 8 from the words (14; placeholder in `placeholder`), 14 in from the leading edge; clear button while there's text; a system `TextField` | Your places | Built; shadow estimated |
| `SkyView` | `Components/SkyView.swift` | Four phases by the clock; cross-fade with travelling sun and moon on a change; settle-in on every open; remembers the last phase shown; crescent moon, stars, horizon band | Today header (user's sky images) | Built |

Still expected from the brief: calendar tiles, the segmented range control, the privacy bar, the dial, calendar match rows.

## Patterns

- **States.** Every screen designs loading, empty, still mapping ("what we're waiting for and how long"), stale (banner over usable content), failed with retry. Permissions are a banner on top, not a state.
- **Voice vs data.** Voiced sentences use `voice` roles through `VoiceText`; numbers use `data` roles and never change with the dial. Where a sentence carries data (Today's headline), `VoicedSentence` slots the data in as runs: the same runs at every dial position, set in full ink with an icon, while the voiced words sit back at 70%.
- **Privacy line.** "Only you can see this." / "Your map is private to you." where it applies.
- **Screen anatomy (Today).** A full-bleed sky for the time of day runs under the status bar behind the header (avatar left, a glass pill right, the headline). The header is pinned: a sheet with 32-pt top corners scrolls up over it and covers it, and pulling down shows the sky's last colour running on below it, never a gap. No pull-to-refresh on a pinned header (its spinner would sit behind the sky); failures offer Retry. On the sheet: white cards with 20-pt corners, separated by dashed hairlines with 20 pt above and below.
- **Getting started (Today, day 0).** Before anything is mapped, Today's sheet holds the shuffling icons (80, 26 below the sheet's top), "Waiting for your first stop" (22 medium, 16 below) and "Mapping right now." with the live dot (6 below); a dashed line; then "Getting started" (a section header, 16 above the steps) and three `StepRow`s 10 apart. The header carries the headline with a 5-minute run.
- **Weekly wrap (Today, from Sunday 6 PM until opened).** The invite leads the sheet, above the live card, 16 below the sheet's top and 41 above the live card (a divider's room, without the line); the rest of Today is unchanged. "Let's go" opens the wrap and the invite goes.
- **First place (Today, install day, minutes in).** Once the first place is mapped, Today takes its usual layout with what there is: the headline names the one place "and nowhere else yet"; the live card times it, its day bar starts when Dwell did (time before install is neither mapped nor a gap) and its legend lists only what's in the bar; the hero stats can read 0m; "This week" keeps its place with a `WaitingCard` and no arrows until insights arrive (first week only; later the engine's fallback keeps the deck full); "Your day" has its one "→ now" row. No confirmation card: Home was saved in onboarding.
- **Floating asks.** A question for the user (the confirmation card) floats 8 pt above the tab bar as a dark card, not inline, and leaves when answered (sliding down behind the bar).
- **Tab bar.** `DwellTabBar` (app target), the design's bar laid over the system `TabView` (whose own bar is hidden): full width, standing on the home indicator with its glass running down behind it, 44-pt top corners, white 20% over a frosted material (`.regularMaterial`, every iOS version; Liquid Glass refracted the content behind it, which the design doesn't) with an ink-10% border (`tabBarStroke`); tabs 101 × 54 (height hugs at larger text), padding 8 across and 6 down, 4 between icon and label, content clipped, spread space-between (first and last flush, so on phones under 428 pt they overlap a few points, unseen); 12 from the bar's top and sides to the tabs and 24 from the tabs to the screen's bottom edge, so they reach 10 pt into the home indicator's strip; the design's icons 22 pt, the same on every tab (dark versions derived by inverting the tones), labels `tab` role, #747474 (`tabInactive`) when not selected; the selected tab's label in ink on a white-80% pill the size of the tab with a #F6F6F6 border and four soft shadows (y 26.05 / 14.37 / 5.86 / 1.2, blur 10.78 / 8.36 / 5.86 / 3.59, black 1 / 2 / 4 / 4%; Figma's fifth is 0% and draws nothing). The pill slides between tabs (`Motion.standard`); under Reduce Motion it appears in place. No haptics on tab changes. A safe-area inset on the `TabView` never reaches the screens inside it (each tab is its own UIKit host), so `RootView` measures the bar and passes its height down (`tabBarHeight`); every screen adds it to its bottom safe area with `.clearsTabBar()` inside its `NavigationStack`, on the root and each pushed page, never on a sheet. Content then scrolls up behind the glass and ends above it.
- **Pushed page (Your places).** No system navigation bar: the design's `BackButton` sits 17 below the status bar (16 from the edge), then 18 to a `PageHeader`, 12 to the search field, 12 to the chips (8 apart, wrapping), 18 to the content. Margins 16. Everything scrolls together, back button included (as drawn; QUESTIONS.md). The edge swipe still goes back. The tab bar stays, as on every pushed page (`.clearsTabBar()`); the frame doesn't show one (QUESTIONS.md).
- **Grouped list (Your places).** One white card, 12 down and 16 across inside; each section a `SectionLabel`, then for each row a dashed line and the row, 12 apart, each row with 4 more below it; 18 between sections. A place that is a favourite shows in Favourites and again in All places. While searching, one list; with the Favourites chip on, only Favourites. Nothing left: a card saying so with "Clear filters". Nothing mapped yet: a `WaitingCard` with the 3D place pin.
- **Stand-ins.** Missing art uses an SF Symbol marked `[ICON NEEDED]` in code; missing copy is marked `[COPY NEEDED]`; pages and sheets without a design open `PendingView` ("Waiting for the design.").

## Change log

| Date | Design | What changed |
| --- | --- | --- |
| 2026-10-29 | Setup | Placeholder tokens, type roles, motion, haptics |
| 2026-10-29 | Today (Figma 69:81) | Colours for background, surface, text, separators, accent, live, work/home/food & drink/transit; radius scale; screen margin; SF Pro Rounded type scale; card, divider, sheen, soft button, section header, day bar, stat tile, insight card and week chart, timeline rows, confirmation card, banner, avatar; motion for MO-01, 02, 05, 06 |
| 2026-11-11 | Sky images (sunrise, day, sunset, night) | Header sky drawn in code with four phases by the clock, sky tokens, MO-12 and MO-13; header ink follows the sky; the sunrise image is gone |

| 2026-11-12 | Today (Figma tick and tile specs) | Work is #FA51D0; ticks and swatches get five inner shadows in a per-category glint; hero tiles get the disc-and-rays glow behind the icon; the day bar draws with SwiftUI shapes |

| 2026-11-12 | Today (Figma borders, unmapped, nav) | The day bar spans the whole day with unmapped ticks hollow and striped (#DADADA 80%); its box border is ink 5%, dashed lines ink 10%; radius box 14; rays stronger; tab bar outlined icons and rounded labels |

| 2026-11-12 | Today (Figma tab bar) | The design's tab bar replaces the system bar's look; the day bar is back to gaps only for Unmapped; the rays are back to Figma's values |

| 2026-11-12 | Today (tab bar fix) | The tab bar's height now reaches the screens: the confirmation card floats above the bar instead of behind it, and Today's end scrolls clear of it |

| 2026-11-12 | Today (tab spacing, rays, Unmapped) | Tabs 101 × 54 with 8 × 6 padding, 12 from the bar's top and sides, 24 from the screen's bottom; rays 15% ink at the centre; the sample Monday gets a 15m gap so Unmapped shows, small, as in a real day |

| 2026-11-12 | Today (tab bar look, rays) | The tab bar is frosted (regular material) instead of Liquid Glass, with its own ink-10% border token; inactive labels #747474, labels 12 on a 16 line, icons ink; the rays are back to Figma's values |

| 2026-11-12 | Today (confirmation card) | The card follows the new Figma: navy #252537, category art, grey question over the visit, buttons on the same row, warm top light instead of the cyan glow; brief's words kept |

| 2026-11-12 | Today (card shadows, stat digits, sweep) | The card shadow is cast by the card's shape only, so the day bar box and hero tiles no longer shadow the white around them; hero stat numbers use proportional digits; the confirmation card's streaks sweep across it while it waits |

| 2026-11-12 | Today (icons, row well, insight spacing) | The design's icons in place: tab bar, hero tiles (briefcase, sunrise), section headers (calendar, sun with clock), timeline glyphs (buildings, home, cup); the timeline well's border is ink 5% and its glyph 18; an insight's topic and sentence sit 4 apart |

| 2026-11-12 | Today (motion fixes) | Today no longer grows in from the middle at launch (the confirmation card's animation covered the whole screen; the day bar's covered its box); the card slides up on its own; its streaks sweep on a steady loop; the live dot pulses; the live caption drops "· estimate" |

| 2026-11-12 | Today (timeline rows, line icons) | Timeline rows centre their two lines on the 32-pt well and trim the type's spare space, so a row is 32-33 tall as in Figma; transit and gap rows take the same shape; the design's clock, chevron, "This week" arrows and day-pill calendar are in place |

| 2026-11-12 | Today (live status, rays, arrows) | 4 between the timer and its caption (was 16); the live dot loses its static halo and only pulses; the hero tile rays turn a full circle every 24 s; the "This week" arrows sit 8 apart |

| 2026-11-12 | Today (Getting started) | Day 0 gets its own layout from the Figma "Getting Started" frame: icon shuffle, waiting title and live line, numbered Now / Next / Then cards; `step` blue; `LiveDot` moves to DwellUI |

| 2026-11-12 | Today (after a few minutes of getting started) | `WaitingCard` for "This week" before insights exist; the install day's day bar and recap start when Dwell started recording; the headline's "and nowhere else yet" for a single place; design leftovers (legend, "0h 28m", "Yours 28m") follow the brief and the main Today |

| 2026-11-12 | Today (weekly wrap) | `WeeklyWrapCard`, `wrapCentre` and `wrapEdge`, type roles `voiceDisplay` (32) and `action` (18), `.card(fill:)`; the ray shape is shared with the hero tiles |

| 2026-11-12 | Today (icon shuffle timing) | The shuffle slows to one icon every 0.8 s and loses its bounce: smooth spring in, ease-in out, from the user's reference video |

| 2026-11-12 | Today (icon shuffle as a 3D turn) | The shuffle becomes a coin-like turn on the vertical axis, a new icon every 0.7 s, swapping edge-on; the scale-and-fade swap is gone |

| 2026-11-12 | Today (more 3D art) | The headline's clock and the Getting started rocket are the design's; the shuffle turns through house, office, café, a place pin and the map's cells, and takes in new category art by itself |

| 2026-11-12 | Your places (screenshot) | A pushed page: the design's back button, page header (`pageTitle` 24), raised search field (`field`, `fieldIcon`, `placeholder`), filter chips (radius `control` 12), and one card of place rows in Favourites and All places; the timeline row's well and duration become `IconWell` and `DurationTrail` so place rows share them; `DotLine` for dot-separated facts |
