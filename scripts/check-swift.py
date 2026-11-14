#!/usr/bin/env python3
"""Catch the Swift mistakes that have broken the Mac build, before pushing.

Cloud sessions run on Linux, where SwiftUI and the Xcode project can't compile, so app and
DwellUI code first meets a compiler on the user's Mac. Every build failure so far was one of a
few patterns; this finds them by reading the source.

    python3 scripts/check-swift.py          # the whole app and DwellUI
    python3 scripts/check-swift.py FILE...  # just these files

Errors (exit 1) are certain failures: the app target turns on MemberImportVisibility, so a
member from a framework the file doesn't import (UTType's `.png`, `PHPhotoLibrary`...) fails.
Warnings are patterns that have failed before, or that the compiler is known to choke on;
read the line and decide. See CLAUDE.md, "SwiftUI has to build the first time".
"""
import glob
import re
import sys

# A use of a framework's API, and the module the file must import for it. Checked in the app
# target (`Dwell/`), where SWIFT_UPCOMING_FEATURE_MEMBER_IMPORT_VISIBILITY is on.
IMPORT_RULES = [
    (r"exportedContentType:\s*\.|importedContentType:\s*\.|contentType:\s*\.|\bUTType\b|(?<![\w.])\.png\b|(?<![\w.])\.jpeg\b|(?<![\w.])\.plainText\b",
     "UniformTypeIdentifiers"),
    (r"\bPH(PhotoLibrary|Asset\w*|AccessLevel|AuthorizationStatus|Picker\w*)\b", "Photos"),
    (r"\bMF(MessageCompose|MailCompose)\w*", "MessageUI"),
    (r"\bUI(Pasteboard|Image|Application|ViewController|Color|Font|Screen|Device|ImpactFeedbackGenerator|"
     r"SelectionFeedbackGenerator|NotificationFeedbackGenerator|ActivityViewController|ViewRepresentable|"
     r"ViewControllerRepresentable|HostingController|GraphicsImageRenderer)\b|\.pngData\(|\.jpegData\(", "UIKit"),
    (r"\bMK[A-Z]\w+|\bMapCameraPosition\b|\bMapStyle\b|\bMapPolygon\b|\bMapPolyline\b|\bMapCircle\b", "MapKit"),
    (r"\bChart\s*[({]|\b(Bar|Line|Sector|Rule|Point|Area|Rectangle)Mark\b|\.chart[XY](Selection|Scale|Axis)\b|\bAxisMarks\b",
     "Charts"),
    (r"\bAS(Authorization|WebAuthenticationSession)\w*|\bSignInWithAppleButton\b", "AuthenticationServices"),
    (r"\bCL(LocationManager|LocationCoordinate2D|Location|AuthorizationStatus|Geocoder|Placemark)\b", "CoreLocation"),
    (r"\bCM(MotionActivity\w*|Pedometer)\b", "CoreMotion"),
    (r"\bEK(EventStore|Event|Calendar)\b", "EventKit"),
    (r"\bUN(UserNotificationCenter|MutableNotificationContent|NotificationRequest)\b", "UserNotifications"),
    (r"\bActivityAttributes\b|\bActivity<", "ActivityKit"),
    (r"\bWidgetConfiguration\b|\bTimelineProvider\b|\bWidgetCenter\b", "WidgetKit"),
    (r"\bAV(Player|AudioPlayer|CaptureSession)\b", "AVFoundation"),
    (r"\bCIFilter\b|\bCIImage\b|\bCIContext\b", "CoreImage"),
]

# Modules that bring others with them.
REEXPORTS = {
    "MapKit": {"CoreLocation"},
    "UIKit": {"Foundation"},
}

# Destructuring a tuple inside a view builder (`let (a, b) = …` in `body`) isn't allowed.
TUPLE = re.compile(r"^\s*let\s*\(\s*\w+\s*,", re.M)
BUILDER = re.compile(r"var\s+body\s*:\s*some\s+View\s*\{|@ViewBuilder[^{]*\{")


def builder_ranges(code):
    """Where view builders run: each `body` and `@ViewBuilder` block, brace to brace."""
    ranges = []
    for match in BUILDER.finditer(code):
        depth, end = 1, match.end()
        while end < len(code) and depth:
            depth += {"{": 1, "}": -1}.get(code[end], 0)
            end += 1
        ranges.append((match.end(), end))
    return ranges

