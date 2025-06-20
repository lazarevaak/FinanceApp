import Foundation

extension Transaction {
    
    // MARK: - CSV Parsing
    
    static func fromCSV(_ csvLine: String) -> Transaction? {
        let parts = csvLine
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }

        guard parts.count == 14 else { return nil }

        let formatter = ISO8601DateFormatter()

        guard
            let id = Int(parts[0]),
            let accountId = Int(parts[1]),
            let balance = Decimal(string: parts[3]),
            let categoryId = Int(parts[5]),
            let emoji = parts[7].first,
            let isIncome = Bool(parts[8]),
            let amount = Decimal(string: parts[9]),
            let transactionDate = formatter.date(from: parts[10]),
            let createdAt = formatter.date(from: parts[12]),
            let updatedAt = formatter.date(from: parts[13])
        else {
            return nil
        }

        let account = BankAccount(
            id: accountId,
            name: parts[2],
            balance: balance,
            currency: parts[4]
        )

        let category = Category(
            id: categoryId,
            name: parts[6],
            emoji: emoji,
            isIncome: isIncome
        )

        let comment = parts[11].isEmpty ? nil : parts[11]

        return Transaction(
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

    // MARK: - CSV Generation

    var toCSV: String {
        let formatter = ISO8601DateFormatter()
        return [
            "\(id)",
            "\(account.id)",
            account.name,
            "\(account.balance)",
            account.currency,
            "\(category.id)",
            category.name,
            String(category.emoji),
            "\(category.isIncome)",
            "\(amount)",
            formatter.string(from: transactionDate),
            comment ?? "",
            formatter.string(from: createdAt),
            formatter.string(from: updatedAt)
        ].joined(separator: ",")
    }
}
