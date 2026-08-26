import SwiftUI

/// Seven-day bar chart shown in the popover's character section.
///
/// Each bar encodes the standing percentage for one day; a coloured dot below
/// the bar indicates whether the user's daily goal was met.
struct WeeklyBarsView: View {
    @EnvironmentObject var engine: CycleEngine

    // MARK: - Body

    var body: some View {
        let week = engine.weeklyData()

        HStack(alignment: .bottom, spacing: 6) {
            ForEach(week) { day in
                VStack(spacing: 3) {
                    // Bar
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color(nsColor: .separatorColor).opacity(0.25))
                            .frame(height: 40)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(barColor(for: day))
                            .frame(height: day.hasData
                                   ? max(3, CGFloat(day.standPercent / 100) * 40)
                                   : 3)
                            .animation(.easeOut(duration: 0.5), value: day.standPercent)
                    }

                    // Goal dot
                    Circle()
                        .fill(dotColor(for: day))
                        .frame(width: 4, height: 4)

                    // Day label
                    Text(day.label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(day.isToday ? .indigo : .secondary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Helpers

    /// Fill colour for a day's bar: green (goal met), orange (≥50% of goal), red (below half), or clear (no data).
    private func barColor(for day: DayData) -> Color {
        guard day.hasData else { return .clear }
        if day.goalMet { return .green }
        if day.standPercent >= Double(engine.settings.goalPercent) * 0.5 { return .orange }
        return .red
    }

    /// Fill colour for the small dot below each bar: green/red on days with data, separator-grey otherwise.
    private func dotColor(for day: DayData) -> Color {
        guard day.hasData else { return Color(nsColor: .separatorColor) }
        return day.goalMet ? .green : .red
    }
}
