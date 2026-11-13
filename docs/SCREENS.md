# Screens and states

Everything the brief asks the app to show, so nothing is missed. Each design the user sends is mapped here: some rows are designed directly, the rest are derived from those designs' system. When the designs are done, every row still ⬜ in **Design** is a gap to raise with the user.

**Design:** ⬜ not designed yet · 🎨 designed (name the design) · 🔁 derived from another design (name it)
**Built:** ⬜ not started · 🟡 in progress · ✅ done (all states, light and dark, large text, VoiceOver, Reduce Motion, dial variants)

Built 🟡 on a page we finished means the code is complete for every state but hasn't yet compiled in Xcode: cloud sessions can't build SwiftUI. It turns ✅ once the page builds and its previews are checked on a Mac.

Designs so far: **Today** (Figma `WpF9jJZdOG3ox1bR7iMT6o`, node 69:81); Today **"Getting Started"** (Figma, 12 Nov); Today **"After few minutes of getting started"** (screenshot, 12 Nov); Today **"Weekly Wrap"** (screenshot and Figma values, 12 Nov); **Your places** (screenshot, 12 Nov); **You** (screenshot, 12 Nov); **Time** (three screenshots, 12 Nov: the whole page, the part above the fold, and "All categories" at 4×); the **Weekly wrap** flow (screenshot of all eight frames, 13 Nov: the invite, then seven pages) and its first page, **"Weekly Wrap 1"** ("This week.", screenshot, 13 Nov).

Counts: 13 onboarding, 7 first-week moments, 16 Today, 10 Map, 14 Time, 13 You, 10 sheets, 8 system surfaces, 13 motion moments. Compare (social) is listed last and is not v1.

## Cross-cutting (every screen)

| Requirement | Brief |
| --- | --- |
| Light and dark | §11 |
| Standard iPhone size and one accessibility text size | §12 |
| Peace, Plain and Grind wherever a screen carries voice | §6, §12 |
| States: loading, empty, still mapping, stale, failed with retry | §7 |
| One permission banner at a time, never modal: location denied, When-In-Use only, precise off, motion denied | §8.3 |
| VoiceOver labels; audio graphs on every chart | §11 |
| Reduce Motion alternative for every animation | §11 |
| Room for longer strings (Italian is the first localisation) | §11 |

## Onboarding and account (A.1, §7.6)

| ID | Screen | States and contents | Brief | Design | Built |
| --- | --- | --- | --- | --- | --- |
| O-01 | My world | Promise; example world of made-up places, captioned as made-up; Start my world / Preview a fictional demo. No permissions. | A.1 #1 | ⬜ | ⬜ |
| O-02 | Demo gate (sheet) | "I confirm I am 16 or older"; Enter fictional demo | A.1 #1a | ⬜ | ⬜ |
| O-03 | Account and consent | Region tick, date of birth (never stored), Sign in with Apple, core consent (required, on), training consent (optional, off, never bundled), legal links; Continue disabled until sign-in, consent and region | A.1 #2 | ⬜ | ⬜ |
| O-04 | Under 16 | "Account setup stopped."; fixed no-data preview of Today and Time with example data | A.1 #2a | ⬜ | ⬜ |
| O-05 | Your places | Add home, work, gym, school, family by role; favourite; Add / Continue / Skip; "Saving a place does not record a visit." | A.1 #3 | ⬜ (same name as the Your places page in You, Y-06, but a different screen: it adds places by role before any visit) | ⬜ |
| O-06 | Start my day | When-In-Use explanation; collapsed Motion explainer; edit places link; Allow / Open Settings / Start my day; declining completes into a degraded state. Never Always here. | A.1 #4 | ⬜ | ⬜ |
| O-07 | Set your dial | The dial with one sentence re-rendering live Peace → Grind; Set / Later. A step or a first-open moment. | A.1, §6 | ⬜ | ⬜ |
| O-08 | Always upgrade | "See the hours after you close Dwell"; three promises; Turn on Always / Not now. Day 1–2, at most once per two weeks. | A.1 | ⬜ | ⬜ |
| O-09 | Notifications ask | When the first real insight is ready; Yes / Not now | A.1 | ⬜ | ⬜ |
| O-10 | Re-consent | Blocking; core locked on, training editable; Continue | A.1 | ⬜ | ⬜ |
| O-11 | Sign in to resume | Sign in with Apple; optional date of birth | A.1 | ⬜ | ⬜ |
| O-12 | Account states | Full screen, no tabs: checking; confirm age; unavailable; deleted / erasing. Try again / Confirm / Preview | A.1 | ⬜ | ⬜ |
| O-13 | Fictional demo mode | The whole app on made-up data, no account, no network, clearly marked as a demo | §7.6 | ⬜ | ⬜ |

