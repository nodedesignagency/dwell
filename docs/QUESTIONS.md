# Open questions

Questions for the user or the client (Zac), and any place a design and the brief disagree. Each answer goes back into the code and this file.

## For the client

1. **The tracking engine and app state are not in this repo.** The repo started empty. The brief says a TestFlight build and a working engine are "available on request". We need the engine's code or API to write the adapter behind `DwellRepository`. Until then screens run on the sample week.
2. **Appendix D, "a real week", was not attached.** The brief says it was sent separately. We use a stand-in week built from the brief's names; the real one has the true string lengths, visits per day and gap frequency.
3. **Bundle identifier and Apple team.** The project uses the placeholder `app.dwell.ios` and no team.
4. **The copy deck.** The brief gives 20 lines (Appendix B) and says the client writes the full deck. Everything else will be marked `[COPY NEEDED]` until it arrives.

## Brief gaps to settle

5. **Calm and Push.** Every string has Peace, Plain and Grind variants, and in-between stops "pick the nearer variant with softer intensifiers". Calm (25) and Push (75) sit exactly between two anchors. Current rule: Calm uses Peace, Push uses Grind, unless the copy deck writes its own Calm or Push line (`VoicedLine` supports both).
6. **Hero stats at Calm, Plain and Push.** Only Peace (work · yours) and Grind (work · sessions) are specified.
7. **Plain and the weekly wrap push.** The dial table says Plain gets "morning recap only", but §10 sends the weekly wrap every Sunday at 6 PM. Does Plain get the Sunday push?
8. **When-In-Use banner timing.** The banner ranks "When-In-Use only" second, but Always is asked on day 1–2 in its own moment. Should the banner wait until that moment has passed?
9. **Duration edge cases.** Whole hours currently read "10h" (not "10h 0m") and anything under a minute reads "<1m". Does the live timer show seconds?
10. **Upcoming calendar events.** Match states cover the past (attended, partial, missed, unknown). Does Today show events still to come?

## Design vs brief

None yet.
