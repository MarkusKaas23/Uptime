import Foundation
import Combine
import UserNotifications
import ServiceManagement

// CycleEngine is the single source of truth for the entire app.
// It drives the countdown timer, manages sessions, and computes
// all the statistics that the views display.
class CycleEngine: ObservableObject {

    // MARK: - Published
    @Published var isStanding:       Bool
    @Published var secondsRemaining: Int
    @Published var sessions:         [Session]
    @Published var settings:         AppSettings
    @Published var trackingMode:     TrackingMode

    // MARK: - Private
    private var timerCancellable:  AnyCancellable?
    private var currentSessionStart: Date
    private var notificationFired = false

    // MARK: - Init
    init() {
        let savedSettings = AppSettings.load()
        let savedSessions = Session.loadAll()
        let wasStanding   = UserDefaults.standard.bool(forKey: "uptime_isStanding")
        let sessionStart  = (UserDefaults.standard.object(forKey: "uptime_sessionStart") as? Date) ?? Date()
        let modeRaw       = UserDefaults.standard.string(forKey: "uptime_trackingMode") ?? "active"
        let savedMode     = TrackingMode(rawValue: modeRaw) ?? .active

        self.settings             = savedSettings
        self.sessions             = savedSessions
        self.isStanding           = wasStanding
        self.currentSessionStart  = sessionStart
        self.trackingMode         = savedMode

        // Restore countdown based on elapsed time
        let elapsed   = Int(Date().timeIntervalSince(sessionStart))
        let cycleSecs = wasStanding ? savedSettings.standMinutes * 60
                                    : savedSettings.sitMinutes   * 60
        self.secondsRemaining = max(0, cycleSecs - elapsed)

        startTimer()
        syncLaunchAtLoginStatus()
    }

    // MARK: - Timer
    private func startTimer() {
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        guard trackingMode == .active else { return }
        if secondsRemaining > 0 {
            secondsRemaining -= 1
            notificationFired = false
        } else if !notificationFired {
            sendNotification()
            notificationFired = true
        }
    }

    // MARK: - Toggle sit / stand
    func toggle() {
        let finished = Session(isStanding: isStanding,
                               start: currentSessionStart,
                               end: Date())
        sessions.append(finished)

        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        sessions = sessions.filter { $0.start >= cutoff }
        Session.saveAll(sessions)

        isStanding          = !isStanding
        currentSessionStart = Date()
        secondsRemaining    = isStanding ? settings.standMinutes * 60
                                         : settings.sitMinutes   * 60
        notificationFired   = false

        UserDefaults.standard.set(isStanding,          forKey: "uptime_isStanding")
        UserDefaults.standard.set(currentSessionStart, forKey: "uptime_sessionStart")
    }

    // MARK: - Pause / Away / End Day
    func pause()  { enterInactiveMode(.paused) }
    func away()   { enterInactiveMode(.away) }
    func endDay() { enterInactiveMode(.dayEnded) }

    func resume() {
        currentSessionStart = Date()
        secondsRemaining    = isStanding ? settings.standMinutes * 60
                                         : settings.sitMinutes   * 60
        notificationFired   = false
        setTrackingMode(.active)
        UserDefaults.standard.set(currentSessionStart, forKey: "uptime_sessionStart")
    }

    func startNewDay() {
        isStanding = false
        resume()
    }

    /// Saves the current partial session (if ≥ 1 min), then switches mode.
    private func enterInactiveMode(_ mode: TrackingMode) {
        let duration = Date().timeIntervalSince(currentSessionStart)
        if duration >= 60 {
            let partial = Session(isStanding: isStanding,
                                  start: currentSessionStart,
                                  end: Date())
            sessions.append(partial)
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            sessions = sessions.filter { $0.start >= cutoff }
            Session.saveAll(sessions)
        }
        setTrackingMode(mode)
    }

    private func setTrackingMode(_ mode: TrackingMode) {
        trackingMode = mode
        UserDefaults.standard.set(mode.rawValue, forKey: "uptime_trackingMode")
    }

    // MARK: - Update settings
    func applySettings(_ newSettings: AppSettings) {
        settings         = newSettings
        AppSettings.save(newSettings)
        secondsRemaining = isStanding ? newSettings.standMinutes * 60
                                      : newSettings.sitMinutes   * 60
    }

