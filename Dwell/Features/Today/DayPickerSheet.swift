import DwellCore
import DwellUI
import SwiftUI

/// Picks the day Today shows, from the day pill. Derived: the design has the pill but not
/// what it opens, so this is the system's calendar. Future days can't be picked.
struct DayPickerSheet: View {
    @Binding var pickedDay: DwellDay?
    let today: DwellDay

    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            DatePicker("Day", selection: $date, in: ...today.start(in: calendar), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Palette.accent)
                .padding(.horizontal, Space.l)
                .frame(maxHeight: .infinity, alignment: .top)
                .navigationTitle("Choose a day") // [COPY NEEDED]
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Today") {
                            pickedDay = nil
                            dismiss()
                        }
                        .disabled(pickedDay == nil)
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            pick()
                            dismiss()
                        }
                    }
                }
        }
        .presentationDetents([.height(520), .large])
        .onAppear {
            date = (pickedDay ?? today).start(in: calendar)
        }
    }

    private func pick() {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        let day = DwellDay(year: parts.year ?? today.year, month: parts.month ?? today.month, day: parts.day ?? today.day)
        pickedDay = day < today ? day : nil
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            DayPickerSheet(pickedDay: .constant(nil), today: SampleData.today)
        }
        .samplePreview()
}
