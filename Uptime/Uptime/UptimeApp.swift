import SwiftUI
import UserNotifications

@main
struct UptimeApp: App {
    @StateObject private var engine = CycleEngine()

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environmentObject(engine)
                .frame(width: 300)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: menuBarIcon(engine))
                    .font(.system(size: 13, weight: .medium))
                Text(engine.menuBarLabel)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
            }
        }
        .menuBarExtraStyle(.window)
    }

    private func menuBarIcon(_ engine: CycleEngine) -> String {
        switch engine.trackingMode {
        case .active:   return engine.isStanding ? "figure.stand" : "figure.seated.side"
        case .paused:   return "pause.circle"
        case .away:     return "figure.walk"
        case .dayEnded: return "moon"
        }
    }

    init() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
}
