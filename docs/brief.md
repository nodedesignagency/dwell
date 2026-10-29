# Dwell design brief *Bump for your time*

**Version** 2.3**Date** September 2026**For** Breeje Anadkat**Scope** what the app needs and how we think about it**Status** draft, not yet sent

Contents

1. [1. The ask, in one paragraph](#1-the-ask-in-one-paragraph)
2. [2. What we want back from you](#2-what-we-want-back-from-you)
3. [3. What Dwell is](#3-what-dwell-is)
4. [4. Who it is for](#4-who-it-is-for)
5. [5. Design goals, in priority order](#5-design-goals-in-priority-order)
6. [6. The tone dial](#6-the-tone-dial)
7. [7. Information architecture](#7-information-architecture)
8. [8. Product rules that constrain design](#8-product-rules-that-constrain-design)
9. [9. Data, in user terms](#9-data-in-user-terms)
10. [10. System surfaces](#10-system-surfaces)
11. [11. Platform constraints](#11-platform-constraints)
12. [12. Scope of the work](#12-scope-of-the-work)
13. [13. How we judge it](#13-how-we-judge-it)
14. [14. Open questions you may answer](#14-open-questions-you-may-answer)
15. [Appendix A: Screen-by-screen requirements](#appendix-a-screen-by-screen-requirements)
16. [Appendix B: Copy starter deck](#appendix-b-copy-starter-deck)
17. [Appendix D: A real week](#appendix-d-a-real-week)
18. [Appendix C: Glossary](#appendix-c-glossary)

This brief describes the product, its rules, and what we want. It deliberately does **not** include the current app's visuals, brand system, or layouts. It does include our product vocabulary and copy voice, because those are product decisions and you will need them. Where our current build already made a visual or structural choice, that choice is not binding on you. Three references are named on purpose: **Bump** (map and scratch-off), **CARROT Weather** (tone dial), and **Apple Screen Time** (the honest breakdown). Study those, not us.

---

## 1. The ask, in one paragraph

Design an iOS app that is **Bump for your time**. A map of your real life that fills in as you live it, a scratch-off world that rewards going places, and underneath it the deepest, most honest breakdown of how you actually spend your hours that anyone has shipped. It must be a complete, delightful product for **one person alone**; the social layer comes later and must never be load-bearing. It has a **tone dial**, in the spirit of CARROT Weather's personality setting, that slides from *Peace* to *Grind* and changes the voice, the stats it celebrates, and the notifications it sends, without changing the data. The current app is accurate and calm and does not spark anything. This engagement exists to make it something people open because they want to.

## 2. What we want back from you

This document says what the app needs and how we think about it. It does not propose phases, a timeline, or a budget. That is yours to propose. Come back with:

- How you would phase the work and what each phase delivers.
- A timeline and a price for each phase.
- Whether you want to design only, or design and build in SwiftUI with Claude Code against our existing app, and the price of each.
- What you need from us to start.

Facts you can rely on: one decision-maker (Zac, product owner), fast turnaround on reviews, a shipping TestFlight build and a working tracking engine available on request, launch market United States (beta seeded in New York) with EU expansion planned. We have no retention or share numbers we trust yet; we will instrument the current build before you start so there is a baseline.

---

## 3. What Dwell is

Dwell runs quietly in the background on an iPhone, notices where you stop and for how long, and turns that into a record of where your life happens. No routes, only places and times. It is free and has no paywall.

Three layers, in priority order:

1. **Where you are and where you've been.** The live place, today's day, the map of your places, the scratch-off of your world.
2. **How you spend your time.** Hours by category, by place, by day, week, month, year. Patterns, records, firsts, anomalies, comparisons to your own past. Your calendar against reality: did you actually go to the meetings you set? Every open teaches you something.
3. **People.** Later. Company, rivals, friends, leaderboards. Designed now as a future layer so the foundation accommodates it; not shipped in v1.

Marketing line (not for App Store metadata, since Screen Time is Apple's name): *Screen time, but for real life.* App Store subtitle: *Where your time really goes.*

**Name and mark.** The name is Dwell and is fixed. A wordmark and a mark exist; we are holding them back until a direction is chosen so they do not steer you. Treat the app icon and the in-app identity as in scope: propose how they should relate, knowing the existing mark may be kept, adapted, or replaced on the strength of what you show us.

### 3.1 The first week

Fun is won or lost before there is much data. This is what the app must feel like day by day. Design for each of these as a real screen, not an empty state with a spinner.

| Day | What exists | What the user sees | The moment |
| --- | --- | --- | --- |
| 0 (install) | Nothing | Onboarding, then Today with "Your day starts here" and a Now / Next / Then checklist. Map shows one covered world with nothing uncovered. | The promise: "Tonight you'll see your first place." |
| 1 | One or two visits, probably home and one other | Today has a live timer and a two-row timeline. The first confirmation card: "Is this home?" Map has one pin and one uncovered cell. First insight is the onboarding series: "First place mapped." | The first cell scratching off. |
| 2 | A full day | The first real day visual. "Is this work?" Insight: "Your first full day: 9h 12m at work, 2h 40m yours." The Always-location upgrade moment appears. | Seeing a whole day of your life as one shape. |
| 3 | Three days | Time shows three bars and says "still learning your week". Streaks show "1 of 3" toward the first qualifying week. Set-your-dial moment if not yet done. Notifications ask, since the first real insight exists. | The first insight in the dial's voice. |
| 5 | A working week | Rhythm still locked ("needs two weeks"). Records wall has its first entries ("Earliest arrival so far · 8:12 AM"). Calendar vs reality has its first matches if a calendar is connected. Map coverage has a number: "1.4% of Brooklyn". | The first record. |
| 7 | One week | The first weekly wrap on Sunday evening: total, day visuals, three superlatives, share. Explorer week streak qualifies if a new place was visited. | The first share. |
| 14 | Two weeks | Rhythm unlocks. Calendar vs reality has patterns. Places over time has deltas. | "Your Tuesdays look like this." |

Rule: on every one of these days, Today shows something the user did not know. If the data cannot support an insight yet, the app says what it is waiting for and how long.

### 3.2 The Bump reference, precisely

Bump (by amo, ex-Zenly) is a friends-location app. We are not building a friends-location app. Borrow these:

| Borrow | Do not borrow |
| --- | --- |
| The map as a place you want to be, not a utility | Live friend location as the core |
| Automatic place detection that feels magical | Chat, stickers, music sharing |
| The scratch map: uncovering the world you've been to, with an exploration percentage | Ghost mode as a concept (we have nothing to hide from because nothing is shared by default) |
| Battery-friendly always-on presence that people trust | School directories, bumping phones |
| Widgets that make the app present when closed |  |
| Motion and physicality: things bounce, snap, and reveal |  |

### 3.3 The CARROT reference, precisely

CARROT Weather ships one dataset with a personality setting (Professional, Friendly, Snarky, Homicidal, Overkill). The personality lives in the headline copy, notifications, empty states, and achievements; it never touches the data. Users choose CARROT *because* of the character. Borrow: one dial that changes voice across the whole app, character kept typographically separate from data, achievements with attitude. Do not borrow: the robot mascot, the politics slider, the meanness. Our dial is not "how rude" but "what do you want from your time".

---

## 4. Who it is for

Two people use the same data through two lenses. The dial between them is continuous, not a binary. Users pick a starting position at onboarding and slide it any time.

### Peace (left end)

Wants to understand their time and protect their calm. Motivated by reclaiming evenings, protected weekends, unhurried mornings. Wants the app to notice rest, not just work. Never wants to be shamed.

> "First weekend without work since March." · "You were home by 6:10 every night this week." · "Three quiet mornings in a row."

### Grind (right end)

Wants proof. Office hours, gym hours, streaks, records, rank. Motivated by being first in and last out, by 10-hour days, by the number going up. Competitive, with a ceiling: nothing celebrates more than 12 hours of work in a day.

> "10h 12m. Longest day yet." · "First one in, four days running." · "Gym 5 of the last 7 days."

### Representative people

- **Maya, 31, product manager, Brooklyn.** Peace. Suspects she works too much, wants a number she trusts and a nudge she does not resent. Will share a "first weekend without work" card.
- **Dev, 26, analyst, Manhattan.** Grind. First job, competitive team. Wants proof he is first in. Will screenshot a streak.
- **Sam, 38, freelance designer, Austin.** Middle of the dial. Works from cafés, wants to see where the day went and which places they keep returning to. Cares most about their map.

The beta launches in the United States. The founders are in the EU and EU expansion is planned, so the privacy rules in §8 are designed to the stricter regime from the start and show up in the UI.

---

## 5. Design goals, in priority order

1. **Single-player is the whole game.** With zero friends and no company, the app must be complete, fun, and worth opening daily. Every social affordance is additive and off by default.
2. **Where you are, first.** The live place and the live timer are the heartbeat. The map is the home the user comes back to. The scratch-off is the reason to go somewhere new.
3. **Deep, honest time.** The breakdown is the product's spine. Report, do not grade. "9h 40m at work," not "You worked too much." Gaps are shown as gaps. Approximate is visibly approximate.
4. **Every open teaches you something.** Before the user scrolls, Today shows a fresh, specific fact about their own life, right after where they are. Never an empty feed, never a repeat.
5. **The dial changes the voice, never the data.** Peace and Grind see the same numbers with different framing, celebrations, and notifications.
6. **Alive when closed.** Live Activity, widgets, a morning notification. The app should feel like it is running even when you are not looking.
7. **Collectible.** Places, scratched cells, streaks, badges, records accumulate visibly.
8. **Shareable by design.** Insights, wraps, records, badges, and scratch-map progress render to images people post.
9. **Private by default, visibly.** Nothing leaves the phone by default except sync to the user's own account. Home is never a location in any shared surface.

### What "fun" means here

Motion with purpose: a timer that ticks, a bar that fills, a cell that scratches off, a record that lands with weight. Personality in the data presentation itself. Moments: closing a day, uncovering a new neighborhood, hitting a streak, seeing a week wrapped. A visual system that photographs well. Warmth.

### What "fun" does not mean here

Mascots. Confetti on every action. Exclamation marks (records may have one). Streak anxiety (streaks are forgiven: one freeze token earned per seven qualifying days, bank of two, never bought). Glorifying overwork. Hiding numbers behind illustration. Dark patterns. Anything to upsell.

---

## 6. The tone dial

This is the feature we most want you to design. A single control, continuous, with named stops. The stops are ours to name in copy, yours to design.

| Position | Working name | Voice | What gets celebrated | Which notifications fire |
| --- | --- | --- | --- | --- |
| 0 | Peace | Soft, unhurried, notices rest | Early exits, work-free evenings, weekends, slow mornings, time with people | Morning recap; never a work-total push; no streak-at-risk |
| 25 | Calm | Warm, plain | Work vs yours, routines kept | Morning recap |
| 50 | Plain | Neutral, factual, no personality (CARROT's "Professional") | Nothing in particular; facts only | Morning recap only |
| 75 | Push | Direct, a little competitive | Streaks, records, consistency | Morning recap; streak-at-risk in the evening |
| 100 | Grind | Blunt, proud, a bit cocky | 10h days, first in, rank, records | Morning recap; streak-at-risk; records; rank moves |

The lock-screen text of every push is fixed and neutral ("Dwell update. Open Dwell to see what changed.") for privacy. The dial decides *which* pushes fire and *when*; the voiced sentence renders in-app after the tap.

The same insight at three positions:

| Data | Peace | Plain | Grind |
| --- | --- | --- | --- |
| Left office at 5:52 PM, earliest this week | "Out by 5:52. The evening is yours." | "Office exit 5:52 PM. Earliest this week." | "5:52? Soft. Earliest exit this week." |
| 10h 12m at work, lifetime record | "10h 12m today. That's a lot. Rest tomorrow." | "10h 12m at work. Lifetime record." | "10h 12m. New record. Nobody outworked you today." |
| Skipped gym after 12 days | "First rest day in 12. Bodies need those." | "First missed gym day in 12." | "Streak broken at 12. Back tomorrow." |
| Weekend with zero work | "A whole weekend to yourself. First since March 8." | "Zero work hours Sat–Sun. First since March 8." | "Zero work this weekend. Recharged or slacking? Monday decides." |

Rules for the dial:

- Numbers never change. Only sentences, emphasis, and which stats are chosen.
- Grind never celebrates beyond 12h/day and never shames rest as failure; Peace never shames work.
- Every string in the app has a Peace, Plain, and Grind variant at minimum; the in-between stops blend by picking the nearer variant with softer intensifiers. (We write the copy; you design where character lives and how it stays typographically separate from data.)
- The dial is discoverable in onboarding, adjustable in You, and previewed live: dragging it re-renders today's headline insight in the new voice.
- Character lives in headlines, insight sentences, notifications, empty states, badges, and the weekly wrap. It never lives in numbers, axes, timeline rows, or settings.

---

### 6.1 Sound and haptics

Haptics are part of the voice. Use them where something physical happened, never as decoration.

- A light tap when a confirmation is accepted, a scratch cell uncovers, or the dial passes a named stop.
- A firmer, single impact when a record lands, a badge unlocks, or a streak extends.
- Nothing on scrolling, tab changes, timers ticking, or chart scrubbing beyond the system's own selection feedback.
- No sounds by default. If you propose sounds, they are opt-in, tied to the same three moments as the firm haptic, and silent under the ringer switch.
- Peace and Grind do not change what is felt, only what is said.

## 7. Information architecture

Single-player v1 has four surfaces. Social is a fifth, later. Order is fixed: Today first, You last.

| Surface | Purpose | Question it answers |
| --- | --- | --- |
| **Today** | Right now and today | Where am I, where have I been today, what did I learn? |
| **Map** | Your places and your world | Where does my life happen? How much of my city have I uncovered? |
| **Time** | Over time, deeply | Where does my time go by day, week, month, year, place, and pattern? |
| **You** | Me, my dial, my places, my privacy | Who am I in this app and what does it know? |
| *Compare* (later) | Social | How do I stack up against company, rivals, friends? |

### 7.1 Today

- **Live status.** "At Kestriva Labs since 8:40 AM" with a ticking timer, marked as an estimate. Or "In transit · 12m". Or "Last known: Home · last seen 2:10 PM" when the phone has been quiet. The heartbeat.
- **Today's day bar.** One visual of the day so far by category with durations and total mapped time. The signature visual. Must work at every size from Dynamic Island to share card.
- **Hero stats.** Two big numbers chosen by the dial. Peace: "9h 32m at work · 4h 52m yours". Grind: "9h 32m at work · 2 sessions".
- **The insight.** One to five ranked fresh facts, the top one as hero, in the dial's voice, each with share.
- **Confirmation.** When something needs a yes: "You spent 57m at Brambleline Café. Looks right?" (**Looks right** / **Pick another**), "Is this home?", "Is this work?", "Working from home today?" This is the one piece of work the user does. Make it a game, not a chore.
- **Timeline.** The day as a vertical schedule: each visit with name, span, duration, precision mark, badges (private, WFH, approximate). Gaps shown honestly ("Dwell was asleep · 42m"). Long-press to edit (relabel, split, merge, private, WFH, delete).
- **Calendar against reality.** With a calendar connected, each scheduled event is matched to what actually happened and shown in the timeline: "Design review · 2:00–3:00 · you were there", "Dentist · 4:30 · you were at Kestriva Labs", "Coffee with Sam · 8:30 · left 20 min early". Matching is by time and, when the event has a location, by place. Unmatched events are stated plainly, never as blame.
- **New today.** If a scratch cell or a new place was uncovered today, it shows here and links to the map.

States: first day ("Your day starts here" checklist), degraded permissions (persistent banner, §8.3), quiet day, sync failed, load failed.

### 7.2 Map

The home the user comes back to. Two layers on one map, toggled or blended:

- **Places.** Every recognised place as a marker with a halo sized by time. Tap for a place page: visits, total, streaks at this place, first and last seen, share level. Personal and private places are never on the map. No routes, ever.
- **Scratch-off.** The world as cells that start covered and are uncovered by being there. Three zoom levels with their own coverage percentage: neighborhood (cells \~250 m), city, world (countries). "You've uncovered 3.2% of Brooklyn." A new cell today is a moment. Never uncovers by passing through at speed (transit doesn't count); a stop of 5+ minutes does.
- **Header.** Coverage stat for the current zoom, places count, new this week.
- **Lens reading.** One line in the dial's voice: Peace "31h beyond work this week." Grind "5 returns to Kestriva Labs."
- **Places you return to.** Top five by time.
- **Privacy line.** "Your map is private to you."

States: loading, syncing, failed, empty ("Your map starts with your first place"), populated.

### 7.3 Time

Depth lives here. Everything below is required; how it is organized (one long screen, sub-tabs, cards that expand) is yours.

- **Range.** Day / Week / Month / Year.
- **Breakdown.** Stacked by category for the range, with average line and category filters. Headline number with delta vs prior period, signed, with arrow.
- **Category detail.** Calendar heatmap, records, top places, and for Work: arrival and departure strips (a dot per day, median line), office vs WFH split.
- **Calendar vs reality.** With a calendar connected: meetings attended vs scheduled this period, time in meetings vs time at your desk, the meetings you tend to skip, the ones you leave early, the days your calendar and your day disagree most. "6 of 8 meetings attended this week." "You left the Monday standup early 3 weeks running." Peace notices over-scheduling; Grind notices attendance.
- **Rhythm.** Your typical week as a shape: when you arrive, leave, eat, train, sleep. Weekday vs weekend. "Your Tuesday" vs "your Saturday".
- **Places over time.** Which places are growing or shrinking in your life. "Northline Gym: up 40% this month." "Brambleline Café: not since August."
- **Records wall.** Lifetime bests as a grid. Locked records show what unlocks them.
- **Work vs yours.** Hours at work against hours that are yours, this period, with trend. Two numbers side by side, never a single score or ratio. Peace calls the second number "yours", Grind calls it "off".
- **Year in places.** An annual wrap: places, hours, records, scratch progress, firsts.

States: still mapping, unavailable (retry), stale (banner over a usable chart).

### 7.4 You

- Profile (avatar, username, city) and **the dial** with live preview.
- Streaks (current, best, flame, freeze bank), badges (tier grid with progress), scratch-map badges.
- Saved places and the places manager (rename, category, share level, private, home/work, apply to past).
- Work rules (auto-WFH per weekday, tag a day WFH or PTO, out-by target), Live Activity at the gym.
- Calendar connection: pick which calendars count, whether location matching is on, and a plain statement that event titles stay on the phone and never leave it.
- Battery ledger ("about 1.8% today", bursts, minutes, explanation). Honest and proud.
- Notifications (per type), quiet hours, units, calendar context.
- Privacy center (training consent, export, delete with 30-day grace, sharing defaults, legal).

### 7.5 Compare (later, not v1)

Not in v1. It exists as a working implementation behind an internal build flag and will ship when there are enough real users for company cohorts to mean anything. We include it here so the v1 foundation leaves room for it. Nothing in v1 depends on it.

Company card (average in, out, office hours, WFH, core-hours heatmap, member count; renders only with 5+ verified members, else an industry benchmark in a visibly different style), rivals (up to three, head-to-head), leaderboards (office hours / total work; company / friends / city; your row pinned; Peace flips framing to "most reclaimed evenings"), friends (category-level status, weekly mini bars, mutual consent, report/block). Appendix A.5 has the full sheet.

### 7.6 Onboarding (four steps plus deferred moments)

1. **My world.** Promise plus an example world of made-up places. **Start my world** or **Preview a fictional demo** (no account, no network, gated by "I'm 16 or older").
2. **Account and consent.** Region eligibility (US beta), date of birth entered once and never stored (under 16 stops here and gets a fixed no-data preview), Sign in with Apple, two consent toggles: "Use my visits to run Dwell" (required) and "Help improve Dwell's models" (optional, off, never bundled).
3. **Your places.** Optional: add home, work, gym, school, family by role; star favourites. "Saving a place does not record a visit."
4. **Start my day.** Location When-In-Use with a plain explanation; optional collapsed Motion explainer; **Start my day**. Declining still completes into a degraded state.

Deferred moments: **Set your dial** (first Today open or a step: preview the same sentence sliding from Peace to Grind), **Always-location upgrade** (day 1 to 2, own screen: "See the hours after you close Dwell", places and times only, routes never recorded, gaps stay visible; re-shown at most once per two weeks), **Notifications ask** (when the first real insight is ready), **Re-consent** (blocking, when consent text changes), **Sign in to resume**, account states (checking, confirm age, unavailable, deleted).

---

## 8. Product rules that constrain design

### 8.1 Honesty

Report, do not grade. Gaps are gaps. Approximate is visible. Benchmarks from public data look different from real cohort data. A frozen timer says "last seen", never pretends to run.

### 8.2 Privacy is a feature

- Nothing is shared by default. Friends (later) see category only; home shows as "Home" with no location; personal and private places are never shared and never on any map.
- Share cards never include coordinates, pins, precise home times, or venue names unless the user set that place to venue-level sharing. **Scratch-map shares** show coverage as a silhouette at city level or above, never at neighborhood level, never with pins.
- Model-training consent is separate, unticked, optional, and declining it degrades nothing.
- Every privacy fact is stated plainly where it applies: "Only you can see this."

### 8.3 Permissions are choreographed

The app works and looks complete at every permission level. One persistent, non-modal banner at a time, priority order: location denied, When-In-Use only, precise off, motion denied. Never a blocking modal. Always-location is asked days later, in its own moment.

### 8.4 The ceiling

Nothing, at any dial position, celebrates more than 12 hours of work in a day. Marathoner gold copy still says "take a nap."

### 8.5 No monetisation

Free. No paywall, no purchasable anything. Freeze tokens are earned.

### 8.6 Vocabulary

"place" not "location", "visit" not "check-in", "record visits" not "track", "Looks right / Pick another" not "Confirm / Reject", "only you can see this" not "private mode". Sentence case. One idea per line.

---

## 9. Data, in user terms

- **Categories (fixed):** Work · Home · Food & drink · Shopping · Fitness · Errands · Social · Entertainment · Outdoors · Education · Transit · Travel · Personal · Other. Health and religious fold into Personal on the device. Colour is never the only carrier of identity.
- **Visit:** place, arrival, departure, duration, precision (exact / approximate). Durations as `9h 32m`. Monospaced digits everywhere.
- **Day:** 4:00 AM to 4:00 AM local, so sleep is one block and night shifts get sane days.
- **Place:** name, category, lifetime total, visit count, share level (none / category / venue), home/work labels, favourite, private.
- **Scratch cell:** a geographic cell at neighborhood, city, or country level, uncovered by a stop of 5+ minutes, with the date first uncovered. Coverage % per level. Stored on device and in the user's account, never shared below city level.
- **Calendar match:** an event from a connected calendar paired with a visit. States: attended (there for most of it), partial (arrived late or left early, with the minutes), missed (somewhere else), unknown (no location on the event and no clear match). Event titles and attendees stay on the phone; only the match state and minutes sync.
- **Insight:** a templated novel fact scored by novelty and relevance, rendered in the dial's voice. Families: records, firsts, trends, anomalies, rhythm, places over time, calendar vs reality, scratch progress, comparisons to your own past, periodic (daily recap, weekly wrap, year in places). Fallback chain guarantees the feed is never empty.
- **Streaks:** mode-aware. Peace: out by target, work-free evening, weekend guard. Grind: 10h days, first in, office streak. Both: gym regular, explorer week (a never-before place this week), new-cell week. One freeze per 7 qualifying days, bank of 2, auto-spent.
- **Leaderboards (later):** hours over 12 in a day count as 12 toward rank. A capped row shows "12h+" with a small cap mark in the hours column, so rank and the displayed number never disagree; the true total is visible only on the user's own Time screen.
- **Badges:** bronze / silver / gold. Explorer, Regular, Cartographer (neighborhoods uncovered), Globetrotter (countries), Early Bird, Closer, Houdini, Iron Routine, Homebody, Marathoner, Balanced Month, Streak Keeper, Founding User. Flat, geometric, no mascots, legible at 44pt and glorious at 300pt.

---

## 10. System surfaces

| Surface | Content |
| --- | --- |
| Live Activity / Dynamic Island | Starts on a work or gym visit (gym opt-in). Compact: category icon + estimate timer. Expanded: place, timer, today's total. Freezes to "last seen" when stale. |
| Lock-screen widget | Current place + timer, or today's work total. |
| Home widget, small | Current place and timer, today's day bar, "Work today · 6h 12m". |
| Home widget, medium | This week: seven mini day bars with streak marks; or scratch progress ring. |
| Share cards | 1080×1920 and 1080×1080. Daily recap, weekly wrap (three superlatives, work and yours as two numbers), record, badge, scratch progress (city silhouette), later head-to-head. Category-level only. |
| Notifications | At most one insight push per day at the user's morning; streak-at-risk (opt-in, evening); weekly wrap Sunday 6 PM. OS-visible text is fixed and neutral ("Open Dwell to see what changed"); the real sentence, in the dial's voice, renders in-app. |
| App icon | Light, dark, tinted. Reads at 16px. |
| App Store screenshots | Six to eight from the final design. |

---

## 11. Platform constraints

iOS 17+, SwiftUI, native. System components where they exist. System fonts strongly preferred for body (Dynamic Type); a display face is acceptable if it earns its place. Charts in Swift Charts: one y-axis; at most seven named categories per chart plus a fold bucket called "Everything else" (never "Other", which is a real category); everything tappable or scrubbable. Map in MapKit. SF Symbols for system actions; category icons may be custom. Light and dark from day one. Dynamic Type through accessibility sizes. VoiceOver audio-graphs on every chart. Reduce Motion honored with a real alternative for every animation. Colour-vision-safe palette. Two performance budgets exist so the design does not demand heavy rendering: cold launch to a Today skeleton under 600 ms and share-card render under 300 ms, measured by us on the current build; you do not need to measure them. English at launch; Italian is the first planned localisation, so leave room for longer strings.

---

## 12. Scope of the work

Everything below is in scope. Propose how to sequence it.

- **Direction.** Genuinely different visual directions to choose from, each with a point of view on what "fun" means for this product and how the dial shows up.
- **Design system.** Colour (light and dark), type, spacing, radii, elevation, icons, the category set with a contrast check, chart and map styles. Component library in Figma with variants, Dev Mode on, tokens as JSON.
- **Screens.** Every screen and state in Appendix A, light and dark, at a standard iPhone size and one large accessibility size. The dial rendered at Peace, Plain, and Grind wherever a screen carries voice.
- **Motion.** The timer, the day visual filling, the scratch-off reveal, place reveal on the map, insight arrival, confirmation, badge unlock, streak extend, record landing, weekly wrap, dial drag. Timing, easing, and a reduced-motion alternative for each.
- **System surfaces.** Everything in §10: Live Activity and Dynamic Island, widgets, share card templates, notification presentation, app icon, App Store screenshots.
- **Calendar connection.** The connect flow, the match states in the timeline, and the calendar-vs-reality section of Time.
- **Prototype.** A clickable run through the core loop: open, see where you are, confirm a visit, read an insight, drag the dial, scratch a cell, share.
- **Social (Compare).** Not in v1 and the last thing to design. Appendix A.5 describes it so the v1 foundation leaves room for it.
- **Build, if you want it.** SwiftUI implementation of the design system and the four v1 surfaces against our app state and tracking engine, with Claude Code, on a branch we review.

## 13. How we judge it

Would someone screenshot this and send it to a friend unprompted? Does the first screen teach you something in two seconds? Does it feel alive when nothing is happening? Does it stay honest? Does the dial feel like a personality, not a setting? Is the app complete with zero friends? Does it hold in dark mode, at large text, with reduced motion, in a widget? Can it be built in SwiftUI without heroics?

Targets after launch: D7 retention ≥ 40%, ≥ 1 insight opened per user per day, share exports per weekly active user up from baseline, Always-location grant ≥ 60% by day 3.

---

## 14. Open questions you may answer

Our current build has an answer to some of these. None of those answers bind you.

1. Is the day bar horizontal, a ring, a treemap, or something else? It has to work from Dynamic Island to share card.
2. How do the places layer and the scratch layer coexist on one map without noise?
3. Is the dial a slider, a segmented control with a preview, or something more physical? Where does it live day to day?
4. How does the map earn the daily open when nothing new was uncovered?
5. What does a scratched cell look like at neighborhood, city, and world zoom, and what is the reveal animation?
6. What is the single hero moment the whole app is built around?
7. How should a missed meeting look so it reads as a fact and never as a scolding, at every dial position?

---

## Appendix A: Screen-by-screen requirements

Purpose, required content, actions, states. Layout is yours.

### A.1 Onboarding and account

| # | Screen | Required content | Actions | Notes |
| --- | --- | --- | --- | --- |
| 1 | My world | Promise; example world of made-up places, captioned as made-up | Start my world / Preview a fictional demo | No permissions here |
| 1a | Demo gate (sheet) | "I confirm I am 16 or older" | Enter fictional demo | No account, no network |
| 2 | Account and consent | Region tick; date of birth (once, never stored); Sign in with Apple; core consent (on, required); training consent (off, optional); legal links | Continue to your places | Disabled until sign-in, consent, region |
| 2a | Under 16 | "Account setup stopped." | View a no-data preview | Fixed Today + Time preview with example data |
| 3 | Your places | Add by role; favourite | Add / Continue / Skip | "Saving a place does not record a visit." |
| 4 | Start my day | Location explanation and When-In-Use prompt; collapsed Motion; edit places link | Allow / Open Settings / Start my day | Never Always here |
| — | Set your dial | The dial with one sentence re-rendering live from Peace to Grind | Set / Later | May be a step or a first-open moment |
| — | Always upgrade | "See the hours after you close Dwell"; three promises | Turn on Always / Not now | Day 1–2; ≤ once per 2 weeks |
| — | Notifications ask | When first real insight is ready | Yes / Not now |  |
| — | Re-consent | Core locked on, training editable | Continue | Blocking |
| — | Sign in to resume | Sign in with Apple; optional DOB | Sign in |  |
| — | Account states | Checking; confirm age; unavailable; deleted / erasing | Try again / Confirm / Preview | Full screen, no tabs |

### A.2 Today

| Element | Required content | Actions | States |
| --- | --- | --- | --- |
| Live status | "At {place} since {time}" + estimate timer; or "In transit"; or "Last known: {place} · last seen {time}"; or "Mapping your first place" | Tap → place page | live / transit / stale / unknown / no permission |
| Day bar | Today by category with durations; total mapped | Tap or scrub → callout | empty / partial / full |
| Hero stats | Two numbers chosen by dial | — |  |
| Confirmation | One of four prompts | Looks right / Pick another (→ picker) / Yes / No | none / queued |
| Insight | Hero sentence in dial voice, one supporting number, Share | Tap → detail; Not useful; Share | day 1–3 series; fallback |
| New today | New place or new cell uncovered | Tap → Map | none / some |
| Timeline | Visits with badges, gaps, "Review this place"; current "→ now" | Long-press → edit sheet | empty / partial / complete |
| Calendar matches | Each scheduled event with its match state: attended / partial (minutes late or early) / missed (where you were instead) / unknown | Tap → event detail; Connect calendar when none is connected | not connected / no events today / matched |
| Banner | One degraded state at a time | Fix / Open Settings | 4 types |
| Sync | "Retry sync" line | Retry | offline |
| First day | Now / Next / Then checklist | — |  |
| Empty / failed | "No stops yet today" / "Today couldn't load" | Retry |  |

### A.3 Map

| Element | Required content | Actions | States |
| --- | --- | --- | --- |
| Header | Coverage % at current zoom; places; new this week | Layer toggle (places / scratch / both) |  |
| Map | Place markers with time halos; scratch cells covered / uncovered; place reveal on first load; no POIs, no routes | Pan, zoom, tap place → page, tap cell → date uncovered | loading / syncing / failed / empty / populated |
| Lens reading | One line in dial voice | — |  |
| Places you return to | Top five by time | Tap → place page |  |
| Place page | Name, category, total, visits, first/last seen, streaks here, share level, calendar of visits | Edit, Share level, Private |  |
| Scratch detail | Neighborhood / city / world coverage with %, cells uncovered this week, next milestone | Share (city silhouette) |  |
| Privacy line | "Your map is private to you." | — |  |

### A.4 Time

| Element | Required content | Actions | States |
| --- | --- | --- | --- |
| Range | D / W / M / Y | Select |  |
| Headline | Focus category total, delta vs prior with sign and arrow | Tap → category |  |
| Breakdown | Stacked bars; average line; category filters; scrub callout | Scrub, filter | sparse / single day |
| Category rows | Icon, name, total, delta | Tap → detail |  |
| Category detail | Heatmap, records, top places; Work adds arrival/departure strips and office/WFH | Tap day → visits |  |
| Calendar vs reality | Attended vs scheduled; meeting time vs desk time; meetings you skip or leave early; days calendar and reality disagree most | Tap → that day; Tap a meeting series → its history | not connected (sells the feature) / needs 2+ weeks / populated |
| Rhythm | Typical week shape: arrive, leave, eat, train, sleep; weekday vs weekend | Toggle | needs 2+ weeks |
| Places over time | Growing / shrinking places with deltas | Tap → place page |  |
| Work vs yours | Two numbers side by side; trend; never a ratio | — |  |
| Records wall | Lifetime bests grid; locked show unlock condition | Tap → record card, share |  |
| Year in places | Annual wrap: places, hours, records, coverage, firsts | Share | available after 30 days |
| States | Still mapping; unavailable (retry); stale banner | Retry |  |

### A.5 Compare (later)

| Element | Required content | Actions | States |
| --- | --- | --- | --- |
| Company directory | Search; Join; "Create a company" | Join / Create / Report | none |
| My company | Name, cohort badge, avg office, out, WFH, trend, core-hours heatmap, members, verification form | Verify / Leave / Report | below threshold (progress + benchmark) / live |
| Rivals | Up to 3; W/L; hours | Head-to-head; Add / Remove | none / some / locked |
| Leaderboards | Board switch; scope tabs; opt-in; rows with rank, avatar, name, hours ("12h+" with a cap mark when capped); your row pinned with an explicit rank break; rules link | Opt in/out; Report; Block | empty / hidden / Peace framing |
| Friends | Add by username; invite link; rows with category status + mini bars; requests | Friend page; Remove; Report; Block | empty |
| Report / block | Reason picker | Confirm |  |

### A.6 You

| Element | Required content | Actions | States |
| --- | --- | --- | --- |
| Profile | Avatar, username, city | Edit |  |
| The dial | Continuous slider with named stops; live preview of today's headline | Drag |  |
| Streaks | Name, current, best, flame, freeze bank | Opt out of at-risk push | empty / active / at risk / frozen / broken |
| Badges | Tier grid with progress | Badge detail, share |  |
| Your places | Saved places with favourites | Add / edit / archive | empty |
| Places manager | All places by lifetime time | Place settings sheet | empty |
| Work rules | Auto-WFH per weekday; tag a day; out-by target; Live Activity at the gym | Edit |  |
| Battery | Estimate, bursts, minutes, explanation | — | collecting |
| Settings | 4 notification toggles; quiet hours; units | Edit |  |
| Calendar | Connect; choose calendars; location matching on/off; "Titles never leave your phone" | Connect / Disconnect | not connected / connected |
| Privacy center | Training toggle; export (5 states); delete (30-day grace); sharing defaults read-only; legal links | Toggle / Export / Delete | demo variant |

### A.7 Sheets and overlays

Visit edit · Place picker (nearby, search, somewhere else) · Insight detail + share preview · Place page · Scratch cell detail · Badge detail · Record card · Weekly wrap (multi-step reveal) · Year in places · Set your dial · Always upgrade · Notifications ask.

---

## Appendix B: Copy starter deck

Twenty strings in the three anchor voices, so the dial can be designed without inventing copy. We will write the full deck; this is enough to lay out with. Numbers never change across a row.

| Where | Peace | Plain | Grind |
| --- | --- | --- | --- |
| Onboarding, step 1 | More of your day, quietly. | See where your time goes. | Know exactly where your hours went. |
| First place mapped | Your first place. The map starts here. | First place mapped. | First place down. Keep moving. |
| Is this home? | Looks like home. Is it? | Is this home? | Home? Confirm it. |
| Confirm a visit | Looks like 57m at Brambleline Café. Right? | You spent 57m at Brambleline Café. Looks right? | 57m at Brambleline Café. Looks right? |
| Live status caption | Here since 1:31. | At Kestriva Labs since 1:31 PM · estimate | On the clock since 1:31. |
| Gap in tracking | Dwell was asleep for 22m. That time isn't counted. | Dwell was asleep · 22m | Dwell was asleep · 22m. Not counted. |
| Early exit | Out by 5:52. The evening is yours. | Office exit 5:52 PM. Earliest this week. | 5:52? Soft. Earliest exit this week. |
| Long day, record | 10h 12m today. That's a lot. Rest tomorrow. | 10h 12m at work. Lifetime record. | 10h 12m. New record. Nobody outworked you today. |
| Missed gym | First rest day in 12. Bodies need those. | First missed gym day in 12. | Streak broken at 12. Back tomorrow. |
| Weekend, zero work | A whole weekend to yourself. First since March 8. | Zero work hours Sat–Sun. First since March 8. | Zero work this weekend. Recharged or slacking? Monday decides. |
| Streak extended | Fourteen evenings home by 6:30. | 14-day out-by-6:30 streak. | 14 straight. Don't stop now. |
| Streak at risk (evening) | Still at work at 8. No pressure, just noticing. | Out-by-6:30 streak at risk today. | Streak on the line. Clock out. |
| Freeze used | Yesterday didn't count against you. One freeze left. | Freeze used for yesterday. 1 of 2 left. | Freeze burned. 1 left. Earn it back. |
| New cell uncovered | Somewhere new: Red Hook. | New neighborhood: Red Hook. First time. | Red Hook, uncovered. 3.2% of Brooklyn. |
| Coverage milestone | You've seen 5% of Brooklyn. Slowly is fine. | 5% of Brooklyn uncovered. | 5% of Brooklyn. 95% to go. |
| Calendar, attended | You made the design review. | Design review · attended. | Design review · attended. |
| Calendar, missed | The dentist was at 1. You were at work. No judgment. | Dentist · 1:00 · you were at Kestriva Labs. | Dentist · missed. You were at work. |
| Calendar, left early | Left coffee with Sam 12 minutes early. | Coffee with Sam · left 12m early. | Coffee with Sam · bailed 12m early. |
| Weekly wrap opener | Your week, gently. | This week. | The week. Receipts inside. |
| Empty Today | Nothing yet today. Dwell is waiting for your first stop. | No stops yet today. | No stops yet. Go somewhere. |

Lines that hold at every position: "Only you can see this." · "Dwell records places and times. Never the route between them." · "Dwell used about 1.8% of your battery today." · "Dwell can't see any places. Enable location in Settings."

Lines Dwell never says, at any position: anything that calls rest lazy, anything that calls work a failure, anything about a person's body, anything about money, anything with an exclamation mark except a record.

## Appendix D: A real week

Attached separately: one real week from a founder's account, with place names replaced by plausible ones and the home address removed. It shows real string lengths, real visit counts per day, how often gaps occur, and how the timeline actually looks by 9 PM. Lay out from it, not from idealised data.

## Appendix C: Glossary

| Term | Meaning |
| --- | --- |
| Visit | One stay at one place: arrival, departure, duration |
| Place | A named venue with a category and a share level |
| Day bar | The visual of one day by category |
| The dial | The Peace ↔︎ Grind tone control; framing only |
| Calendar match | A calendar event paired with a visit: attended, partial, missed, or unknown |
| Scratch cell | A map cell uncovered by a 5+ minute stop; three levels: neighborhood, city, country |
| Coverage | Percent of cells uncovered at a level |
| Insight | A templated, novel fact about the user's own data, voiced by the dial |
| Streak / Freeze | Consecutive qualifying days / an earned token that protects one miss |
| Precision | Exact (geofence or GPS fix) or approximate |
| Gap | A period the app received no location, shown honestly |
| Verified member | Company member proven by work email or ten workdays at the office |
| k-threshold | Five verified members before company stats render |