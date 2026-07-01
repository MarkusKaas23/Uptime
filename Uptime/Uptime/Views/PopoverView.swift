import SwiftUI

struct PopoverView: View {
    @EnvironmentObject var engine: CycleEngine
    @State private var showSettings = false
    @State private var showStages   = false

    var body: some View {
        VStack(spacing: 0) {

            // ── 1. Timer / State section ─────────────────────────────────
            Group {
                switch engine.trackingMode {

                case .active:
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(engine.isStanding ? Color.green : Color.red)
                                .frame(width: 7, height: 7)
                            Text("Currently \(engine.isStanding ? "standing" : "sitting")")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                                .textCase(.uppercase)
                                .tracking(1.5)
                        }

                        // Big elapsed timer
                        Text(engine.elapsedLabel)
                            .font(.system(size: 40, weight: .bold, design: .monospaced))
                            .foregroundColor(engine.isStanding ? .green : .red)
                            .animation(.easeInOut(duration: 0.3), value: engine.isStanding)

                        // Progress bar toward goal
                        VStack(spacing: 4) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(Color(nsColor: .separatorColor).opacity(0.4))
                                        .frame(height: 5)
                                    RoundedRectangle(cornerRadius: 3)
                                        .fill(engine.goalReached
                                              ? Color.green
                                              : (engine.isStanding ? Color.green : Color.red))
                                        .frame(width: geo.size.width * engine.sessionProgress,
                                               height: 5)
                                        .animation(.linear(duration: 1), value: engine.sessionProgress)
                                }
                            }
                            .frame(height: 5)

                            if engine.goalReached {
                                Label("Goal reached!", systemImage: "checkmark.circle.fill")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.green)
                            } else {
                                let targetMin = engine.isStanding
                                    ? engine.settings.standMinutes
                                    : engine.settings.sitMinutes
                                Text("Goal: \(targetMin) min")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button { engine.toggle() } label: {
                            Label(
                                engine.isStanding ? "I'm Now Sitting" : "I'm Now Standing!",
                                systemImage: engine.isStanding ? "figure.seated.side" : "figure.stand"
                            )
                            .font(.system(size: 14, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(engine.isStanding ? Color.indigo : Color.green)
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                        // Secondary action bar
                        HStack(spacing: 6) {
                            ModeButton(icon: "pause.fill",  label: "Pause")   { engine.pause() }
                            ModeButton(icon: "figure.walk", label: "Away")    { engine.away() }
                            ModeButton(icon: "moon.fill",   label: "End Day") { engine.endDay() }
                        }
                    }
                    .padding(16)

                case .paused, .away:
                    VStack(spacing: 10) {
                        Image(systemName: engine.trackingMode == .away ? "figure.walk" : "pause.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.orange)
                        Text(engine.trackingMode == .away ? "Away" : "Paused")
                            .font(.system(size: 22, weight: .bold))
                        Text("Timer paused — time isn't being tracked.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button { withAnimation { engine.resume() } } label: {
                            Label("Resume", systemImage: "play.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.green)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)

                case .dayEnded:
                    VStack(spacing: 10) {
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.indigo)
                        Text("Day Complete")
                            .font(.system(size: 22, weight: .bold))
                        HStack(spacing: 8) {
                            StatPill(label: "Standing",
                                     value: formatDuration(engine.todayStandTime), color: .green)
                            StatPill(label: "Sitting",
                                     value: formatDuration(engine.todaySitTime),   color: .red)
                            StatPill(label: "Stand %",
                                     value: "\(Int(engine.todayStandPercent))%",   color: .indigo)
                        }
                        if engine.todayGoalMet {
                            Label("Goal met — great work today 🎉", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                        }
                        Button { withAnimation { engine.startNewDay() } } label: {
                            Label("Start New Day", systemImage: "sunrise.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(Color.indigo)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(16)
                }
            }

            Divider()

            // ── 2. Character + Weekly bars ───────────────────────────────
            VStack(spacing: 6) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { showStages = true }
                } label: {
                    CharacterView(stage: engine.characterStage)
                        .frame(width: 100, height: 100)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: engine.characterStage)
                }
                .buttonStyle(.plain)

                HStack(spacing: 4) {
                    Text(engine.stageInfo.name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(engine.stageInfo.color)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }

                Text(engine.motivationMessage)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)

                WeeklyBarsView()
                    .environmentObject(engine)
                    .frame(height: 58)
                    .padding(.top, 4)

                if engine.streak >= 2 {
                    Label("\(engine.streak)-day streak", systemImage: "flame.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // ── 3. Today's stats ─────────────────────────────────────────
            VStack(spacing: 8) {
                HStack {
                    Text("Today")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.secondary)
                        .textCase(.uppercase)
                        .tracking(1.5)
                    Spacer()
                }

                HStack(spacing: 8) {
                    StatPill(label: "Standing",
                             value: formatDuration(engine.todayStandTime), color: .green)
                    StatPill(label: "Sitting",
                             value: formatDuration(engine.todaySitTime),   color: .red)
                    StatPill(label: "Stand %",
                             value: "\(Int(engine.todayStandPercent))%",   color: .indigo)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(nsColor: .separatorColor).opacity(0.4))
                            .frame(height: 6)
                        let ratio = engine.todayStandPercent / Double(engine.settings.goalPercent)
                        RoundedRectangle(cornerRadius: 4)
                            .fill(LinearGradient(colors: [.green, .teal],
                                                 startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(0, min(geo.size.width, geo.size.width * ratio)),
                                   height: 6)
                            .animation(.easeOut(duration: 0.6), value: engine.todayStandPercent)
                    }
                }
                .frame(height: 6)

                HStack {
                    Spacer()
                    Text("Goal: \(engine.settings.goalPercent)% standing")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }
            .padding(16)

            Divider()

            // ── 4. Settings + Quit ───────────────────────────────────────
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { showSettings = true }
            } label: {
                HStack {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                    Text("Settings")
                        .font(.system(size: 13))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                        .font(.system(size: 13))
                    Text("Quit Uptime")
                        .font(.system(size: 13))
                    Spacer()
                }
                .foregroundColor(.secondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
            }
            .buttonStyle(.plain)
        }
        .background(.regularMaterial)
        .overlay {
            if showStages {
                StagesOverviewView(show: $showStages)
                    .environmentObject(engine)
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .overlay {
            if showSettings {
                SettingsView(showSettings: $showSettings)
                    .environmentObject(engine)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
    }
}

// MARK: - Mode Button (Pause / Away / End Day)
private struct ModeButton: View {
    let icon:   String
    let label:  String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .foregroundColor(.secondary)
            .background(Color(nsColor: .controlBackgroundColor))
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(nsColor: .separatorColor).opacity(0.6), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Pill
private struct StatPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.primary)
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 7)
        .background(color.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
