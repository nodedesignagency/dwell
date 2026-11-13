#!/usr/bin/env bash
# Build Dwell and launch it in the iOS Simulator, without opening Xcode.
#
#   ./scripts/run.sh                    # the booted iPhone simulator, or the newest one
#   ./scripts/run.sh "iPhone 18 Pro"    # a simulator by name
#   DWELL_SKY=night ./scripts/run.sh    # force Today's sky: sunrise, day, sunset or night
#   DWELL_STATE=empty ./scripts/run.sh  # show a state: loading, empty, firstDay, firstPlace, weeklyWrap,
#                                       # failed, offline, transit, lastSeen, locationDenied, whenInUse,
#                                       # preciseOff, motionDenied
#   DWELL_OPEN=you ./scripts/run.sh     # open a page: you (the You tab), places (Your places, from You), time (the Time tab),
#                                       # wrap (last week's wrap, over Today), insight (the Insights page, from Today)
#   DWELL_OPEN=wrap7 ./scripts/run.sh   # the wrap on one of its pages, 1 to 7 (wrap3 is Weekends, wrap7 the postcard)
#   DWELL_FRESH=1 ./scripts/run.sh      # forget what's been seen, so first-sight animations (View more's streaks sweeping away) play again
#
# Needs Xcode 26+ installed (xcodebuild comes with it); the Xcode app can stay closed.
set -euo pipefail
cd "$(dirname "$0")/.."

NAME="${1:-}"
BUNDLE_ID="app.dwell.ios"
DERIVED=".build/xcode" # .build/ is gitignored
UUID_PATTERN='[0-9A-F]{8}-([0-9A-F]{4}-){3}[0-9A-F]{12}'

if [ -n "$NAME" ]; then
  UDID=$(xcrun simctl list devices available | grep -F "    $NAME (" | grep -Eo "$UUID_PATTERN" | head -1 || true)
  [ -n "$UDID" ] || { echo "No simulator called \"$NAME\". Available iPhones:"; xcrun simctl list devices available | grep -E '^ +iPhone'; exit 1; }
else
  UDID=$(xcrun simctl list devices booted | grep -E '^ +iPhone' | grep -Eo "$UUID_PATTERN" | head -1 || true)
  [ -n "$UDID" ] || UDID=$(xcrun simctl list devices available | grep -E '^ +iPhone' | grep -Eo "$UUID_PATTERN" | tail -1 || true)
  [ -n "$UDID" ] || { echo "No iPhone simulator found. Add one in Xcode > Settings > Components."; exit 1; }
fi

echo "Building Dwell…"
mkdir -p "$DERIVED"
LOG="$DERIVED/build.log"
if ! xcodebuild -project Dwell.xcodeproj -scheme Dwell -configuration Debug \
  -destination "id=$UDID" -derivedDataPath "$DERIVED" -quiet build >"$LOG" 2>&1; then
  # Only the errors, not the compiler's command lines; the whole log stays on disk.
  grep -E "error:" "$LOG" | sort -u || tail -40 "$LOG"
  echo "Build failed. Full log: $LOG"
  exit 1
fi

echo "Launching on $(xcrun simctl list devices | grep "$UDID" | sed -E 's/^ +//; s/ \(.*//')…"
xcrun simctl boot "$UDID" 2>/dev/null || true
open -a Simulator --args -CurrentDeviceUDID "$UDID"
xcrun simctl install "$UDID" "$DERIVED/Build/Products/Debug-iphonesimulator/Dwell.app"
xcrun simctl launch --terminate-running-process "$UDID" "$BUNDLE_ID" ${DWELL_SKY:+-DwellSky "$DWELL_SKY"} ${DWELL_STATE:+-DwellState "$DWELL_STATE"} ${DWELL_OPEN:+-DwellOpen "$DWELL_OPEN"} ${DWELL_FRESH:+-DwellFresh YES} >/dev/null
echo "Running."
