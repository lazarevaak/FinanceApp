import SwiftUI

struct MainTabView: View {
    // MARK: - Initialization
    init() {
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = .white
        
        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
    
    // MARK: - Body
    var body: some View {
        TabView {
            // MARK: - Outcome Tab
            TransactionsListView(direction: .outcome)
                .tabItem {
                    Label {
                        Text("Расходы")
                    } icon: {
                        Image("tab_outcome")
                            .renderingMode(.template)
                    }
                }

            // MARK: - Income Tab
            TransactionsListView(direction: .income)
                .tabItem {
                    Label {
                        Text("Доходы")
                    } icon: {
                        Image("tab_income")
                            .renderingMode(.template)
                    }
                }

            // MARK: - Account Tab
            AccountView()
                .tabItem {
                    Label {
                        Text("Счет")
                    } icon: {
                        Image("tab_account")
                            .renderingMode(.template)
                    }
                }

            // MARK: - Categories Tab
            CategoriesView()
                .tabItem {
                    Label {
                        Text("Статьи")
                    } icon: {
                        Image("tab_categories")
                            .renderingMode(.template)
                    }
                }

            // MARK: - Settings Tab
            SettingsView()
                .tabItem {
                    Label {
                        Text("Настройки")
                    } icon: {
                        Image("tab_settings")
                            .renderingMode(.template)
                    }
                }
        }
    }
}
