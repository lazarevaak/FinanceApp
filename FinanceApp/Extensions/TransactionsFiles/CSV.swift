import Foundation

extension Transaction {
    static func fromCSV(_ line: String) -> Transaction? {
        let parts = line
            .split(separator: ",", omittingEmptySubsequences: false)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count == 14 else { return nil }

        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        guard
            let id              = Int(parts[0]),
            let accountId       = Int(parts[1]),
            let accountBalance  = Decimal(string: parts[3]),
            let categoryId      = Int(parts[5]),
            let emojiChar       = parts[7].first,
            let isIncome        = Bool(parts[8]),
            let amount          = Decimal(string: parts[9]),
            let txDate          = iso.date(from: parts[10]),
            let createdAt       = iso.date(from: parts[12]),
            let updatedAt       = iso.date(from: parts[13])
        else { return nil }

        let account = BankAccount(
            id:       accountId,
            name:     parts[2],
            balance:  accountBalance,
            currency: parts[4]
        )
        let category = Category(
            id:       categoryId,
            name:     parts[6],
            emoji:    emojiChar,
            isIncome: isIncome
        )
        let commentValue = parts[11].isEmpty ? nil : parts[11]

        return Transaction(
            id:              id,
            account:         account,
            category:        category,
            amount:          amount,
            transactionDate: txDate,
            comment:         commentValue,
            createdAt:       createdAt,
            updatedAt:       updatedAt
        )
    }

    var toCSV: String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return [
            String(id),
            String(account.id),
            account.name,
            account.balance.description,
            account.currency,
            String(category.id),
            category.name,
            String(category.emoji),
            String(category.isIncome),
            amount.description,
            iso.string(from: transactionDate),
            comment ?? "",
            iso.string(from: createdAt),
            iso.string(from: updatedAt)
        ].joined(separator: ",")
    }
}
