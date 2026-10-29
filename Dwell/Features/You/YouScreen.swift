import DwellUI
import SwiftUI

struct YouScreen: View {
    var body: some View {
        PendingScreen(title: "You", systemImage: "person")
    }
}

#Preview {
    YouScreen()
        .samplePreview()
}
