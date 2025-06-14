import Foundation

final class BankAccountsService {
    
    // MARK: - Mock Data
    
    private var mockAccount = BankAccount(
        id: 1,
        userId: 1,
        name: "Основной счёт",
        balance: 10000.00,
        currency: "RUB",
        createdAt: Date(),
        updatedAt: Date()
    )
    
    // MARK: - Public Methods
    
    func getAccount() async -> BankAccount {
        return mockAccount
    }

    func updateAccount(_ updated: BankAccount) async {
        mockAccount = updated
    }
}
