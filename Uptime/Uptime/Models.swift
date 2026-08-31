import Foundation

// MARK: - Session

/// One continuous sitting or standing period recorded by the engine.
struct Session: Codable, Identifiable {
    var id   = UUID()
    /// `true` while the user was standing, `false` while sitting.
    var isStanding: Bool
    var start: Date
    var end:   Date

    /// Wall-clock length of the session in seconds.
    var duration: TimeInterval { end.timeIntervalSince(start) }

    static let storageKey = "uptime_sessions"

    /// Loads all persisted sessions from `UserDefaults`, or returns `[]` on failure.
    static func loadAll() -> [Session] {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode([Session].self, from: data)
        else { return [] }
        return decoded
    }

    /// Encodes and writes `sessions` to `UserDefaults`. Silently no-ops on encode failure.
    static func saveAll(_ sessions: [Session]) {
        guard let data = try? JSONEncoder().encode(sessions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - AppSettings

/// All user-configurable preferences for Uptime.
///
/// Stored as a single JSON blob in `UserDefaults`. Adding new optional properties
/// with default values keeps this Codable-backward-compatible with older stored blobs.
struct AppSettings: Codable {
    var sitMinutes:    Int  = 30    // Minutes per sit cycle
    var standMinutes:  Int  = 15    // Minutes per stand cycle
    var goalPercent:   Int  = 40    // % of tracked time that should be standing
    var launchAtLogin: Bool = false // Registered with SMAppService

    // ── Feature toggles ──────────────────────────────────────────────────
    // Each feature can be turned on/off independently. Defaults are
    // intentionally conservative — only weekSummaryEnabled starts ON.

    /// Show total standing/sitting hours for the week below the bar chart.
    var weekSummaryEnabled:      Bool   = true

    /// Fire a notification every N minutes to nudge a short walk.
    var breakReminderEnabled:    Bool   = false
    var breakReminderMinutes:    Int    = 45

    /// Auto-pause the timer when the Mac has been idle for N minutes.
    var idleDetectionEnabled:    Bool   = false
    var idleThresholdMinutes:    Int    = 5

    /// Split today's stats into AM (before noon) and PM (after noon).
    var morningAfternoonEnabled: Bool   = false

    /// Log each completed session as a Calendar event (requires Calendars
    /// entitlement — add the capability in Xcode Signing & Capabilities).
    var calendarSyncEnabled:     Bool   = false

    /// System sound name played when a goal notification fires.
    /// Options: "default", "Glass", "Ping", "Pop", "Sosumi", "none"
    var notificationSound:       String = "default"

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

// MARK: - ProgressState

/// Persists the user's lifetime XP and level-up bookkeeping.
///
/// XP only ever increases — it is not affected by editing sessions or resetting
/// the activity data. `lastAwardedDayStart` prevents double-awarding XP for the
/// same calendar day across app launches. `lastCelebratedLevel` prevents the
/// level-up toast from appearing again after the user has already seen it.
struct ProgressState: Codable {
    var totalXP:             Int   = 0
    var lastAwardedDayStart: Date? = nil
    var lastCelebratedLevel: Int   = 1

    static let storageKey = "uptime_progress"

    static func load() -> ProgressState {
        guard
            let data    = UserDefaults.standard.data(forKey: storageKey),
            let decoded = try? JSONDecoder().decode(ProgressState.self, from: data)
        else { return ProgressState() }
        return decoded
    }

    static func save(_ state: ProgressState) {
        guard let data = try? JSONEncoder().encode(state) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}

// MARK: - TrackingMode

/// High-level state of the timer. Drives which UI panel is shown in the popover.
enum TrackingMode: String, Codable {
    /// Normal sit/stand cycle — the one-second timer is ticking.
    case active
    /// Timer paused (short break). Time is not tracked.
    case paused
    /// User flagged themselves as away (meeting, errand, etc.). Time not tracked.
    case away
    /// User explicitly ended their work day. Stats are frozen until `startNewDay()`.
    case dayEnded
}

// MARK: - DayData

/// Pre-computed stats for a single calendar day, consumed by `WeeklyBarsView`.
struct DayData: Identifiable {
    let id           = UUID()
    /// Abbreviated weekday label, e.g. `"Mon"`.
    let label:        String
    /// Standing percentage for the day, in the range `0…100`.
    let standPercent: Double
    /// `true` if `standPercent` met or exceeded the user's goal.
    let goalMet:      Bool
    /// `false` when fewer than 60 seconds were tracked — bar is not drawn.
    let hasData:      Bool
    /// `true` for the rightmost bar (today).
    let isToday:      Bool
    /// Total tracked minutes (standing + sitting combined).
    let totalMinutes: Int
}

// MARK: - Helpers

/// Formats a `TimeInterval` (seconds) as a compact human-readable string.
///
/// Examples: `"45m"`, `"1h"`, `"1h 30m"`.
func formatDuration(_ interval: TimeInterval) -> String {
    let minutes = Int(interval) / 60
    guard minutes >= 60 else { return "\(minutes)m" }
    let hours = minutes / 60
    let rem   = minutes % 60
    return rem > 0 ? "\(hours)h \(rem)m" : "\(hours)h"
}
