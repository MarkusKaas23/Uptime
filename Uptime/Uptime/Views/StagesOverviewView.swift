import SwiftUI

struct StagesOverviewView: View {
    @EnvironmentObject var engine: CycleEngine
    @Binding var show: Bool

    private let stages: [(name: String, subtitle: String, threshold: String, color: Color)] = [
        ("The Cave Dweller",     "🦴",  "0–24% of goal days",   .red),
        ("The Office Slouch",    "😑",  "25–49% of goal days",  .orange),
        ("The Upriser",          "🙂",  "50–74% of goal days",  .blue),
        ("The Posture Champion", "🏆",  "75–100% of goal days", .purple),
    ]

    var body: some View {
        VStack(spacing: 0) {

            // ── Header ──────────────────────────────────────────────────────
            HStack {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { show = false }
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
                Text("Your Journey")
                    .font(.system(size: 13, weight: .semibold))
                Spacer()
                Color.clear.frame(width: 48, height: 1)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // ── Stage cards — 2 × 2 grid ────────────────────────────────────
            ScrollView {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())],
                          spacing: 10) {
                    ForEach(0..<4, id: \.self) { i in
                        StageCard(
                            stage: i,
                            name: stages[i].name,
                            emoji: stages[i].subtitle,
                            threshold: stages[i].threshold,
                            color: stages[i].color,
                            isCurrent: engine.characterStage == i,
                            isUnlocked: engine.characterStage >= i
                        )
                    }
                }
                .padding(12)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}

// MARK: – Individual stage card
private struct StageCard: View {
    let stage:      Int
    let name:       String
    let emoji:      String
    let threshold:  String
    let color:      Color
    let isCurrent:  Bool
    let isUnlocked: Bool

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(isCurrent ? 0.18 : 0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isCurrent ? color : Color.clear, lineWidth: 2)
                    )

                VStack(spacing: 4) {
                    CharacterView(stage: stage)
                        .frame(width: 72, height: 88)
                        .opacity(isUnlocked ? 1.0 : 0.30)
                        .overlay(
                            Group {
                                if !isUnlocked {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.secondary)
                                }
                            }
                        )
                }
                .padding(.vertical, 8)

                if isCurrent {
                    VStack {
                        HStack {
                            Spacer()
                            Text("NOW")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(color)
                                .clipShape(RoundedRectangle(cornerRadius: 4))
                                .padding(5)
                        }
                        Spacer()
                    }
                }
            }

            VStack(spacing: 2) {
                Text("\(emoji) Stage \(stage + 1)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(isUnlocked ? color : .secondary)
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                Text(threshold)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 4)
        }
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color(nsColor: .separatorColor).opacity(0.5), lineWidth: 0.5)
        )
    }
}
