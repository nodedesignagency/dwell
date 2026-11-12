import DwellCore
import DwellUI
import SwiftUI

/// Picks the period Time shows, from the date pill. Derived: the design has the pill and its
/// chevron but not what it opens. A day picks from the system's calendar, like Today's day
/// pill; a week, month or year from a list back to when Dwell started. Nothing still to come.
struct PeriodPickerSheet: View {
    let range: TimeRange
    let shown: TimePeriod
    let today: DwellDay
    /// The day Dwell started recording; `nil` when unknown (a year back is offered).
    let earliest: DwellDay?
    /// A day inside the chosen period, or `nil` for the one being lived.
    let onPick: (DwellDay?) -> Void

    @Environment(\.calendar) private var calendar
    @Environment(\.dismiss) private var dismiss
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Group {
                if range == .day {
                    DatePicker("Day", selection: $date, in: firstDate ... today.start(in: calendar), displayedComponents: .date)
                        .datePickerStyle(.graphical)
                        .labelsHidden()
                        .tint(Palette.accent)
                        .padding(.horizontal, Space.l)
                        .frame(maxHeight: .infinity, alignment: .top)
                } else {
                    List(periods) { period in
                        Button {
                            onPick(period.contains(today) ? nil : period.last)
                            dismiss()
                        } label: {
                            HStack {
                                Text(verbatim: TimeCopy.label(period, calendar: calendar))
                                    .textRole(.body)
                                    .foregroundStyle(Palette.textPrimary)
                                Spacer()
                                if period == shown {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(Palette.accent)
                                        .accessibilityHidden(true)
                                }
                            }
                            .contentShape(.rect)
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(period == shown ? .isSelected : [])
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Choose a \(range.noun)") // [COPY NEEDED]
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                if range == .day {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            let day = DwellDay(containing: calendar.date(byAdding: .hour, value: 12, to: calendar.startOfDay(for: date)) ?? date, calendar: calendar)
                            onPick(day < today ? day : nil)
                            dismiss()
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear {
            date = shown.first.start(in: calendar)
        }
    }

    private var firstDate: Date {
        (earliest ?? today.adding(days: -365, in: calendar)).start(in: calendar)
    }

    /// From the one being lived back to the one Dwell started in, newest first.
    private var periods: [TimePeriod] {
        let first = earliest ?? today.adding(days: -365, in: calendar)
        var periods: [TimePeriod] = []
        var period = TimePeriod(range, containing: today, calendar: calendar)
        while period.last >= first, periods.count < 120 {
            periods.append(period)
            period = period.adding(-1, in: calendar)
        }
        return periods
    }
}

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            PeriodPickerSheet(
                range: .week,
                shown: TimePeriod(.week, containing: SampleData.today, calendar: SampleData.calendar),
                today: SampleData.today,
                earliest: DwellDay(year: 2026, month: 8, day: 31),
                onPick: { _ in })
        }
        .samplePreview()
}
