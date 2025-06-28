import Foundation

// MARK: - TransactionsListViewModel
@MainActor
final class TransactionsListViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var transactions: [Transaction] = []

    // MARK: - Private Properties
    private let service = TransactionsService()

    // MARK: - Data Fetching
    func fetchTransactionsForToday() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(
            bySettingHour: 23, minute: 59, second: 59,
            of: now
        )!

        let all = await service.getTransactions(from: startOfDay, to: endOfDay)
        self.transactions = all
    }

    // MARK: - Calculations
    func totalAmount(for direction: Direction) -> Decimal {
        transactions
            .filter { $0.category.direction == direction }
            .reduce(0) { $0 + $1.amount }
    }

    func totalFormatted(for direction: Direction) -> String {
        let amount = totalAmount(for: direction)
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencySymbol = "₽"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: amount as NSDecimalNumber) ?? "0 ₽"
    }
}
