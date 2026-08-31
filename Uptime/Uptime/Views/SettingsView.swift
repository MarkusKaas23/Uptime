import SwiftUI

/// Settings panel that slides up from the bottom of the popover.
///
/// All controls are kept in local `@State` and only applied to the engine when
/// the user taps **Save**, preventing partial saves on back-navigation.
struct SettingsView: View {
    @EnvironmentObject var engine: CycleEngine
    @Binding var showSettings: Bool

    // ── Timer sliders ────────────────────────────────────────────────────
    @State private var sitMinutes:   Double = 30
    @State private var standMinutes: Double = 15
    @State private var goalPercent:  Double = 40

    // ── Feature toggles ──────────────────────────────────────────────────
    @State private var weekSummaryEnabled:      Bool   = true
    @State private var breakReminderEnabled:    Bool   = false
    @State private var breakReminderMinutes:    Double = 45
    @State private var idleDetectionEnabled:    Bool   = false
    @State private var idleThresholdMinutes:    Double = 5
    @State private var morningAfternoonEnabled: Bool   = false
    @State private var calendarSyncEnabled:     Bool   = false
    @State private var notificationSound:       String = "default"

    var body: some View {
        VStack(spacing: 0) {

            // ── Back header ───────────────────────────────────────────────
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Back")
                            .font(.system(size: 13))
                    }
                    .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Text("Settings")
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Color.clear.frame(width: 48, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                VStack(spacing: 18) {

                    // ── Presets ───────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 8) {
                        sectionLabel("Quick presets")
                        HStack(spacing: 8) {
                            PresetButton(title: "Starter",
                                         subtitle: "50/10 min",
                                         sit: 50, stand: 10) { applyPreset($0, $1) }
                            PresetButton(title: "Standard",
                                         subtitle: "30/15 min",
                                         sit: 30, stand: 15) { applyPreset($0, $1) }
                            PresetButton(title: "Advanced",
                                         subtitle: "20/15 min",
                                         sit: 20, stand: 15) { applyPreset($0, $1) }
                        }
                    }

                    // ── Sit duration ──────────────────────────────────────
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Sitting duration", systemImage: "figure.seated.side")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(Int(sitMinutes)) min")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.indigo)
                        }
                        Slider(value: $sitMinutes, in: 10...60, step: 5)
                            .tint(.indigo)
                    }

                    // ── Stand duration ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Standing duration", systemImage: "figure.stand")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(Int(standMinutes)) min")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        Slider(value: $standMinutes, in: 5...30, step: 5)
                            .tint(.green)
                    }

                    // ── Weekly goal ───────────────────────────────────────
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Label("Weekly standing goal", systemImage: "target")
                                .font(.system(size: 13))
                            Spacer()
                            Text("\(Int(goalPercent))%")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                        Slider(value: $goalPercent, in: 20...65, step: 5)
                            .tint(.orange)
                        Text("WHO recommends 30–40% of work time standing.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // ── Launch at Login ───────────────────────────────────
                    Toggle(isOn: Binding(
                        get: { engine.settings.launchAtLogin },
                        set: { engine.setLaunchAtLogin($0) }
                    )) {
                        Label("Launch at Login", systemImage: "power")
                            .font(.system(size: 13))
                    }
                    .toggleStyle(.switch)

                    Divider()

                    // ── Features ─────────────────────────────────────────
                    sectionLabel("Features")

                    // Weekly summary
                    featureToggle(
                        isOn: $weekSummaryEnabled,
                        icon: "chart.bar.fill",
                        title: "Weekly summary",
                        subtitle: "Show total hours below the weekly bar chart"
                    )

                    // Break reminders
                    VStack(alignment: .leading, spacing: 8) {
                        featureToggle(
                            isOn: $breakReminderEnabled,
                            icon: "bell.badge.fill",
                            title: "Break reminders",
                            subtitle: "Get a nudge to walk around every so often"
                        )
                        if breakReminderEnabled {
                            HStack {
                                Text("Every \(Int(breakReminderMinutes)) min")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $breakReminderMinutes, in: 15...90, step: 5)
                                    .tint(.orange)
                            }
                            .padding(.leading, 28)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: breakReminderEnabled)

                    // Idle auto-pause
                    VStack(alignment: .leading, spacing: 8) {
                        featureToggle(
                            isOn: $idleDetectionEnabled,
                            icon: "zzz",
                            title: "Idle auto-pause",
                            subtitle: "Pause automatically when your Mac is idle"
                        )
                        if idleDetectionEnabled {
                            HStack {
                                Text("After \(Int(idleThresholdMinutes)) min idle")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .frame(width: 80, alignment: .leading)
                                Slider(value: $idleThresholdMinutes, in: 2...15, step: 1)
                                    .tint(.purple)
                            }
                            .padding(.leading, 28)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: idleDetectionEnabled)

                    // Morning / Afternoon split
                    featureToggle(
                        isOn: $morningAfternoonEnabled,
                        icon: "sun.and.horizon.fill",
                        title: "AM / PM split",
                        subtitle: "Split today's stats into morning and afternoon"
                    )

                    // Calendar sync
                    VStack(alignment: .leading, spacing: 4) {
                        featureToggle(
                            isOn: $calendarSyncEnabled,
                            icon: "calendar.badge.plus",
                            title: "Calendar sync",
                            subtitle: "Log each session as a Calendar event"
                        )
                        if calendarSyncEnabled {
                            Text("⚠ Requires the Calendars capability in Xcode (Signing & Capabilities → + Capability → Calendars).")
                                .font(.system(size: 10))
                                .foregroundColor(.orange)
                                .padding(.leading, 28)
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: calendarSyncEnabled)

                    Divider()

                    // ── Notification sound ────────────────────────────────
                    sectionLabel("Notification sound")
                    VStack(alignment: .leading, spacing: 6) {
                        Picker("", selection: $notificationSound) {
                            Text("Default").tag("default")
                            Text("Glass").tag("Glass")
                            Text("Ping").tag("Ping")
                            Text("Pop").tag("Pop")
                            Text("Sosumi").tag("Sosumi")
                            Text("None").tag("none")
                        }
                        .pickerStyle(.menu)
                        .labelsHidden()

                        Text("Plays when a sit or stand goal is reached.")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    // ── Save ──────────────────────────────────────────────
                    Button {
                        let newSettings = AppSettings(
                            sitMinutes:             Int(sitMinutes),
                            standMinutes:           Int(standMinutes),
                            goalPercent:            Int(goalPercent),
                            launchAtLogin:          engine.settings.launchAtLogin,
                            weekSummaryEnabled:     weekSummaryEnabled,
                            breakReminderEnabled:   breakReminderEnabled,
                            breakReminderMinutes:   Int(breakReminderMinutes),
                            idleDetectionEnabled:   idleDetectionEnabled,
                            idleThresholdMinutes:   Int(idleThresholdMinutes),
                            morningAfternoonEnabled: morningAfternoonEnabled,
                            calendarSyncEnabled:    calendarSyncEnabled,
                            notificationSound:      notificationSound
                        )
                        engine.applySettings(newSettings)
                        withAnimation(.easeInOut(duration: 0.2)) { showSettings = false }
                    } label: {
                        Text("Save")
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.indigo)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)

                    // ── Danger zone ───────────────────────────────────────
                    // Note: clears session history only — XP and level are preserved.
                    Button {
                        engine.sessions = []
                        Session.saveAll([])
                    } label: {
                        Text("Clear all data")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.7))
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
        .onAppear {
            let s = engine.settings
            sitMinutes             = Double(s.sitMinutes)
            standMinutes           = Double(s.standMinutes)
            goalPercent            = Double(s.goalPercent)
            weekSummaryEnabled     = s.weekSummaryEnabled
            breakReminderEnabled   = s.breakReminderEnabled
            breakReminderMinutes   = Double(s.breakReminderMinutes)
            idleDetectionEnabled   = s.idleDetectionEnabled
            idleThresholdMinutes   = Double(s.idleThresholdMinutes)
            morningAfternoonEnabled = s.morningAfternoonEnabled
            calendarSyncEnabled    = s.calendarSyncEnabled
            notificationSound      = s.notificationSound
        }
    }

    // MARK: - Helpers

    /// Updates the sit/stand sliders to preset values with a brief animation.
    private func applyPreset(_ sit: Double, _ stand: Double) {
        withAnimation { sitMinutes = sit; standMinutes = stand }
    }

    /// Styled uppercase section header label used throughout the settings scroll view.
    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(.secondary)
            .textCase(.uppercase)
            .tracking(1.5)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Consistent toggle row used for every optional feature in the settings panel.
    @ViewBuilder
    private func featureToggle(isOn: Binding<Bool>, icon: String,
                               title: String, subtitle: String) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 13))
                    Text(subtitle)
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
        }
        .toggleStyle(.switch)
    }
}

// MARK: - PresetButton

/// Tappable card for a named sit/stand preset (e.g. "Standard — 30/15 min").
private struct PresetButton: View {
    let title:    String
    let subtitle: String
    let sit:      Double
    let stand:    Double
    let onTap:    (Double, Double) -> Void

    var body: some View {
        Button { onTap(sit, stand) } label: {
            VStack(spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}