## The first week (§3.1)

Real screens, not empty states with a spinner. Each day Today must show something the user didn't know, or say what it's waiting for and how long.

| ID | Day | What the user sees | Design | Built |
| --- | --- | --- | --- | --- |
| W-0 | 0 (install) | Today: "Your day starts here" with a Now / Next / Then checklist. Map: one covered world, nothing uncovered. "Tonight you'll see your first place." | 🎨 Today: "Getting Started" (Figma, 12 Nov) before the first stop; "After few minutes of getting started" (screenshot, 12 Nov) once the first place is mapped. ⬜ Map | 🟡 Today (`DWELL_STATE=firstDay`, `firstPlace`) |
| W-1 | 1 | Live timer, two-row timeline, "Is this home?", Map with one pin and one uncovered cell, insight "First place mapped." | 🔁 Today from "After few minutes": live timer, short timeline, "This week" waiting card until the engine's insights arrive. ⬜ "Is this home?" (T-04), the "First place mapped." insight (QUESTIONS.md, design vs brief 15), Map | 🟡 Today |
| W-2 | 2 | First whole-day visual, "Is this work?", "Your first full day: 9h 12m at work, 2h 40m yours.", Always upgrade moment | ⬜ | ⬜ |
| W-3 | 3 | Time: three bars, "still learning your week"; streaks "1 of 3"; set-your-dial if not done; notifications ask | 🔁 Time: "Still learning your week · 4 days to go" over the hour grid's first days. ⬜ streaks, dial, notifications | 🟡 Time |
| W-5 | 5 | Rhythm locked ("needs two weeks"); first records ("Earliest arrival so far · 8:12 AM"); first calendar matches; coverage number ("1.4% of Brooklyn") | 🔁 Time: rhythm locked with days to go, the records wall, calendar vs reality's first ring. ⬜ Map's coverage | 🟡 Time |
| W-7 | 7 | First weekly wrap Sunday evening; explorer week streak qualifies | 🎨 Today: the weekly wrap invite (T-16); the wrap's opener, "This week." (S-06). 🔁 a first week counts only the days Dwell was recording ("4 days, 5 places…"). ⬜ the wrap's other six pages, the explorer streak | 🟡 Today (`DWELL_STATE=weeklyWrap`), the wrap (`DWELL_OPEN=wrap`) |
| W-14 | 14 | Rhythm unlocks; calendar vs reality patterns; places over time deltas | 🎨 Time: rhythm, "Worth noticing", places over time | 🟡 Time |

## Today (A.2, §7.1)

