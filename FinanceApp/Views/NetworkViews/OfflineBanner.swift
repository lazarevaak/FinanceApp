import SwiftUI

struct OfflineBanner: View {
    var body: some View {
        Text("Offline mode")
            .font(.subheadline).bold()
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(Color.red)
            .foregroundColor(.white)
    }
}
