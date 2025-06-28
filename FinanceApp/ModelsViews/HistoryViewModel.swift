import SwiftUI

// MARK: - History ViewModel
@MainActor
final class HistoryViewModel: ObservableObject {
    // MARK: - Sorting Types
    enum SortingType: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case byDate
        case byAmount
    }

    // MARK: - Public Properties
    let direction: Direction
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var sorting: SortingType = .byDate {
        didSet { Task { await reload() } }
    }
    @Published private(set) var transactions: [Transaction] = []

    // MARK: - Private Properties
    private let service = TransactionsService()

    // MARK: - Initialization
    init(direction: Direction) {
        self.direction = direction
        let now = Date()
        endDate = now
        startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
    }

    // MARK: - Computed Properties
    var total: Decimal {
        transactions.reduce(0) { $0 + $1.amount }
    }

    var totalFormatted: String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencySymbol = "₽"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: total as NSDecimalNumber) ?? "0 ₽"
    }

    // MARK: - Public Methods
    func reload() async {
        // Ensure valid date range
        if endDate < startDate { endDate = startDate }
        if startDate > endDate { startDate = endDate }

        let from = Calendar.current.startOfDay(for: startDate)
        let to = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: endDate)!

        let all = await service.getTransactions(from: from, to: to)
        var filtered = all.filter { $0.category.direction == direction }

        switch sorting {
        case .byDate:
            filtered.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            filtered.sort { $0.amount > $1.amount }
        }

        transactions = filtered
    }
}
