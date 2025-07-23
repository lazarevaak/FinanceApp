import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    let text: String

    init(text: String = "Загрузка…") {
        self.text = text
    }

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .opacity(0.4)
                .ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text(text)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(24)
            .background(Color(.secondarySystemBackground))
            .cornerRadius(12)
            .shadow(radius: 10)
        }
    }
}

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
