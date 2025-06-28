import SwiftUI

// MARK: - Transaction Item View
struct TransactionItemView: View {
    let transaction: Transaction

    // MARK: - Body
    var body: some View {
        HStack(spacing: 12) {
            // MARK: - Emoji
            Text(String(transaction.category.emoji))
                .font(.title3)

            // MARK: - Category Name
            Text(transaction.category.name)
                .font(.subheadline)

            Spacer()

            // MARK: - Amount
            Text("\(NSDecimalNumber(decimal: transaction.amount).doubleValue.formatted(.number.precision(.fractionLength(0)))) ₽")
                .font(.subheadline)

            // MARK: - Chevron
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.footnote)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
    }
}
