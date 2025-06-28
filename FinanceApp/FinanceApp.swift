import SwiftUI

// MARK: - Entry Point
@main
struct FinanceApp: App {
    // MARK: - Scene
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .accentColor(Color("AccentColor")) 
        }
    }
}
