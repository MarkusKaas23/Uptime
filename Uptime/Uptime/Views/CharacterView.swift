import SwiftUI

// CharacterView displays one of four giraffe posture stage images.
// stage 0 = Cave Dweller
// stage 1 = Office Slouch
// stage 2 = Upriser
// stage 3 = Posture Champion
struct CharacterView: View {
    let stage: Int

    var body: some View {
        Image("GiraffeStage\(stage + 1)")
            .resizable()
            .aspectRatio(contentMode: .fit)
    }
}
