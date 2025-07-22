import SwiftUI

struct MainTabView: View {
    // MARK: - Dependencies
    private let client: NetworkClient
    private let accountService: BankAccountsService
    private let initialAccountId: Int

    // MARK: - State
    @State private var accountId: Int?
    @State private var isLoading: Bool = true
    @State private var alertError: ErrorWrapper?

    // MARK: - Init
    init(client: NetworkClient, accountId: Int) {
        self.client = client
        self.initialAccountId = accountId
        self.accountService = BankAccountsService(client: client)

        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor.white
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - Body
    var body: some View {
        Group {
            if let accountId = accountId {
                TabView {
                    TransactionsListView(direction: .outcome,
                                         client: client,
                                         accountId: accountId)
                        .tabItem {
                            Image("tab_outcome")
                                .renderingMode(.template)
                            Text("Расходы")
                        }

                    TransactionsListView(direction: .income,
                                         client: client,
                                         accountId: accountId)
                        .tabItem {
                            Image("tab_income")
                                .renderingMode(.template)
                            Text("Доходы")
                        }

                    AccountView(client: client)
                        .tabItem {
                            Image("tab_account")
                                .renderingMode(.template)
                            Text("Счет")
                        }

                    CategoriesView()
                        .tabItem {
                            Image("tab_categories")
                                .renderingMode(.template)
                            Text("Статьи")
                        }

                    SettingsView()
                        .tabItem {
                            Image("tab_settings")
                                .renderingMode(.template)
                            Text("Настройки")
                        }
                }
            }
        }
        .loading(isLoading, text: "Загрузка счёта…")
        .errorAlert(errorWrapper: $alertError)
        .task {
            isLoading = true
            do {
                let account = try await accountService.getAccount(withId: initialAccountId)
                accountId = account.id
            } catch {
                alertError = ErrorWrapper(message: error.localizedDescription)
            }
            isLoading = false
        }
    }
}
