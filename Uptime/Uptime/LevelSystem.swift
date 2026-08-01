import Foundation

// Pure leveling math, kept separate from CycleEngine so the progression
// curve can be tuned (or unit-tested) without touching timer/session logic.
enum LevelSystem {

    /// XP required to advance from `level` to `level + 1`.
    /// Grows a little each level so early levels come fast and later ones
    /// take sustained consistency rather than one good day.
    static func xpForLevel(_ level: Int) -> Int {
        100 + (level - 1) * 20
    }

    static func level(for totalXP: Int) -> Int {
        progress(for: totalXP).level
    }

    /// Current level, XP earned inside that level, and XP needed for the next one.
    static func progress(for totalXP: Int) -> (level: Int, xpIntoLevel: Int, xpForNextLevel: Int) {
        var remaining = totalXP
        var level = 1
        while remaining >= xpForLevel(level) {
            remaining -= xpForLevel(level)
            level += 1
        }
        return (level, remaining, xpForLevel(level))
    }

    /// The level at which each illustrated form (stage) unlocks.
    /// Wider than level-ups so a new giraffe still feels like a milestone.
    static let stageThresholds = [1, 6, 12, 20]

    static func stage(for level: Int) -> Int {
        (stageThresholds.lastIndex { level >= $0 }) ?? 0
    }

    /// XP earned for one finished day, scaled by how close to the standing
    /// goal it was and boosted by the current streak (capped at +30%).
    static func dailyXP(standPercent: Double, goalPercent: Int, streak: Int) -> Int {
        let ratio = min(1.0, standPercent / Double(max(goalPercent, 1)))
        let base = Int(ratio * 100)
        let streakBonusPercent = min(streak, 10) * 3
        return base + (base * streakBonusPercent / 100)
    }
}

// Fired once when a completed day pushes the user across a level (or stage) boundary.
struct LevelUpEvent: Equatable {
    let newLevel: Int
    let xpEarned: Int
    let didUnlockNewStage: Bool
    let newStage: Int
}
