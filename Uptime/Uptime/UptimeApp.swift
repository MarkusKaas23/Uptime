import SwiftUI
import UserNotifications

@main
struct UptimeApp: App {

    // MARK: - State

    @StateObject private var engine = CycleEngine()

    // MARK: - Scene

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(engine)
                .frame(width: 300)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarIcon(for: engine))
                    .font(.system(size: 13, weight: .medium))
                Text(engine.menuBarLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }

    // MARK: - Helpers

    /// SF Symbol name for the current engine state shown in the menu bar.
    private func menuBarIcon(for engine: CycleEngine) -> String {
        switch engine.trackingMode {
        case .active:
            if engine.goalReached { return "checkmark.circle.fill" }
            return engine.isStanding ? "figure.stand" : "figure.seated.side"
        case .paused:   return "pause.circle"
        case .away:     return "figure.walk"
        case .dayEnded: return "moon"
        }
    }

    // MARK: - Init

    init() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
