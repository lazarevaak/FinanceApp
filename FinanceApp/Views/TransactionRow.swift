import SwiftUI

// MARK: - Transaction Row
struct TransactionRow: View {
    let transaction: Transaction

    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Emoji (only for outcome)
            if transaction.category.direction == .outcome {
                Text("\(transaction.category.emoji)")
                    .font(.system(size: 12))
                    .frame(width: 22, height: 22)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Circle())
            }

            // MARK: - Name & Comment
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

            // MARK: - Amount & Chevron
            HStack(spacing: 12) {
                Text(formatAmount(transaction.amount))
                    .font(.body)
                Image(systemName: "chevron.forward")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color("SecondaryColor"))
                    .padding(.horizontal, 4)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
    }

    // MARK: - Formatting Amount
    private func formatAmount(_ amount: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencySymbol = "₽"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: amount as NSDecimalNumber) ?? "0 ₽"
    }
}
