import Foundation

struct BankAccount: Codable {
    let id: Int
    let userId: Int?
    let name: String
    let balance: Decimal
    let currency: String
    let createdAt: Date?
    let updatedAt: Date?

    // MARK: - Full Init

    init(id: Int, userId: Int, name: String, balance: Decimal, currency: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    // MARK: - Short Init (Without Metadata)

    init(id: Int, name: String, balance: Decimal, currency: String) {
        self.id = id
        self.userId = nil
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = nil
        self.updatedAt = nil
    }
}
