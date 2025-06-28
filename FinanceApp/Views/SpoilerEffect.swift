import SwiftUI
import UIKit

final class EmitterView: UIView {
    override class var layerClass: AnyClass { CAEmitterLayer.self }
    override var layer: CAEmitterLayer { super.layer as! CAEmitterLayer }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.emitterPosition = CGPoint(x: bounds.midX, y: bounds.midY)
        layer.emitterSize = bounds.size
    }
}

struct SpoilerView: UIViewRepresentable {
    let isOn: Bool

    func makeUIView(context: Context) -> EmitterView {
        let view = EmitterView()
        let cell = CAEmitterCell()
        cell.contents = UIImage(named: "textSpeckle_Normal")?.cgImage
        cell.color = UIColor.black.cgColor
        cell.contentsScale = 1.8
        cell.emissionRange = .pi * 2
        cell.lifetime = 1
        cell.scale = 0.5
        cell.velocityRange = 20
        cell.alphaRange = 1
        cell.birthRate = 600
        view.layer.emitterShape = .rectangle
        view.layer.emitterCells = [cell]
        return view
    }

    func updateUIView(_ uiView: EmitterView, context: Context) {
        if isOn { uiView.layer.beginTime = CACurrentMediaTime() }
        uiView.layer.birthRate = isOn ? 1 : 0
    }
}

struct SpoilerModifier: ViewModifier {
    let isOn: Bool
    func body(content: Content) -> some View {
        content
            .opacity(isOn ? 0 : 1)
            .overlay { SpoilerView(isOn: isOn) }
            .animation(.default, value: isOn)
    }
}

extension View {
    func spoiler(isOn: Binding<Bool>) -> some View {
        self
            .modifier(SpoilerModifier(isOn: isOn.wrappedValue))
            .onTapGesture { isOn.wrappedValue.toggle() }
    }
}
