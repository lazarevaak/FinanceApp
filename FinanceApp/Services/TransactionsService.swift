import Foundation

final class TransactionsService {
    
    // MARK: - Mock Data
    private var transactions: [Transaction] = {
        let now = ISO8601DateFormatter().date(from: "2025-06-11T16:12:34.235Z")!
        let account = BankAccount(
            id: 1,
            name: "Основной счёт",
            balance: Decimal(string: "1000.00")!,
            currency: "RUB"
        )
        let salaryCategory = Category(id: 1, name: "Зарплата", emoji: "💰", isIncome: true)
        
        return [
            Transaction(
                id: 1,
                account: account,
                category: salaryCategory,
                amount: Decimal(string: "500.00")!,
                transactionDate: now.addingTimeInterval(-3600),
                comment: "Зарплата за месяц",
                createdAt: now.addingTimeInterval(-3600),
                updatedAt: now.addingTimeInterval(-3600)
            )
        ]
    }()
    
    // MARK: - Fetching
    // Пока без обработки ошибок тк работаем с фейк данными.
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
