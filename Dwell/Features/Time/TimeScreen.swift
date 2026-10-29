import DwellUI
import SwiftUI

struct TimeScreen: View {
    var body: some View {
        PendingScreen(title: "Time", systemImage: "clock")
    }
}

#Preview {
    TimeScreen()
        .samplePreview()
}
