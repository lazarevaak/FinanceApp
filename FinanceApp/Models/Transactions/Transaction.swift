import Foundation

// MARK: - ISO-8601 «любого вида»
enum ISO8601Any {
    static func date(from string: String) -> Date? {
        if let d = withMs.date(from: string) { return d }
        return noMs.date(from: string)
    }
    
    private static let withMs: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    
    private static let noMs: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}

// MARK: - Model
struct Transaction: Codable, Identifiable {
    let id: Int
    let account: BankAccount
    let category: Category
    let amount: Decimal
    let transactionDate: Date
    let comment: String?
    let createdAt: Date
    let updatedAt: Date

    private enum CodingKeys: String, CodingKey {
        case id, account, category, amount, transactionDate, comment, createdAt, updatedAt
    }

    // MARK: Decoding
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)

        id       = try c.decode(Int.self,          forKey: .id)
        account  = try c.decode(BankAccount.self, forKey: .account)
        category = try c.decode(Category.self,    forKey: .category)

        let amountStr = try c.decode(String.self, forKey: .amount)
        guard let dec = Decimal(string: amountStr) else {
            throw DecodingError.dataCorruptedError(forKey: .amount, in: c,
                                                   debugDescription: "Bad decimal: \(amountStr)")
        }
        amount = dec

        func parse(_ key: CodingKeys) throws -> Date {
            let s = try c.decode(String.self, forKey: key)
            guard let d = ISO8601Any.date(from: s) else {
                throw DecodingError.dataCorruptedError(forKey: key, in: c,
                                 debugDescription: "Bad ISO-8601: \(s)")
            }
            return d
        }

        transactionDate = try parse(.transactionDate)
        createdAt       = try parse(.createdAt)
        updatedAt       = try parse(.updatedAt)

        comment = try c.decodeIfPresent(String.self, forKey: .comment)
    }

    // MARK: Encoding
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,       forKey: .id)
        try c.encode(account,  forKey: .account)
        try c.encode(category, forKey: .category)
        try c.encode("\(amount)", forKey: .amount)

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        try c.encode(iso.string(from: transactionDate), forKey: .transactionDate)
        try c.encode(iso.string(from: createdAt),       forKey: .createdAt)
        try c.encode(iso.string(from: updatedAt),       forKey: .updatedAt)
        try c.encodeIfPresent(comment,                  forKey: .comment)
    }
}

extension Transaction {
    init(
        id: Int,
        account: BankAccount,
        category: Category,
        amount: Decimal,
        transactionDate: Date,
        comment: String?,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.account = account
        self.category = category
        self.amount = amount
        self.transactionDate = transactionDate
        self.comment = comment
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
