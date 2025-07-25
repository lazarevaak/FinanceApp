import SwiftUI

struct LaunchView: View {
    @State private var isFinished = false
    let client: NetworkClient
    let accountId: Int

    var body: some View {
        Group {
            if isFinished {
                MainTabView(client: client, accountId: accountId)
                    .accentColor(Color("AccentColor"))
            } else {
                LottieView(animationName: "upload") {
                    withAnimation(.easeOut(duration: 0.3)) {
                        isFinished = true
                    }
                }
                .edgesIgnoringSafeArea(.all)
                .background(Color.white)
            }
        }
    }
}
