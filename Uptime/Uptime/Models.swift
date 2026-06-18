import Foundation

// MARK: - Session
// Represents one continuous sitting or standing period
struct Session: Codable, Identifiable {
    var id   = UUID()
    var isStanding: Bool
    var start: Date
    var end:   Date

    var duration: TimeInterval { end.timeIntervalSince(start) }

    static let storageKey = "uptime_sessions"

    static func loadAll() -> [Session] {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Session].self, from: data)
        else { return [] }
        return decoded
    }

    static func saveAll(_ sessions: [Session]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - AppSettings
struct AppSettings: Codable {
    var sitMinutes:    Int  = 30    // Minutes per sit cycle
    var standMinutes:  Int  = 15    // Minutes per stand cycle
    var goalPercent:   Int  = 40    // % of tracked time that should be standing
    var launchAtLogin: Bool = false // Registered with SMAppService

    static let storageKey = "uptime_settings"

    static func load() -> AppSettings {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(AppSettings.self, from: data)
        else { return AppSettings() }
        return decoded
    }

    static func save(_ settings: AppSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - TrackingMode
enum TrackingMode: String, Codable {
    case active      // Normal sit/stand cycle
    case paused      // Timer on hold (short break)
    case away        // Meeting / other activity
    case dayEnded    // Done for the day
}

// MARK: - DayData
// Summarised stats for one day — used by the weekly bar chart
struct DayData: Identifiable {
    let id           = UUID()
    let label:        String   // e.g. "Mon"
    let standPercent: Double   // 0–100
    let goalMet:      Bool
    let hasData:      Bool     // false if < 1 min tracked
    let isToday:      Bool
}

// MARK: - Helpers
func formatDuration(_ interval: TimeInterval) -> String {
    let minutes = Int(interval) / 60
    guard minutes >= 60 else { return "\(minutes)m" }
    let hours = minutes / 60
    let rem   = minutes % 60
    return rem > 0 ? "\(hours)h \(rem)m" : "\(hours)h"
}
