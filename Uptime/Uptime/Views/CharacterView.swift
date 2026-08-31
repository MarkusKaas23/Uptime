import SwiftUI

/// Renders one of the four giraffe posture illustrations based on the user's current stage.
///
/// The asset names map as follows (1-indexed to match the image file names in Assets.xcassets):
/// - Stage 0 → `GiraffeStage1`  (The Cave Dweller)
/// - Stage 1 → `GiraffeStage2`  (The Office Slouch)
/// - Stage 2 → `GiraffeStage3`  (The Upriser)
/// - Stage 3 → `GiraffeStage4`  (The Posture Champion)
struct CharacterView: View {
    /// Stage index in the range `0…3`, sourced from `CycleEngine.characterStage`.
    let stage: Int

    var body: some View {
        Image("GiraffeStage\(stage + 1)")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