| ID | Element | States and contents | Design | Built |
| --- | --- | --- | --- | --- |
| T-01 | Live status | Live ("At {place} since {time}", ticking estimate timer); in transit ("In transit · 12m"); stale ("Last known: Home · last seen 2:10 PM", timer stopped); unknown ("Mapping your first place"); no permission. Tap → place page. | 🎨 Today: live (at work; at home on the install day). 🔁 Today: transit, stale, unknown, no permission | 🟡 |
| T-02 | Day bar | Empty / partial / full; durations by category, total mapped; tap or scrub → callout. Must also work in the Dynamic Island, widgets and share cards. | 🎨 Today: partial, legend, unmapped look; one category on the install day. 🔁 Today: empty, full (past day), callout, gaps as unmapped; the install day counts from when Dwell started, never from 4 AM | 🟡 (`DayBarView`, ready for widgets) |
| T-03 | Hero stats | Two big numbers chosen by the dial (Peace: work · yours; Grind: work · sessions) | 🎨 Today: work · yours (also at 0m · 0m on the install day). 🔁 Today: work · sessions | 🟡 |
| T-04 | Confirmation card | Visit ("You spent 57m at Brambleline Café. Looks right?" Looks right / Pick another → picker); "Is this home?"; "Is this work?"; "Working from home today?" (Yes / No); none / queued | 🎨 Today: visit (Figma card, 12 Nov; brief's words). 🔁 floats above the tab bar. ⬜ Is this home? / work? / WFH? (need a data model) | 🟡 visit only |
| T-05 | Insight | Hero sentence in the dial's voice, one supporting number, Share; up to four more ranked below; Not useful; day 1–3 onboarding series; fallback so it is never empty | 🎨 Today: deck with week chart; "Waiting for your insights" card in the first week ("After few minutes"). 🔁 Today: share, Not useful, lone-number card, Peace and Grind waiting lines [COPY NEEDED] | 🟡 (series and fallback come from the engine) |
| T-06 | New today | New place or new scratch cell → Map; none / some | ⬜ | ⬜ |
| T-07 | Timeline | Visits with name, span, duration, precision mark, badges (private, WFH, approximate); transit; gaps ("Dwell was asleep · 42m"); "Review this place"; current row "→ now"; long-press → visit edit; empty / partial / complete | 🎨 Today: visit rows, View more; a lone "→ now" row. 🔁 Today: transit, gaps, badges, Review this place, empty. ⬜ long-press → visit edit (S-01) | 🟡 |
| T-08 | Calendar matches | In the timeline: attended / partial (minutes late or early) / missed (where you were instead) / unknown; not connected (Connect calendar) / no events today / matched. Tap → event detail. | ⬜ | ⬜ |
| T-09 | Permission banner | Four types, one at a time, Fix / Open Settings | 🔁 Today. 🎨 "Turn on your location" sheet (Figma "Turn Location", 12 Nov): opens over Today once per launch when location is off, and from the banner's button; "Yes, turn on" goes to Settings. 🔁 dark, AX sizes. ⬜ sheets for the other three banners | 🟡 (`DWELL_STATE=locationDenied`) |
| T-10 | Sync | "Retry sync" line when offline | 🔁 Today: stale line, offline state | 🟡 |
| T-11 | First day | Now / Next / Then checklist | 🎨 Today: "Getting Started": headline with a 5-minute run, shuffling icons, "Waiting for your first stop" with the live dot, numbered Now / Next / Then cards. 🔁 Peace and Grind headlines [COPY NEEDED], dark, AX sizes, permission banner | 🟡 |
| T-12 | Empty and failed | "No stops yet today" / "Today couldn't load" + Retry | 🔁 Today | 🟡 |
| T-13 | Quiet day | A day with little movement still teaches something | 🔁 Today (same layout; headline drops absent runs) | 🟡 |
| T-14 | Loading | Skeleton within 600 ms of cold launch | 🔁 Today | 🟡 |
| T-15 | Day picker | The day pill opens a calendar; a past day shows its headline, day bar, hero stats and timeline, without live status, insights or confirmation. Not in the brief (QUESTIONS.md). | 🎨 Today: the pill. 🔁 system calendar sheet | 🟡 |
| T-16 | Weekly wrap invite | Once last week's wrap is ready (Sunday 6 PM on) and until it's opened: a blue card leading the sheet with the week, a voiced invite and "Let's go" → the wrap (S-06). Today only. Not in the brief's Today list; the brief's way in is the Sunday push (§10). | 🎨 Today: "Weekly Wrap" (12 Nov); the first frame of the Weekly wrap flow (13 Nov). 🔁 Peace and Grind (Appendix B's wrap openers), the week as its label, dark, AX sizes; "Let's go" grows the wrap out of the card (iOS 18 and later), and the card leaves Today once the wrap closes | 🟡 (`DWELL_STATE=weeklyWrap`) |

## Map (A.3, §7.2)

| ID | Element | States and contents | Design | Built |
| --- | --- | --- | --- | --- |
| M-01 | Header | Coverage % at the current zoom, places count, new this week; layer toggle places / scratch / both | ⬜ | ⬜ |
| M-02 | Places layer | Markers with halos sized by time; place reveal on first load; tap → place page. No POIs, no routes, no private or personal places. | ⬜ | ⬜ |
| M-03 | Scratch layer | Covered / uncovered cells at neighborhood (~250 m), city and world (countries); tap cell → date uncovered; a new cell is a moment | ⬜ | ⬜ |
| M-04 | Map states | Loading / syncing / failed / empty ("Your map starts with your first place") / populated | ⬜ | ⬜ |
| M-05 | Lens reading | One line in the dial's voice ("31h beyond work this week." / "5 returns to Kestriva Labs.") | ⬜ | ⬜ |
| M-06 | Places you return to | Top five by time → place page | ⬜ (a "See all" can push Your places, Y-06: `YourPlacesScreen` takes the stack's own `openPlace`) | ⬜ |
| M-07 | Place page | Name, category, total, visits, first and last seen, streaks here, share level, calendar of visits; Edit, Share level, Private | ⬜ (Today's rows and live status, and Your places' rows, already open a placeholder) | ⬜ |
| M-08 | Scratch detail | Neighborhood / city / world coverage with %, cells this week, next milestone; Share (city silhouette) | ⬜ (You's "3.2% mapped" opens a placeholder) | ⬜ |
| M-09 | Scratch cell detail | Date first uncovered | ⬜ | ⬜ |
| M-10 | Privacy line | "Your map is private to you." | ⬜ | ⬜ |

## Time (A.4, §7.3)

Built from the Time screenshots (12 Nov): `Dwell/Features/Time/`, data in `DwellCore/Time/` (tested). `DWELL_OPEN=time ./scripts/run.sh` opens it; on the sample's Monday the week has one day, so pick Oct 19 – 25 from the dates for a full week.

| ID | Element | States and contents | Design | Built |
| --- | --- | --- | --- | --- |
| TI-01 | Range | Day / Week / Month / Year | 🎨 Time: the segmented control (`SegmentedPicker`), "Time", the date pill, share on glass. 🔁 the pill's picker (a list of periods back to the install, the system calendar for a day), share opens a stand-in until share cards are designed (S-10) | 🟡 |
| TI-02 | Headline | Focus category total, signed delta vs prior period with arrow; tap → category | 🎨 Time: "This week, 42h 29m at work, up by 2h 44m, and 27h 09m at yours." 🔁 down / as usual / no usual yet, yours leading when there's no work, Peace and Grind [COPY NEEDED], before recording, no stops. ⬜ tap → category (the sentence isn't a control) | 🟡 |
| TI-03 | Breakdown | Stacked bars by category, average line, category filters, scrub callout; sparse / single day; ≤ 7 + Everything else; audio graph | 🎨 Time: "Every hour of the week" grid instead of stacked bars (QUESTIONS.md, design vs brief 37). 🔁 day, month (a thin row a day) and year (a typical day a month); tap a stretch for its times, tap the legend to pick a category out; still learning; audio graph. ⬜ the brief's average line | 🟡 |
| TI-04 | Category rows | Icon, name, total, delta → detail | 🎨 Time: badge, name, time, "↑ 2h 44m longer than usual"; Food & drink opening into Coffee, Drinks, Food. 🔁 Home included, last; the same as usual; no usual yet; AX sizes; collapse | 🟡 (rows open the category detail placeholder) |
| TI-05 | Category detail | Calendar heatmap, records, top places; tap a day → its visits | ⬜ (rows open a placeholder) | ⬜ |
| TI-06 | Work detail | Adds arrival and departure strips (a dot per day, median line) and office vs WFH split | ⬜ | ⬜ |
| TI-07 | Calendar vs reality | Attended vs scheduled, meeting time vs desk time, meetings skipped or left early, days that disagree most; not connected (sells the feature) / needs 2+ weeks / populated; tap → that day; tap a series → its history | 🎨 Time: the ring ("6/8 meetings"), attended / left early / elsewhere, "Worth noticing" with runs and missed meetings. 🔁 not connected, no meetings, patterns waiting (under two weeks), nothing to notice, Peace and Grind notes. ⬜ meeting vs desk time, days that disagree most, taps (QUESTIONS.md, design vs brief 40) | 🟡 |
| TI-08 | Rhythm | Typical week as a shape: arrive, leave, eat, train, sleep; weekday vs weekend toggle; locked "needs two weeks" | 🎨 Time: Weekday / Weekend, the strip, Arrive · Lunch · Leave · Home by. 🔁 weekend (Out · Lunch · Home by), locked with days to go, no workdays yet. ⬜ train and sleep (design vs brief 41) | 🟡 |
| TI-09 | Places over time | Growing and shrinking places with deltas ("Northline Gym: up 40% this month.") → place page | 🎨 Time: badge, name, time over four weeks, "↑ 40%", "Paused · Not since…". 🔁 too soon for trends | 🟡 (rows open the place page placeholder) |
| TI-10 | Work vs yours | Two numbers side by side with trend, never a ratio; Peace says "yours", Grind says "off" | 🎨 Time: "Work and yours", the two tiles (label first), four weeks of bars. 🔁 "Off" and "On and off" at Grind [COPY NEEDED], months, days, years | 🟡 |
| TI-11 | Records wall | Lifetime bests grid; locked records show what unlocks them; tap → record card | 🎨 Time: four won, two locked (Closer, Explorer). 🔁 a new account's all-locked wall, AX sizes one to a row. ⬜ the 3D art ([ICON NEEDED]); tap opens a placeholder (S-04) | 🟡 |
| TI-12 | Year in places | Annual wrap entry point, available after 30 days | 🎨 Time: "2026 in places, so far · 15 places, 3.2% of Brooklyn, 4 records." "Open your year" opens a placeholder (S-07). 🔁 hidden in the first 30 days | 🟡 |
| TI-13 | Time states | Still mapping / unavailable with retry / stale banner over a usable chart | 🔁 Time: skeleton, nothing mapped yet (waiting card), still learning your week, before recording, failed and offline with retry, stale, permission banner | 🟡 |
| TI-14 | Day detail | A past day's visits, reached from heatmaps and charts | ⬜ (Today's day pill shows past days) | ⬜ |

## You (A.6, §7.4)

| ID | Element | States and contents | Design | Built |
| --- | --- | --- | --- | --- |
| Y-01 | Profile | Avatar, username, city; Edit | 🎨 You (screenshot, 12 Nov): "You" and the settings button; the picture as a pin over a faded map of the city with the uncovered cells; "41 places" (→ Your places) and "3.2% mapped" (→ scratch detail, M-08) on glass; name; "@maya • Brooklyn". 🔁 the map centred on the city's middle, never home; loading (skeleton), failed (retry, the dial still works), stale (banner), dark, AX sizes (the two facts move under the city). ⬜ Edit: not in the design, assumed behind the settings button (QUESTIONS.md, design vs brief 34) | 🟡 (`DWELL_OPEN=you`) |
| Y-02 | The dial | Continuous with named stops, live preview of today's headline, light haptic at each stop | 🎨 You: "Your dial" on glass, the three-pill art, the stop's name and line, the arc with five stops and a thumb. 🔁 continuous drag (the nearest stop names it), a tap settles on the nearest stop, `Haptic.dialStop` each time a stop is passed, name and line cross-fade, the art follows the thumb, VoiceOver adjusts a stop at a time, AX sizes (end labels only), dark. ⬜ the live preview of today's headline (QUESTIONS.md, design vs brief 37). The art is the design's icon for each stop (sprout, sun behind clouds, pills, lightning bolt, flame), swapping as the thumb crosses into a stop's half | 🟡 |
| Y-03 | Streaks | Name, current, best, flame, freeze bank (max 2); empty / active / at risk / frozen / broken; opt out of the at-risk push | 🎨 You: one streak leading: its run ("12 evenings"), rule ("Home by 6:30 PM") with the pencil (→ work rules, Y-08), the last seven days as flames, Current / Best / Freezes, "View all" (→ S-09). Opt out of the at-risk push: the "Streak at risk" switch in the dial card. 🔁 a day a freeze covered (grey flame), missed and still-to-come days (outline), which streak leads at each stop, weekly streaks (seven weeks), broken ("0 evenings", best kept), empty (voiced, Peace / Plain / Grind), AX sizes (figures stack). At risk and frozen show in today's flame and the push, not a look of their own (QUESTIONS.md, design vs brief 30) | 🟡 |
| Y-04 | Badges | Tier grid (bronze / silver / gold) with progress → badge detail | 🎨 You: "Badges", "6 of 13" (→ every badge), six in three columns: medal, name, tier • count. 🔁 earned first by tier, then locked ones nearest to unlocking ("Locked • 4 countries", grey medal), every badge locked on day 0, two columns at AX sizes; a tile opens badge detail (S-05, pending). ⬜ art for every badge but Explorer at gold (SF Symbol medals stand in) | 🟡 |
| Y-05 | Scratch-map badges | Cartographer, Globetrotter progress | 🔁 You: in the same grid as any badge, counting cells and countries | 🟡 |
| Y-06 | Your places | Saved places with favourites; Add / edit / archive; empty | 🎨 Your places (screenshot, 12 Nov; the back button's glass from Figma): back button, header (3D sun and clock, "Your places", places count · hours mapped), search, chips (Most time, All categories, Favourites), Favourites section. 🔁 the chips' menus and the Favourites toggle, their "on" look (navy), no matches, empty (waiting card), loading, stale, failed, dark, AX sizes, a private place's "Private". ⬜ Add (by role) and archive: not in the design (QUESTIONS.md, design vs brief 24) | 🟡 (`DWELL_OPEN=places`) |
| Y-07 | Places manager | All places by lifetime time → place settings sheet (rename, category, share level, private, home/work, apply to past); empty | 🎨 Your places: one page with Y-06, "All places" by most time, each row with its category, visits (home: "Since March") and lifetime hours. 🔁 sort by visits or A to Z. ⬜ the place settings sheet: rows open the place page (M-07) instead, whose Edit would hold it (QUESTIONS.md, design vs brief 24) | 🟡 |
| Y-08 | Work rules | Auto-WFH per weekday, tag a day WFH or PTO, out-by target, Live Activity at the gym | ⬜ (You's pencil by "Home by 6:30 PM" opens a placeholder) | ⬜ |
| Y-09 | Calendar | Connect flow; choose calendars; location matching on/off; "Titles never leave your phone"; not connected / connected | ⬜ | ⬜ |
| Y-10 | Battery | "About 1.8% today", bursts, minutes, explanation; collecting | ⬜ | ⬜ |
| Y-11 | Notifications and units | Four notification toggles, quiet hours, units | 🎨 You: three switches in the dial card, the design's own switch: Morning recap (every stop), Streak at risk (Push and Grind, opt-in), New records (Grind). 🔁 a push the dial doesn't send shows off and can't be turned on, its glyph grey; the setting is kept, so it comes back when the dial does. ⬜ the fourth toggle, quiet hours and units (behind settings?) (QUESTIONS.md, design vs brief 27) | 🟡 switches |
| Y-12 | Privacy center | Training toggle; export (5 states); delete with 30-day grace; sharing defaults (read-only); legal links; demo variant | ⬜ | ⬜ |
| Y-13 | Edit profile | Avatar, username, city | ⬜ (no Edit in the You design; assumed behind settings) | ⬜ |

## Sheets and overlays (A.7)

| ID | Sheet | States and contents | Design | Built |
| --- | --- | --- | --- | --- |
| S-01 | Visit edit | Relabel, split, merge, private, WFH, delete | ⬜ | ⬜ |
| S-02 | Place picker | Nearby, search, somewhere else | ⬜ (Today's Pick another and Review this place open a placeholder) | ⬜ |
| S-03 | Insight detail + share preview | The insight, its data, the share card preview | ⬜ (Today's insight tap and share open a placeholder) | ⬜ |
| S-04 | Record card | The record landing, share | ⬜ | ⬜ |
| S-05 | Badge detail | Unlock moment, tier progress, share | ⬜ (You's badge tiles open a placeholder) | ⬜ |
| S-06 | Weekly wrap | Multi-step reveal: total, day visuals, three superlatives, work and yours as two numbers, share | 🎨 Weekly wrap flow (13 Nov): a full-screen story of seven pages, each its own colour, under one header ("Your weekly recap", the week, close on glass, a progress bar). 🎨 Page 1, "This week." ("Weekly Wrap 1", 13 Nov): Appendix B's opener, "7 days, 9 places and every hour in between. Here's how it went.", four pieces of 3D art popping out around it (the designer's direction; which art follows which data comes before hand-off), "Tap to continue". 🔁 tap anywhere to move on, the leading third to go back; the progress bar fills; pages cross-fade; it grows out of the invite card and shrinks back into it (iOS 18 and later; swipe down closes); Peace and Grind [COPY NEEDED]; loading, failed with retry, a first week, a week with no visits; dark (the same colours); AX sizes (the art steps aside, the title stops growing at the largest standard size); VoiceOver (the progress bar adjusts the page, escape closes). ⬜ pages 2–7 (Work and yours, Weekends, Where you spent the most time, Earliest exit, Explorer week, Postcard from your week) hold "Waiting for the design." in the flow | 🟡 page 1 (`DWELL_OPEN=wrap`) |
| S-07 | Year in places | Places, hours, records, coverage, firsts; share | ⬜ | ⬜ |
| S-08 | Calendar event detail | The event, its match state, where you were | ⬜ | ⬜ |
| S-09 | Streak detail | History, freezes used and banked | ⬜ (You's "View all" opens a placeholder) | ⬜ |
| S-10 | Share sheet | Format pick (1080×1920 / 1080×1080), preview, system share | ⬜ | ⬜ |

## System surfaces (§10)

| ID | Surface | States and contents | Design | Built |
| --- | --- | --- | --- | --- |
| X-01 | Live Activity and Dynamic Island | Starts on a work or gym visit (gym opt-in). Compact: category icon + estimate timer. Expanded: place, timer, today's total. Minimal. Lock screen. Freezes to "last seen" when stale. | ⬜ | ⬜ |
| X-02 | Lock-screen widgets | Current place + timer, or today's work total (circular, rectangular, inline) | ⬜ | ⬜ |
| X-03 | Home widget, small | Current place and timer, today's day bar, "Work today · 6h 12m" | ⬜ | ⬜ |
| X-04 | Home widget, medium | Seven mini day bars with streak marks, or scratch progress ring | ⬜ | ⬜ |
| X-05 | Share cards | 1080×1920 and 1080×1080: daily recap, weekly wrap, record, badge, scratch progress (city silhouette). Category level only, render under 300 ms. | ⬜ | ⬜ |
| X-06 | Notifications | Lock-screen text fixed and neutral ("Dwell update. Open Dwell to see what changed."); the voiced sentence renders in-app after the tap | ⬜ | ⬜ |
| X-07 | App icon | Light, dark, tinted; reads at 16 px | ⬜ | ⬜ |
| X-08 | App Store screenshots | Six to eight from the final design | ⬜ | ⬜ |

## Motion (§12)

Each needs timing, easing, a Reduce Motion alternative, and its haptic where one applies.

| ID | Moment | Haptic | Design | Built |
| --- | --- | --- | --- | --- |
| MO-01 | Live timer ticking | none | 🔁 Today | 🟡 |
| MO-02 | Day bar filling | none | 🔁 Today; Time's hour grid sweeps in from 4 AM | 🟡 |
| MO-03 | Scratch-off reveal | light | ⬜ | ⬜ |
| MO-04 | Place reveal on the map | none | ⬜ | ⬜ |
| MO-05 | Insight arrival | none | 🔁 Today (deck paging) | 🟡 |
| MO-06 | Confirmation accepted | light | 🔁 Today | 🟡 |
| MO-07 | Badge unlock | firm | ⬜ | ⬜ |
| MO-08 | Streak extends | firm | ⬜ | ⬜ |
| MO-09 | Record landing | firm | ⬜ | ⬜ |
| MO-10 | Weekly wrap reveal | none | 🎨 the opener's art pops out around its words (the designer's direction, 13 Nov). 🔁 the wrap grows out of the invite (iOS 18 and later), the art floats once out, the progress bar fills, pages cross-fade. Reduce Motion: the wrap appears at once, the art fades in still, the bar fades | 🟡 |
| MO-11 | Dial drag (re-rendering the sentence) | light at each stop | 🔁 You: the thumb follows the finger, the art's pills grow and darken towards the stop, the name and line cross-fade; a tap settles with `Motion.standard`. Reduce Motion: no spring, words cross-fade. ⬜ the sentence itself (design vs brief 26) | 🟡 |
| MO-12 | Sky phase change (sunrise, day, sunset, night) | none | 🎨 user's sky images and direction | 🟡 |
| MO-13 | Sky settles on every open | none | 🎨 user's direction | 🟡 |

## Compare (later, not v1)

Not built in v1 (§7.5). Listed so the foundation leaves room: nothing in v1 depends on it.

| ID | Element | Brief |
| --- | --- | --- |
| C-01 | Company directory (search, join, create, report) | A.5 |
| C-02 | My company (avg in/out, office, WFH, trend, core-hours heatmap, members, verification; below threshold shows progress + benchmark in a different style) | A.5 |
| C-03 | Rivals (up to 3, head-to-head) | A.5 |
| C-04 | Leaderboards (board switch, scope tabs, "12h+" cap mark, your row pinned, Peace framing) | A.5 |
| C-05 | Friends (category status, mini bars, requests) | A.5 |
| C-06 | Report / block | A.5 |
