import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {

    let filename: String

    func makeUIView(context: Context) -> LottieAnimationView {
        let animationView = LottieAnimationView(name: filename)
        animationView.loopMode = .playOnce
        animationView.contentMode = .scaleAspectFit
        
        animationView.play()
        return animationView
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) {}
}
