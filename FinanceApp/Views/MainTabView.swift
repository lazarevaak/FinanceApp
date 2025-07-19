import SwiftUI

struct MainTabView: View {
    // MARK: - Dependencies
    private let client: NetworkClient
    private let accountService: BankAccountsService
    private let initialAccountId: Int

    // MARK: - State
    @State private var accountId: Int = 0

    // MARK: - Init
    // MARK: - Init
    init(client: NetworkClient, accountId: Int) {
        self.client = client
        self.accountId = accountId

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }


    var body: some View {
        TabView {
            TransactionsListView(direction: .outcome, accountId: accountId)
                .tabItem { Label("Расходы", systemImage: "minus.circle") }

            TransactionsListView(direction: .income, accountId: accountId)
                .tabItem { Label("Доходы", systemImage: "plus.circle") }

            AccountView(client: client, accountId: accountId)
                .tabItem { Label("Счет", systemImage: "creditcard") }

            CategoriesView()
                .tabItem { Label("Статьи", systemImage: "list.bullet") }

            SettingsView()
                .tabItem { Label("Настройки", systemImage: "gear") }
        }
        .onAppear {
            self.accountId = initialAccountId
        }
        .task {
            do {
                let account = try await accountService.getAccount(withId: initialAccountId)
                accountId = account.id
            } catch {
                print("Ошибка загрузки: \(error.localizedDescription)")
            }
        }
    }
}
