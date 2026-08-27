import AppKit          // NSSound for custom notification sounds
import Combine
import CoreGraphics    // idle detection
import EventKit        // calendar sync
import Foundation
import ServiceManagement
import SwiftUI
import UserNotifications

/// Single source of truth for the entire Uptime app.
///
/// `CycleEngine` drives the one-second timer, manages sit/stand sessions,
/// and exposes computed statistics that every view reads via `@EnvironmentObject`.
/// It is the only type in the app that touches `UserDefaults` directly.
class CycleEngine: ObservableObject {

    // MARK: - Published
    @Published var isStanding:     Bool
    @Published var secondsElapsed: Int      // counts UP from 0 each cycle
    @Published var sessions:       [Session]
    @Published var settings:       AppSettings
    @Published var trackingMode:   TrackingMode
    @Published var progress:       ProgressState
    @Published var levelUpEvent:   LevelUpEvent? = nil

    // MARK: - Private
    private var timerCancellable:    AnyCancellable?
    private var currentSessionStart: Date
    private var notificationFired  = false

    // Feature: break reminder
    private var breakReminderElapsed = 0    // seconds since last break reminder

    // Feature: calendar sync
    private let eventStore           = EKEventStore()
    private var calendarAccessGranted = false

    // MARK: - Init
    init() {
        let savedSettings = AppSettings.load()
        let savedSessions = Session.loadAll()
        let savedProgress = ProgressState.load()
        let wasStanding   = UserDefaults.standard.bool(forKey: "uptime_isStanding")
        let sessionStart  = (UserDefaults.standard.object(forKey: "uptime_sessionStart") as? Date) ?? Date()
        let modeRaw       = UserDefaults.standard.string(forKey: "uptime_trackingMode") ?? "active"
        let savedMode     = TrackingMode(rawValue: modeRaw) ?? .active

        self.settings            = savedSettings
        self.sessions            = savedSessions
        self.progress            = savedProgress
        self.isStanding          = wasStanding
        self.currentSessionStart = sessionStart
        self.trackingMode        = savedMode

        // Restore elapsed time since session started
        let elapsed = Int(Date().timeIntervalSince(sessionStart))
        self.secondsElapsed = max(0, elapsed)

        // If we were already past the target when we relaunched, mark notif as fired
        let target = wasStanding ? savedSettings.standMinutes * 60 : savedSettings.sitMinutes * 60
        self.notificationFired = (elapsed >= target)

        // ── Day-change detection ─────────────────────────────────────────
        let sessionDay = Calendar.current.startOfDay(for: sessionStart)
        let today      = Calendar.current.startOfDay(for: Date())
        if sessionDay < today && savedMode != .dayEnded {
            let daysGap = Calendar.current.dateComponents([.day], from: sessionDay, to: today).day ?? 1
            for daysAgo in stride(from: daysGap, through: 1, by: -1) {
                awardXPIfNeeded(daysAgo: daysAgo)
            }
            self.isStanding          = false
            self.secondsElapsed      = 0
            self.notificationFired   = false
            self.currentSessionStart = Date()
            self.trackingMode        = .active
            UserDefaults.standard.set(false,                        forKey: "uptime_isStanding")
            UserDefaults.standard.set(Date(),                       forKey: "uptime_sessionStart")
            UserDefaults.standard.set(TrackingMode.active.rawValue, forKey: "uptime_trackingMode")
        }

        startTimer()
        registerQuitObserver()
        syncLaunchAtLoginStatus()

        // Pre-flight calendar access if already enabled
        if savedSettings.calendarSyncEnabled { requestCalendarAccess() }
    }

