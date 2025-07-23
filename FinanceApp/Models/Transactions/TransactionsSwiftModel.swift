import Foundation
import SwiftData

// MARK: - Модель сущности транзакции
@Model
public class TransactionEntity {
    @Attribute(.unique) public var id: Int
    public var accountId: Int
    public var categoryId: Int
    public var amount: Decimal
    public var transactionDate: Date
    public var comment: String?
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: Int,
        accountId: Int,
        categoryId: Int,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.accountId = accountId
        self.categoryId = categoryId
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    convenience init(from tx: Transaction) {
        self.init(
            id: tx.id,
            accountId: tx.account.id,
            categoryId: tx.category.id,
            amount: tx.amount,
            transactionDate: tx.transactionDate,
            comment: tx.comment,
            createdAt: tx.createdAt,
            updatedAt: tx.updatedAt
        )
    }

    func toTransaction(
        account: BankAccount,
        category: Category
    ) -> Transaction {
        Transaction(
            id: id,
            account: account,
            category: category,
            amount: amount,
            transactionDate: transactionDate,
            comment: comment,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }
}

// MARK: - Модель для резервных изменений (бекап)
@Model
public class TransactionChangeEntity {
    @Attribute(.unique) public var id: UUID = UUID()
    public var transactionBody: Data
    public var changeType: ChangeType
    public var timestamp: Date = Date()

    public enum ChangeType: String, Codable {
        case create, update, delete
    }

    init(
        body: TransactionRequestBody,
        changeType: ChangeType
    ) throws {
        self.transactionBody = try JSONEncoder().encode(body)
        self.changeType = changeType
    }
}
