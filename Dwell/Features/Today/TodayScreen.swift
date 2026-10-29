import DwellUI
import SwiftUI

struct TodayScreen: View {
    var body: some View {
        PendingScreen(title: "Today", systemImage: "sun.max")
    }
}

#Preview {
    TodayScreen()
        .samplePreview()
}
