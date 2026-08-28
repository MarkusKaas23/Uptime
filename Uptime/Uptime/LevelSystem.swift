import Foundation

/// Pure leveling math for the Uptime progression system.
///
/// Kept separate from `CycleEngine` so the XP curve and stage thresholds can be
/// tuned (or unit-tested) without touching timer or session logic.
enum LevelSystem {

    /// XP required to advance from `level` to `level + 1`.
    ///
    /// The cost grows linearly so early levels come quickly and later ones
    /// require sustained daily consistency rather than a single great day.
    static func xpForLevel(_ level: Int) -> Int {
        100 + (level - 1) * 20
    }

    /// Returns the current level for a given `totalXP` value.
    static func level(for totalXP: Int) -> Int {
        progress(for: totalXP).level
    }

    /// Decomposes `totalXP` into the current level, XP earned within that level,
    /// and the XP threshold needed to reach the next level.
    static func progress(for totalXP: Int) -> (level: Int, xpIntoLevel: Int, xpForNextLevel: Int) {
        var remaining = totalXP
        var level = 1
        while remaining >= xpForLevel(level) {
            remaining -= xpForLevel(level)
            level += 1
        }
        return (level, remaining, xpForLevel(level))
    }

    /// Minimum level at which each giraffe illustration (stage 0–3) unlocks.
    ///
    /// Stage thresholds are spaced wider than individual level-ups so that
    /// seeing a new character image still feels like a meaningful milestone.
    static let stageThresholds = [1, 6, 12, 20]

    /// Returns the stage index (0–3) for the given `level`.
    static func stage(for level: Int) -> Int {
        (stageThresholds.lastIndex { level >= $0 }) ?? 0
    }

    /// XP earned for one completed day.
    ///
    /// Scales linearly with how close `standPercent` was to the goal (0–100 base XP),
    /// then applies a streak bonus capped at +30% (10 days × 3% per day).
    static func dailyXP(standPercent: Double, goalPercent: Int, streak: Int) -> Int {
        let ratio              = min(1.0, standPercent / Double(max(goalPercent, 1)))
        let base               = Int(ratio * 100)
        let streakBonusPercent = min(streak, 10) * 3   // max +30%
        return base + (base * streakBonusPercent / 100)
    }
}

// MARK: - LevelUpEvent

/// Fired once when a completed day pushes the user across a level or stage boundary.
///
/// Stored on `CycleEngine.levelUpEvent` until the user dismisses the toast.
struct LevelUpEvent: Equatable {
    /// The level the user just reached.
    let newLevel:          Int
    /// XP awarded for the day that triggered this event.
    let xpEarned:          Int
    /// `true` if the new level also unlocks a new giraffe illustration.
    let didUnlockNewStage: Bool
    /// Stage index (0–3) after the level-up.
    let newStage:          Int
}
