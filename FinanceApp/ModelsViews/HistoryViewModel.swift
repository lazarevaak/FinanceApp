import Foundation

@MainActor
final class HistoryViewModel: ObservableObject {

    // MARK: - Sorting
    enum SortingType: String, CaseIterable, Identifiable {
        case byDate, byAmount
        var id: String { rawValue }
    }

    // MARK: - Input
    let direction: Direction
    let accountId: Int

    // MARK: - Dependencies
    private let service: TransactionsService

    // MARK: - Filters
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var sorting: SortingType = .byDate {
        didSet { Task { await reload() } }
    }

    // MARK: - Result & State
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var alertError: String?

    // MARK: - Init with *client* injection
    init(
        direction: Direction,
        accountId: Int,
        client: NetworkClient? = nil
    ) {
        self.direction = direction
        self.accountId = accountId

        let resolvedClient = client ?? NetworkClient(token: "jkUZptMlYVqSaxWdzuQWKi1B")
        self.service = TransactionsService(client: resolvedClient)

        let now = Date()
        self.endDate = now
        self.startDate = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        
        Task { await reload() }
    }

    // MARK: - Totals
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

    // MARK: - Reload
    func reload() async {
        if endDate < startDate { endDate = startDate }
        if startDate > endDate { startDate = endDate }

        let from = Calendar.current.startOfDay(for: startDate)
        let to   = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59,
                                         of: Calendar.current.startOfDay(for: endDate))!

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.getTransactions(
                forAccount: accountId,
                from: from,
                to: to
            )

            let filtered = fetched.filter { $0.category.direction == direction }

            transactions = filtered.sorted { lhs, rhs in
                switch sorting {
                case .byDate:   return lhs.transactionDate > rhs.transactionDate
                case .byAmount: return lhs.amount          > rhs.amount
                }
            }
        } catch {
            alertError = error.localizedDescription
        }
    }
}