    // MARK: - Launch at Login
    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled { try SMAppService.mainApp.register() }
            else       { try SMAppService.mainApp.unregister() }
        } catch { /* best-effort */ }
        settings.launchAtLogin = enabled
        AppSettings.save(settings)
    }

    func syncLaunchAtLoginStatus() {
        let registered = (SMAppService.mainApp.status == .enabled)
        if settings.launchAtLogin != registered {
            settings.launchAtLogin = registered
            AppSettings.save(settings)
        }
    }

    // MARK: - Notification
    private func sendNotification() {
        let content   = UNMutableNotificationContent()
        content.sound = .default
        if isStanding {
            content.title = "Time to sit down 🪑"
            content.body  = "You've been standing for \(settings.standMinutes) min. Rest your legs."
        } else {
            content.title = "Time to stand up! 🧍"
            content.body  = "You've been sitting for \(settings.sitMinutes) min. Get up and move!"
        }
        let req = UNNotificationRequest(identifier: UUID().uuidString,
                                        content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
    }

    // MARK: - Display labels
    var menuBarLabel: String {
        switch trackingMode {
        case .active:   return "\(secondsRemaining / 60)m"
        case .paused:   return "paused"
        case .away:     return "away"
        case .dayEnded: return "done"
        }
    }

    var countdownLabel: String {
        String(format: "%d:%02d", secondsRemaining / 60, secondsRemaining % 60)
    }

    // MARK: - Statistics
    func sessionsForDay(daysAgo: Int) -> [Session] {
        let cal      = Calendar.current
        let target   = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
        let dayStart = cal.startOfDay(for: target)
        let dayEnd   = cal.date(byAdding: .day, value: 1, to: dayStart)!
        let now      = Date()

        var result: [Session] = sessions.compactMap { s in
            guard s.start < dayEnd && s.end > dayStart else { return nil }
            return Session(isStanding: s.isStanding,
                           start: max(s.start, dayStart),
                           end:   min(s.end,   dayEnd))
        }
        if daysAgo == 0 {
            result.append(Session(isStanding: isStanding,
                                  start: max(currentSessionStart, dayStart),
                                  end:   min(now, dayEnd)))
        }
        return result
    }

    func standPercent(for sessions: [Session]) -> Double {
        let standTime = sessions.filter { $0.isStanding }.reduce(0.0) { $0 + $1.duration }
        let total     = sessions.reduce(0.0) { $0 + $1.duration }
        guard total >= 60 else { return 0 }
        return standTime / total * 100
    }

    func weeklyData() -> [DayData] {
        (0..<7).reversed().map { daysAgo -> DayData in
            let sesh    = sessionsForDay(daysAgo: daysAgo)
            let total   = sesh.reduce(0.0) { $0 + $1.duration }
            let pct     = standPercent(for: sesh)
            let hasData = total >= 60
            let goalMet = hasData && pct >= Double(settings.goalPercent)

            let date = cal.date(byAdding: .day, value: -daysAgo, to: Date())!
            let idx  = cal.component(.weekday, from: date) - 1
            let lbl  = String(cal.shortWeekdaySymbols[idx].prefix(3))

            return DayData(label: lbl, standPercent: pct,
                           goalMet: goalMet, hasData: hasData, isToday: daysAgo == 0)
        }
    }

    private var cal: Calendar { .current }

    // MARK: - Character stage (0 = cave dweller … 3 = champion)
    var characterStage: Int {
        let week    = weeklyData()
        let tracked = week.filter { $0.hasData }
        guard !tracked.isEmpty else { return 0 }
        let pct = Double(tracked.filter { $0.goalMet }.count) / Double(tracked.count) * 100
        switch pct {
        case 75...: return 3
        case 50...: return 2
        case 25...: return 1
        default:    return 0
        }
    }

    var stageInfo: (name: String, color: Color) {
        switch characterStage {
        case 0:  return ("The Cave Dweller",     .red)
        case 1:  return ("The Office Slouch",    .orange)
        case 2:  return ("The Upriser",          .blue)
        case 3:  return ("The Posture Champion", .purple)
        default: return ("",                     .gray)
        }
    }

    // MARK: - Streak
    var streak: Int {
        var count = 0
        for daysAgo in 0..<30 {
            let sesh  = sessionsForDay(daysAgo: daysAgo)
            let total = sesh.reduce(0.0) { $0 + $1.duration }
            if total < 60 { if daysAgo == 0 { continue } else { break } }
            if standPercent(for: sesh) >= Double(settings.goalPercent) { count += 1 }
            else { break }
        }
        return count
    }

    // MARK: - Today helpers
    var todayStandTime:    TimeInterval { sessionsForDay(daysAgo: 0).filter {  $0.isStanding }.reduce(0) { $0 + $1.duration } }
    var todaySitTime:      TimeInterval { sessionsForDay(daysAgo: 0).filter { !$0.isStanding }.reduce(0) { $0 + $1.duration } }
    var todayStandPercent: Double       { standPercent(for: sessionsForDay(daysAgo: 0)) }
    var todayGoalMet: Bool {
        let total = sessionsForDay(daysAgo: 0).reduce(0.0) { $0 + $1.duration }
        return total >= 60 && todayStandPercent >= Double(settings.goalPercent)
    }

    // MARK: - Motivation message
    var motivationMessage: String {
        switch (streak, characterStage) {
        case (7..., _): return "🔥 \(streak)-day streak — unstoppable!"
        case (5..., _): return "⚡ \(streak) days strong. Keep it up!"
        case (3..., _): return "💪 \(streak)-day streak! You're building a habit."
        case (_, 3):    return "🏆 Champion-level week. Your future back thanks you."
        case (_, 2):    return "📈 Solid week — you're trending up!"
        case (_, 1):    return "🌱 Progress! Every standing minute counts."
        default:        return "🚀 Ready to rise? Hit the button and stand up!"
        }
    }
}

// Needed for Color in stageInfo
import SwiftUI
