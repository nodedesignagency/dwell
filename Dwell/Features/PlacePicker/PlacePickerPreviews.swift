import DwellCore
import DwellUI
import SwiftUI

// The place picker on the sample's Monday: Brambleline Café, 8:02 to 8:59 AM, the visit Dwell
// isn't sure about ("10-26-1"); the afternoon at Kestriva Labs still going ("10-26-7"); the
// clinic, a private place that never goes on a map ("10-26-5"). The picker has no voiced
// words, so it reads the same at every stop of the dial.

@ViewBuilder
private func picker(
    _ id: VisitID = "10-26-1",
    query: String = "",
    failed: Bool = false,
    saving: Bool = false
) -> some View {
    if let visit = SampleData.todaySnapshot.entries.compactMap(\.visit).first(where: { $0.id == id }) {
        PlacePickerScreen(
            request: PlacePickerRequest(visit: visit, now: SampleData.now),
            query: query, failed: failed, saving: saving,
            onSelect: { _ in }, onClose: {})
    }
}

#Preview("Place picker") {
    picker()
        .samplePreview()
}

#Preview("Place picker · dark") {
    picker()
        .samplePreview()
        .preferredColorScheme(.dark)
}

#Preview("Place picker · AX3") {
    picker()
        .samplePreview()
        .dynamicTypeSize(.accessibility3)
}

#Preview("Place picker · still going") {
    picker("10-26-7")
        .samplePreview()
}

#Preview("Place picker · private place") {
    picker("10-26-5")
        .samplePreview()
}

// MARK: Search

#Preview("Place picker · search") {
    picker(query: "wick")
        .samplePreview()
}

#Preview("Place picker · no matches") {
    picker(query: "Lucali")
        .samplePreview()
}

// MARK: Loading, failing, saving

#Preview("Place picker · loading") {
    picker()
        .samplePreview()
        .environment(\.repository, DemoRepository(.loading))
}

#Preview("Place picker · failed") {
    picker()
        .samplePreview()
        .environment(\.repository, DemoRepository(.failed))
}

#Preview("Place picker · saving") {
    picker(saving: true)
        .samplePreview()
}

#Preview("Place picker · save failed") {
    picker(failed: true)
        .samplePreview()
}

#Preview("Place picker · save failed · dark AX3") {
    picker(failed: true)
        .samplePreview()
        .preferredColorScheme(.dark)
        .dynamicTypeSize(.accessibility3)
}