    // MARK: - Quit handling
    private func registerQuitObserver() {
        NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil, queue: .main
        ) { [weak self] _ in self?.handleAppQuit() }
    }

    private func handleAppQuit() {
        guard trackingMode == .active else { return }
        let duration = Date().timeIntervalSince(currentSessionStart)
        if duration >= 60 {
            let partial = Session(isStanding: isStanding,
                                  start: currentSessionStart,
                                  end: Date())
            var all = sessions
            all.append(partial)
            let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
            all = all.filter { $0.start >= cutoff }
            Session.saveAll(all)
        }
        UserDefaults.standard.set(TrackingMode.paused.rawValue, forKey: "uptime_trackingMode")
        UserDefaults.standard.synchronize()
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

        // ── Idle detection ───────────────────────────────────────────────
        if settings.idleDetectionEnabled {
            let idle = systemIdleSeconds()
            if idle >= Double(settings.idleThresholdMinutes * 60) {
                pause()
                return
            }
        }

        secondsElapsed += 1

        // ── Break reminder ───────────────────────────────────────────────
        if settings.breakReminderEnabled {
            breakReminderElapsed += 1
            if breakReminderElapsed >= settings.breakReminderMinutes * 60 {
                sendBreakReminder()
                breakReminderElapsed = 0
            }
        }

        // ── Goal notification ────────────────────────────────────────────
        if secondsElapsed >= targetSeconds && !notificationFired {
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

        // Calendar sync: log the finished session
        addCalendarEventIfNeeded(session: finished)

        isStanding          = !isStanding
        currentSessionStart = Date()
        secondsElapsed      = 0
        notificationFired   = false

        UserDefaults.standard.set(isStanding,          forKey: "uptime_isStanding")
        UserDefaults.standard.set(currentSessionStart, forKey: "uptime_sessionStart")
    }

    // MARK: - Pause / Away / End Day
    func pause()  { enterInactiveMode(.paused) }
    func away()   { enterInactiveMode(.away) }
    func endDay() {
        awardXPIfNeeded(daysAgo: 0)
        enterInactiveMode(.dayEnded)
    }

    func resume() {
        currentSessionStart  = Date()
        secondsElapsed       = 0
        notificationFired    = false
        breakReminderElapsed = 0   // reset break timer on resume
        setTrackingMode(.active)
        UserDefaults.standard.set(currentSessionStart, forKey: "uptime_sessionStart")
    }

    func startNewDay() {
        isStanding = false
        resume()
    }

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
        let wasCalendarEnabled = settings.calendarSyncEnabled
        settings = newSettings
        AppSettings.save(newSettings)
        // Re-evaluate notification threshold with new target
        let newTarget = newSettings.standMinutes * 60
        if secondsElapsed < newTarget { notificationFired = false }
        // Request calendar access if newly enabled
        if newSettings.calendarSyncEnabled && !wasCalendarEnabled {
            requestCalendarAccess()
        }
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

    // MARK: - Notifications (goal reached)
    private func sendNotification() {
        let content   = UNMutableNotificationContent()
        // Use system sound or silence depending on setting
        content.sound = settings.notificationSound == "none" ? nil : .default
        if isStanding {
            content.title = "Standing goal reached 🪑"
            content.body  = "You've hit \(settings.standMinutes) min standing. Sit down when ready."
        } else {
            content.title = "Sitting goal reached 🧍"
            content.body  = "You've been sitting \(settings.sitMinutes) min. Stand up when ready."
        }
        let req = UNNotificationRequest(identifier: UUID().uuidString,
                                        content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
        // Play custom NSSound on top of (or instead of) the notification sound
        playSound(settings.notificationSound)
    }

    // MARK: - Break reminder notification
    private func sendBreakReminder() {
        let content   = UNMutableNotificationContent()
        content.title = "Break time! 🚶"
        content.body  = "Take a short walk or stretch — your body will thank you."
        content.sound = settings.notificationSound == "none" ? nil : .default
        let req = UNNotificationRequest(identifier: "break-\(UUID().uuidString)",
                                        content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req)
        playSound(settings.notificationSound)
    }

    // MARK: - Sound helper
    private func playSound(_ name: String) {
        guard name != "default" && name != "none" else { return }
        NSSound(named: NSSound.Name(name))?.play()
    }

    // MARK: - Idle detection
    /// Returns the number of seconds since the most recent user input event
    /// (mouse movement, key press, or scroll wheel), whichever is smallest.
    private func systemIdleSeconds() -> Double {
        let candidates: [Double] = [
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .mouseMoved),
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .keyDown),
            CGEventSource.secondsSinceLastEventType(.combinedSessionState, eventType: .scrollWheel),
        ]
        return candidates.min() ?? 0
    }

    // MARK: - Calendar sync
    /// Request EventKit access. Must be called before writing events.
    /// Requires the "Calendars" capability in Xcode Signing & Capabilities.
    func requestCalendarAccess() {
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async { self?.calendarAccessGranted = granted }
            }
        } else {
            eventStore.requestAccess(to: .event) { [weak self] granted, _ in
                DispatchQueue.main.async { self?.calendarAccessGranted = granted }
            }
        }
    }

    private func addCalendarEventIfNeeded(session: Session) {
        guard settings.calendarSyncEnabled, calendarAccessGranted else { return }
        guard session.duration >= 60 else { return }   // skip micro-sessions

        // Use the default calendar or the first writable one
        guard let calendar = eventStore.defaultCalendarForNewEvents
                          ?? eventStore.calendars(for: .event).first(where: { !$0.isImmutable })
        else { return }

        let event       = EKEvent(eventStore: eventStore)
        event.title     = session.isStanding ? "🧍 Standing (Uptime)" : "🪑 Sitting (Uptime)"
        event.startDate = session.start
        event.endDate   = session.end
        event.calendar  = calendar
        event.notes     = "Logged automatically by Uptime"

        try? eventStore.save(event, span: .thisEvent)
    }

    // MARK: - Session progress
    var targetSeconds: Int {
        isStanding ? settings.standMinutes * 60 : settings.sitMinutes * 60
    }

    var goalReached: Bool {
        secondsElapsed >= targetSeconds
    }

    var sessionProgress: Double {
        guard targetSeconds > 0 else { return 0 }
        return min(1.0, Double(secondsElapsed) / Double(targetSeconds))
    }

    var elapsedLabel: String {
        String(format: "%d:%02d", secondsElapsed / 60, secondsElapsed % 60)
    }

    var menuBarLabel: String {
        switch trackingMode {
        case .active:
            let mins = secondsElapsed / 60
            return "\(mins)m"   // icon switches to checkmark.circle.fill when goal is reached
        case .paused:   return "paused"
        case .away:     return "away"
        case .dayEnded: return "done"
        }
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
                           goalMet: goalMet, hasData: hasData,
                           isToday: daysAgo == 0,
                           totalMinutes: Int(total / 60))
        }
    }

    private var cal: Calendar { .current }

    // MARK: - Weekly totals (for week summary feature)
    var weeklyTotalStandTime: TimeInterval {
        (0..<7).flatMap { sessionsForDay(daysAgo: $0) }
               .filter { $0.isStanding }
               .reduce(0) { $0 + $1.duration }
    }

    var weeklyTotalSitTime: TimeInterval {
        (0..<7).flatMap { sessionsForDay(daysAgo: $0) }
               .filter { !$0.isStanding }
               .reduce(0) { $0 + $1.duration }
    }

    var weeklyTotalTime: TimeInterval {
        (0..<7).flatMap { sessionsForDay(daysAgo: $0) }
               .reduce(0) { $0 + $1.duration }
    }

    // MARK: - Morning / Afternoon split (for AM/PM feature)
    private var noonToday: Date {
        cal.date(bySettingHour: 12, minute: 0, second: 0, of: Date()) ?? Date()
    }

    private var todayAMSessions: [Session] {
        sessionsForDay(daysAgo: 0).filter { $0.start < noonToday }
    }

    private var todayPMSessions: [Session] {
        sessionsForDay(daysAgo: 0).filter { $0.start >= noonToday }
    }

    var amStandTime:    TimeInterval { todayAMSessions.filter {  $0.isStanding }.reduce(0) { $0 + $1.duration } }
    var amSitTime:      TimeInterval { todayAMSessions.filter { !$0.isStanding }.reduce(0) { $0 + $1.duration } }
    var amStandPercent: Double       { standPercent(for: todayAMSessions) }

    var pmStandTime:    TimeInterval { todayPMSessions.filter {  $0.isStanding }.reduce(0) { $0 + $1.duration } }
    var pmSitTime:      TimeInterval { todayPMSessions.filter { !$0.isStanding }.reduce(0) { $0 + $1.duration } }
    var pmStandPercent: Double       { standPercent(for: todayPMSessions) }

    // MARK: - Leveling
    private func awardXPIfNeeded(daysAgo: Int) {
        let dayStart = cal.startOfDay(for: cal.date(byAdding: .day, value: -daysAgo, to: Date())!)
        if let last = progress.lastAwardedDayStart, dayStart <= last { return }
        progress.lastAwardedDayStart = dayStart

        let sesh  = sessionsForDay(daysAgo: daysAgo)
        let total = sesh.reduce(0.0) { $0 + $1.duration }
        guard total >= 60 else {
            ProgressState.save(progress)
            return
        }

        let pct    = standPercent(for: sesh)
        let earned = LevelSystem.dailyXP(standPercent: pct, goalPercent: settings.goalPercent, streak: streak)

        let beforeLevel = LevelSystem.level(for: progress.totalXP)
        progress.totalXP += earned
        let afterLevel = LevelSystem.level(for: progress.totalXP)

        if afterLevel > progress.lastCelebratedLevel {
            let beforeStage = LevelSystem.stage(for: beforeLevel)
            let afterStage  = LevelSystem.stage(for: afterLevel)
            levelUpEvent = LevelUpEvent(newLevel: afterLevel,
                                        xpEarned: earned,
                                        didUnlockNewStage: afterStage > beforeStage,
                                        newStage: afterStage)
            progress.lastCelebratedLevel = afterLevel
        }
        ProgressState.save(progress)
    }

    func dismissLevelUpEvent() { levelUpEvent = nil }

    var level: Int { LevelSystem.level(for: progress.totalXP) }

    var levelProgress: (xpIntoLevel: Int, xpForNextLevel: Int) {
        let p = LevelSystem.progress(for: progress.totalXP)
        return (p.xpIntoLevel, p.xpForNextLevel)
    }

    var levelProgressRatio: Double {
        let p = levelProgress
        return p.xpForNextLevel > 0 ? Double(p.xpIntoLevel) / Double(p.xpForNextLevel) : 0
    }

    // MARK: - Character stage (0 = cave dweller … 3 = champion)
    var characterStage: Int { LevelSystem.stage(for: level) }

    /// Display name and accent colour for the current character stage.
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
    /// Short encouraging message shown below the weekly bars, driven by streak + stage.
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

