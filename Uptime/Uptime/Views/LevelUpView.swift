import SwiftUI

// Shown once whenever a finished day pushes the user across a level
// (or stage) boundary. Dismissed by the user, then cleared via
// engine.dismissLevelUpEvent() so it never reappears for the same event.
struct LevelUpView: View {
    @EnvironmentObject var engine: CycleEngine
    let event: LevelUpEvent

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: event.didUnlockNewStage ? "sparkles" : "arrow.up.circle.fill")
                .font(.system(size: 34))
                .foregroundColor(.yellow)

            Text(event.didUnlockNewStage ? "New Stage Unlocked!" : "Level Up!")
                .font(.system(size: 18, weight: .bold))

            if event.didUnlockNewStage {
                CharacterView(stage: event.newStage)
                    .frame(width: 90, height: 90)
            }

            Text("Level \(event.newLevel) · +\(event.xpEarned) XP")
                .font(.system(size: 13))
                .foregroundColor(.secondary)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) { engine.dismissLevelUpEvent() }
            } label: {
                Text("Nice!")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.indigo)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.regularMaterial)
    }
}
