import Foundation
import Combine

@MainActor
final class TransactionsListViewModel: ObservableObject {
    @Published var transactions: [Transaction] = []

    private let service = TransactionsService()

    func fetchTransactionsForToday() async {
        refresh()
    }

    func refresh() {
        service.refresh()
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        transactions = service.transactions.filter {
            $0.transactionDate >= startOfDay && $0.transactionDate <= endOfDay
        }
    }

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

