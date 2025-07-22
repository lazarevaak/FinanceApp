import SwiftUI

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    private var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    var body: some View {
        HStack(spacing: 12) {
            if transaction.category.direction == .outcome {
                Text("\(transaction.category.emoji)")
                    .font(.system(size: 12))
                    .frame(width: 22, height: 22)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Circle())
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.category.name)
                    .font(.body)
                if let comment = transaction.comment, !comment.isEmpty {
                    Text(comment)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
            HStack(spacing: 12) {
                Text(format(amount: transaction.amount))
                    .font(.body)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("BackColor"))
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    private func format(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "0 \(currency.symbol)"
    }
}
