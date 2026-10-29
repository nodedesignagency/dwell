import DwellUI
import SwiftUI

struct YouScreen: View {
    var body: some View {
        PendingScreen(title: "You", systemImage: "person.crop.circle")
    }
}

#Preview {
    YouScreen()
        .samplePreview()
}
