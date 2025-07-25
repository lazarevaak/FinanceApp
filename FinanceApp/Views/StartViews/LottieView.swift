import SwiftUI
import Lottie

struct LottieView: UIViewRepresentable {
    let animationName: String
    let onCompletion: (() -> Void)?

    func makeUIView(context: Context) -> LottieAnimationView {
        let animation = LottieAnimation.named(animationName)
        let view = LottieAnimationView(animation: animation)
        
        view.contentMode = .scaleAspectFit
        view.loopMode = .playOnce
        
        view.play { finished in
            if finished {
                onCompletion?()
            }
        }
        return view
    }

    func updateUIView(_ uiView: LottieAnimationView, context: Context) { }
}
