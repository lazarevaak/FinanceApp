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
