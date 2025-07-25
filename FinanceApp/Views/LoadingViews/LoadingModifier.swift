import Foundation
import SwiftUI

// MARK: - Loading Modifier with Minimum Duration
private struct LoadingModifier: ViewModifier {
    let isLoading: Bool
    let text: String
    let minimumDuration: TimeInterval

    @State private var showLoading: Bool = false
    @State private var startDate: Date?

    func body(content: Content) -> some View {
        content
            .onChange(of: isLoading) { newValue in
                if newValue {
                    startDate = Date()
                    showLoading = true
                } else if let start = startDate {
                    let elapsed = Date().timeIntervalSince(start)
                    let delay = max(0, minimumDuration - elapsed)
                    DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                        showLoading = false
                    }
                }
            }
            .overlay(
                Group {
                    if showLoading {
                        LoadingView(text: text)
                    }
                }
            )
    }
}

extension View {
    func loading(_ isLoading: Bool,
                 text: String = "Загрузка…",
                 minimumDuration: TimeInterval = 1.0) -> some View {
        modifier(LoadingModifier(isLoading: isLoading,
                                 text: text,
                                 minimumDuration: minimumDuration))
    }
}

