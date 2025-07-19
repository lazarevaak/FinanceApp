import SwiftUI

struct AnalysisViewControllerWrapper: UIViewControllerRepresentable {
    let direction: Direction
    let accountId: Int

    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIViewController {
        let vc = AnalysisViewController(direction: direction, accountId: accountId)
        vc.onBack = { self.presentationMode.wrappedValue.dismiss() }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
