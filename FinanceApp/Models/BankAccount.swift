import Foundation

struct BankAccount: Codable {
    let id: Int
    let userId: Int?
    let name: String
    let balance: Decimal
    let currency: String
    let createdAt: Date?
    let updatedAt: Date?


    // MARK: - Initializers
    init(id: Int, userId: Int, name: String, balance: Decimal, currency: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.userId = userId
        self.name = name
        self.balance = balance
        self.currency = currency
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(id: Int, name: String, balance: Decimal, currency: String) {
        self.id = id
        self.name = name
        self.balance = balance
        self.currency = currency
        self.userId = nil
        self.createdAt = nil
        self.updatedAt = nil
    }
    
    enum CodingKeys: String, CodingKey {
            case id
            case userId
            case name
            case balance
            case currency
            case createdAt
            case updatedAt
        }

        // MARK: - Custom Decoding (balance как Decimal из строки)
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            id = try container.decode(Int.self, forKey: .id)
            userId = try? container.decode(Int.self, forKey: .userId)
            name = try container.decode(String.self, forKey: .name)

            let balanceString = try container.decode(String.self, forKey: .balance)
            guard let balanceDecimal = Decimal(string: balanceString) else {
                throw DecodingError.dataCorruptedError(
                    forKey: .balance,
                    in: container,
                    debugDescription: "Не удалось сконвертировать \(balanceString) в Decimal"
                )
            }
            balance = balanceDecimal

            currency = try container.decode(String.self, forKey: .currency)
            createdAt = try? container.decode(Date.self, forKey: .createdAt)
            updatedAt = try? container.decode(Date.self, forKey: .updatedAt)
        }

        // MARK: - Custom Encoding
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)

            try container.encode(id, forKey: .id)
            try container.encodeIfPresent(userId, forKey: .userId)
            try container.encode(name, forKey: .name)
            try container.encode("\(balance)", forKey: .balance) 
            try container.encode(currency, forKey: .currency)
            try container.encodeIfPresent(createdAt, forKey: .createdAt)
            try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        }
}
