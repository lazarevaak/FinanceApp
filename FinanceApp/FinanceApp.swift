import SwiftUI

// MARK: - Entry Point
@main
struct FinanceApp: App {
    @AppStorage("accessToken") private var token: String = "jkUZptMlYVqSaxWdzuQWKi1B"
    @AppStorage("userId") private var userId: Int = 100
    
    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            // Используем конкретную реализацию, а не протокол NetworkClient
           let client = NetworkClient(token: token)
            MainTabView(client: client, accountId: userId)
                .accentColor(Color("AccentColor"))
        }
    }
}
