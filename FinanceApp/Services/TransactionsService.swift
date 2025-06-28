import Foundation

final class TransactionsService {
    
    // MARK: - Mock Data
    private var transactions: [Transaction] = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds
        ]
        
        let now = Date()
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        let account = BankAccount(
            id: 1,
            name: "Основной счёт",
            balance: Decimal(string: "1000.00")!,
            currency: "RUB"
        )
        let salaryCategory = Category(id: 1, name: "Зарплата", emoji: "💰", isIncome: true)
        let flatCategory = Category(id: 2, name: "Аренда квартиры", emoji: "🏠", isIncome: false)
        let clothesCategory = Category(id: 4, name: "Одежда", emoji: "👔", isIncome: false)
        let groceriesCategory = Category(id: 3, name: "Продукты", emoji: "🍬", isIncome: false)
        let dogCategory = Category(id: 5, name: "На собачку", emoji: "🐕", isIncome: false)

        return [
            Transaction(
                id: 1,
                account: account,
                category: salaryCategory,
                amount: Decimal(string: "45000.00")!,
                transactionDate: now,
                comment: "",
                createdAt: now,
                updatedAt: now
            ),
            Transaction(
                id: 2,
                account: account,
                category: flatCategory,
                amount: Decimal(string: "30000.00")!,
                transactionDate: now,
                comment: "",
                createdAt: now,
                updatedAt: now
            ),
            Transaction(
                id: 3,
                account: account,
                category: clothesCategory,
                amount: Decimal(string: "1000.00")!,
                transactionDate: now,
                comment: "",
                createdAt: now,
                updatedAt: now
            ),
            Transaction(
                id: 4,
                account: account,
                category: dogCategory,
                amount: Decimal(string: "1500.00")!,
                transactionDate: now,
                comment: "Джэк",
                createdAt: now,
                updatedAt: now
            ),
            Transaction(
                id: 5,
                account: account,
                category: dogCategory,
                amount: Decimal(string: "500.00")!,
                transactionDate: now,
                comment: "Энни",
                createdAt: now,
                updatedAt: now
            ),
            Transaction(
                id: 6,
                account: account,
                category: groceriesCategory,
                amount: Decimal(string: "100.00")!,
                transactionDate: now,
                comment: "",
                createdAt: now,
                updatedAt: now
            ),
            Transaction(
                id: 7,
                account: account,
                category: groceriesCategory,
                amount: Decimal(string: "1050.00")!,
                transactionDate: twoDaysAgo,
                comment: "",
                createdAt: twoDaysAgo,
                updatedAt: twoDaysAgo
            )
        ]
    }()
    
    // MARK: - Fetching
    func getTransactions(from start: Date, to end: Date) async -> [Transaction] {
        return transactions.filter { $0.transactionDate >= start && $0.transactionDate <= end }
    }
    
    // MARK: - Creating
    func createTransaction(_ new: Transaction) async {
        transactions.append(new)
    }
    
    // MARK: - Updating
    func updateTransaction(_ updated: Transaction) async {
        guard let idx = transactions.firstIndex(where: { $0.id == updated.id }) else { return }
        transactions[idx] = updated
    }
    
    // MARK: - Deleting
    func deleteTransaction(id: Int) async {
        transactions.removeAll { $0.id == id }
    }
}
