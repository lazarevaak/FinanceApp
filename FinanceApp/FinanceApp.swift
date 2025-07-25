import SwiftUI

@main
struct FinanceApp: App {
    @AppStorage("accessToken") private var token: String = "jkUZptMlYVqSaxWdzuQWKi1B"
    @AppStorage("userId")      private var userId: Int    = 100

    var body: some Scene {
        WindowGroup {
            let client = NetworkClient(token: token)
            LaunchView(client: client, accountId: userId)
        }
    }
}
