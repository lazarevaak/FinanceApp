import Foundation

final class TransactionsService {
    private let cache = TransactionsFileCache()
    private(set) var transactions: [Transaction] = []
    
    init() {
        refresh()
    }
    
    func refresh() {
        do {
            try cache.loadAll()
            transactions = cache.allTransactions
        } catch {
            print("⚠️ Failed to load transactions: \(error)")
            transactions = []
        }
    }
    
    // MARK: - Fetching
    func getTransactions(from start: Date, to end: Date) async -> [Transaction] {
        return transactions.filter { $0.transactionDate >= start && $0.transactionDate <= end }
    }
    
    // MARK: - Creating
    func createTransaction(_ new: Transaction) async {
        cache.add(new)
        try? cache.saveAll()
    }
    
    // MARK: - Updating
    func updateTransaction(_ updated: Transaction) async {
        if let idx = cache.allTransactions.firstIndex(where: { $0.id == updated.id }) {
            cache.remove(id: updated.id)
            cache.add(updated)
            try? cache.saveAll()
        }
    }
    
    // MARK: - Deleting
    func deleteTransaction(id: Int) async {
        cache.remove(id: id)
        try? cache.saveAll()
    }

    // MARK: - Mock data (однократно при старте, если файл пуст)
    private func preloadMockData() {
        let now = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!

        let account = BankAccount(
            id: 1,
            name: "Основной счёт",
            balance: Decimal(string: "1000.00")!,
            currency: "RUB"
        )

        let categories = [
            Category(id: 1, name: "Зарплата", emoji: "💰", isIncome: true),
            Category(id: 2, name: "Аренда квартиры", emoji: "🏠", isIncome: false),
            Category(id: 3, name: "Продукты", emoji: "🍬", isIncome: false),
            Category(id: 4, name: "Одежда", emoji: "👔", isIncome: false),
            Category(id: 5, name: "На собачку", emoji: "🐕", isIncome: false)
        ]

        let mockTransactions: [Transaction] = [
            .init(id: 1, account: account, category: categories[0], amount: 45000, transactionDate: now, comment: "", createdAt: now, updatedAt: now),
            .init(id: 2, account: account, category: categories[1], amount: 30000, transactionDate: now, comment: "", createdAt: now, updatedAt: now),
            .init(id: 3, account: account, category: categories[3], amount: 1000, transactionDate: now, comment: "", createdAt: now, updatedAt: now),
            .init(id: 4, account: account, category: categories[4], amount: 1500, transactionDate: now, comment: "Джэк", createdAt: now, updatedAt: now),
            .init(id: 5, account: account, category: categories[4], amount: 500, transactionDate: now, comment: "Энни", createdAt: now, updatedAt: now),
            .init(id: 6, account: account, category: categories[2], amount: 100, transactionDate: now, comment: "", createdAt: now, updatedAt: now),
            .init(id: 7, account: account, category: categories[2], amount: 1050, transactionDate: twoDaysAgo, comment: "", createdAt: twoDaysAgo, updatedAt: twoDaysAgo)
        ]

        for tx in mockTransactions {
            cache.add(tx)
        }
        try? cache.saveAll()
    }
}