# Types declared in the app and in DwellUI are main-actor by default (SWIFT_DEFAULT_ACTOR_ISOLATION,
# `.defaultIsolation(MainActor.self)`), and so are their members. Handing one of those functions
# over as a value (`compactMap(Art.illustration)`, d3ba2b8) or a main-actor init as a default
# value (`LaunchPage.init(rawValue:)`, ab2f9b0) fails in Swift 6.
PASSED_FUNCTION = re.compile(
    r"\.(map|compactMap|flatMap|filter|first|contains|sorted|forEach|allSatisfy|reduce)\(\s*([A-Z]\w*)((?:\.\w+)+)\s*\)")


def main_actor_types(paths):
    names = set()
    for path in paths:
        if not (path.startswith("Dwell/") or "/DwellUI/" in path):
            continue
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
        for keyword, name in re.findall(r"^(?:\s*(?:public|private|fileprivate|internal|final|@\w+)\s+)*"
                                         r"(struct|enum|class|extension)\s+([A-Z]\w*)", source, re.M):
            # A type marked nonisolated keeps its members off the main actor.
            if re.search(rf"nonisolated\s+(?:\w+\s+)*{keyword}\s+{name}\b", source):
                continue
            names.add(name)
    return names


def strip_comments(source):
    # Keep line numbers: blank out // comments and /* */ blocks.
    source = re.sub(r"/\*.*?\*/", lambda m: "\n" * m.group(0).count("\n"), source, flags=re.S)
    return re.sub(r"//[^\n]*", "", source)


def strip_strings(code):
    return re.sub(r'"(?:\\.|[^"\\\n])*"', '""', code)


def line_of(text, index):
    return text.count("\n", 0, index) + 1


def check_imports(path, code, imports, errors):
    have = set(imports)
    for module in imports:
        have |= REEXPORTS.get(module, set())
    for pattern, module in IMPORT_RULES:
        if module in have:
            continue
        match = re.search(pattern, code)
        if match:
            errors.append(f"{path}:{line_of(code, match.start())}: error: uses {module} "
                          f"({match.group(0).strip()!r}) without `import {module}` (MemberImportVisibility)")


def check_gradients(path, code, warnings):
    # Long literal gradients have made the type checker give up ("unable to type-check this
    # expression in reasonable time"). Build them from a typed array.
    for match in re.finditer(r"stops:\s*\[", code):
        depth, end = 1, match.end()
        while end < len(code) and depth:
            depth += {"[": 1, "]": -1}.get(code[end], 0)
            end += 1
        stops = len(re.findall(r"Gradient\.Stop\(|\.init\(color:", code[match.end():end]))
        if stops >= 10:
            warnings.append(f"{path}:{line_of(code, match.start())}: warning: a gradient of {stops} literal "
                            f"stops: build them as `let stops: [Gradient.Stop] = …` first")


def main(paths):
    if not paths:
        paths = sorted(glob.glob("Dwell/**/*.swift", recursive=True)
                       + glob.glob("Packages/DwellKit/Sources/DwellUI/**/*.swift", recursive=True))
    errors, warnings = [], []
    every = sorted(glob.glob("Dwell/**/*.swift", recursive=True)
                   + glob.glob("Packages/DwellKit/Sources/DwellUI/**/*.swift", recursive=True))
    main_actor = main_actor_types(every)
    for path in paths:
        with open(path, encoding="utf-8") as handle:
            source = handle.read()
        imports = re.findall(r"^\s*(?:@\w+\s+)*import\s+(\w+)", source, re.M)
        code = strip_strings(strip_comments(source))
        if path.startswith("Dwell/"):
            check_imports(path, code, imports, errors)
        builders = builder_ranges(code)
        for match in TUPLE.finditer(code):
            if any(start <= match.start() < end for start, end in builders):
                warnings.append(f"{path}:{line_of(code, match.start())}: warning: tuple destructuring in a view "
                                f"builder (`let (a, b) = …`) isn't allowed: use two lets or a struct")
        for match in PASSED_FUNCTION.finditer(code):
            if match.group(2) in main_actor and not match.group(3).endswith(".init"):
                warnings.append(f"{path}:{line_of(code, match.start())}: warning: `{match.group(2)}{match.group(3)}` "
                                f"is main-actor and passed as a value: write a closure or a loop")
        check_gradients(path, code, warnings)
    for line in errors + warnings:
        print(line)
    print(f"{len(errors)} error(s), {len(warnings)} warning(s) in {len(paths)} file(s).")
    return 1 if errors else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
