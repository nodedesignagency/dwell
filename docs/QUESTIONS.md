# Open questions

Questions for the user or the client (Zac), and any place a design and the brief disagree. Each answer goes back into the code and this file.

**Reminder:** the user will go through this list once the designs are done. Some questions are not needed; drop them with the user then, not before.

## For the client

1. **The tracking engine and app state are not in this repo.** The repo started empty. The brief says a TestFlight build and a working engine are "available on request". We need the engine's code or API to write the adapter behind `DwellRepository`. Until then screens run on the sample week.
2. **Appendix D, "a real week", was not attached.** The brief says it was sent separately. We use a stand-in week built from the brief's names; the real one has the true string lengths, visits per day and gap frequency.
3. **Bundle identifier and Apple team.** The project uses the placeholder `app.dwell.ios` and no team.
4. **The copy deck.** The brief gives 20 lines (Appendix B) and says the client writes the full deck. Everything else will be marked `[COPY NEEDED]` until it arrives.

## Brief gaps to settle

5. **Calm and Push.** Every string has Peace, Plain and Grind variants, and in-between stops "pick the nearer variant with softer intensifiers". Calm (25) and Push (75) sit exactly between two anchors. Current rule: Calm uses Peace, Push uses Grind, unless the copy deck writes its own Calm or Push line (`VoicedLine` supports both).
6. **Hero stats at Calm, Plain and Push.** Only Peace (work · yours) and Grind (work · sessions) are specified. Built so far: Calm and Plain show work · yours, Push shows work · sessions (`HeroStat.pair`).
7. **Plain and the weekly wrap push.** The dial table says Plain gets "morning recap only", but §10 sends the weekly wrap every Sunday at 6 PM. Does Plain get the Sunday push?
8. **When-In-Use banner timing.** The banner ranks "When-In-Use only" second, but Always is asked on day 1–2 in its own moment. Should the banner wait until that moment has passed?
9. **Duration edge cases.** Whole hours currently read "10h" (not "10h 0m") and anything under a minute reads "<1m". The Today design answers the timer: hours and minutes, no seconds.
10. **Upcoming calendar events.** Match states cover the past (attended, partial, missed, unknown). Does Today show events still to come?
11. **What "yours" means.** The brief never defines it. We count everything mapped except work, home and transit (`DayRecap.yours`). That matches the Today design (57m, the café) and the day-2 line "9h 12m at work, 2h 40m yours", which only adds up without evenings at home. But Peace celebrates "reclaimed evenings", which happen at home. Should home time after work count as yours?
12. **Gap copy in the timeline.** Appendix B voices the gap ("Dwell was asleep for 22m. That time isn't counted." at Peace), but §6 says timeline rows never carry character. Timeline rows use the Plain line at every position; the voiced variants wait for a voiced surface.
13. **Grind live caption away from work.** Appendix B's Grind line is "On the clock since 1:31.", which only fits work. Elsewhere Grind says "At {place} since 1:31." [COPY NEEDED].
14. **"Estimate" at Peace and Grind.** §7.1 says the live timer is "marked as an estimate"; Appendix B has "· estimate" only in the Plain line. VoiceOver says "estimate" at every position; on screen only Plain does. Does the mark need to show at every position?

## For the user

15. **"Unmapped" on the day bar.** You asked to come back to this. We built it as gaps only (time inside the day so far with no record), never the rest of the day still to come. On the sample Monday there are no gaps, so no grey shows. What did the designer mean by Unmapped?
16. **The day pill picks a past day.** Built as you chose: a calendar sheet; a past day shows its headline, day bar, hero stats and timeline, without the live status, insights or confirmation card. The brief puts past days in Time (TI-14), so this is new to the client. Worth checking with Zac.
17. **"This week" over the insight deck.** The deck's title is "This week", but insights cover today too (a new cell, an early exit), and on Monday the chart is last week's Monday to Sunday. Should the title follow the top insight's period?
18. **Assets we couldn't get from Figma.** The Figma MCP Starter plan stopped after four calls. Still needed, exported as PNG at 3× (or PDF): the 3D briefcase and sunrise from the hero stats, the 3D calendar ("This week") and sun-with-clock ("Your day") headers, the four tab icons, the Solar duotone glyphs (buildings, home, cup hot) and the linear clock from the timeline rows. Stand-ins are SF Symbols marked `[ICON NEEDED]`.
19. **Night sunrise.** The header art is a daytime sunrise and has no dark version; dark mode lays 55% black over it. A night version (or one per time of day) would read better.
20. **Contrast.** Secondary text (#8B8B8B) is 3.5:1 on white, below WCAG AA (4.5:1) for the 14-pt times and labels; #737373 would pass. Home blue and Food & drink green on the day bar are about 1.5:1 against white (graphics need 3:1), and green and Transit orange are close for deuteranopia. Built as designed; the legend names carry each category.
21. **Work is pink on the day bar, blue in the week chart.** The design's week bars use the accent blue even when they chart work hours. We kept it (insight charts use the accent), but category colours elsewhere always mean the category.

## Design vs brief

Found in the Today design (Figma 69:81). Settled with the user before building unless marked open.

1. **Live status drops "estimate".** The design reads "At Kestriva Labs since 9:02 AM"; §7.1 and Appendix B mark the timer as an estimate. Built with Appendix B's three voices, Plain including "· estimate". (See 14.)
2. **The headline and live caption don't follow the dial.** The design shows one voice. The headline gets Peace and Grind placeholders [COPY NEEDED]; the caption uses Appendix B.
3. **The timeline shows no gaps and no badges.** §7.1: gaps are shown honestly; approximate stays visibly approximate. Built with gap and transit rows and Approximate / Private / WFH badges, plus "Review this place".
4. **Title Case.** "This Week", "Your Day", "View More", "→ Now" are now sentence case per §8.6.
5. **Confirmation buttons.** The hidden Figma card says "Yes / Wrong place", "Looks right ?" and "47 min at Diggin Cafe". Built with the brief's "Looks right / Pick another", Appendix B's sentence and `9h 32m` durations. Placement (not visible in the design) settled with the user: floating above the tab bar.
6. **Insights lack Share and Not useful.** Settled with the user: a share button by each card's topic, Not useful in the long-press menu.
7. **Custom tab bar.** Kept the native `TabView` with the design's icons; on iOS 26 the system bar floats like the design's.
8. **SN Pro on the day pill.** A non-system face for one label; set in SF Pro Rounded instead.
9. **The design's numbers disagree with each other** ("since 9:02" vs "9:30 → now", the café at 57m in the headline and 14m in the timeline). Not a brief conflict; the build shows the sample week's numbers, which agree everywhere.
10. **Insight below the fold.** The brief wants the fresh fact "right after where they are", before scrolling. The design puts the recap headline first and the insight deck third; on a 6.1" phone the deck's sentence is just above the tab bar, on smaller phones and at large text sizes it's below. Built as designed. Open.
