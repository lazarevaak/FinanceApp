import Foundation
import Combine

// MARK: — Sorts
enum SortOption: String, CaseIterable, Identifiable {
    case byDate, byAmount
    var id: String { rawValue }
}

// MARK: — Date helpers
private extension Date {
    var startOfDay: Date { Calendar.current.startOfDay(for: self) }
    var endOfDay: Date {
        Calendar.current.date(bySettingHour: 23, minute: 59, second: 59,
                              of: self.startOfDay)!
    }
}

@MainActor
final class AnalysisViewModel: ObservableObject {

    // MARK: — Dependencies
    private let service: TransactionsService
    private let accountId: Int
    private let direction: Direction

    // MARK: — Published output
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var total: Decimal = 0
    @Published var isLoading  = false
    @Published var alertError: String?

    // MARK: — Input
    @Published var startDate: Date {
        didSet { Task { await load() } }
    }
    @Published var endDate: Date {
        didSet { Task { await load() } }
    }
    @Published var sortOption: SortOption = .byDate {
        didSet { applySort() }
    }

    var onUpdate: (() -> Void)?

    // MARK: — Init
    init(
        client: NetworkClient = .init(token: "jkUZptMlYVqSaxWdzuQWKi1B"),
        accountId: Int,
        direction: Direction
    ) {
        self.service   = TransactionsService(client: client)
        self.accountId = accountId
        self.direction = direction

        let now = Date()
        self.startDate = now.startOfDay
        self.endDate   = now.endOfDay

        Task { await load() }
    }

    // MARK: — Loading
    func load() async {
        if startDate > endDate { endDate = startDate }
        if endDate   < startDate { startDate = endDate }

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.getTransactions(
                forAccount: accountId,
                from: startDate.startOfDay,
                to:   endDate.endOfDay
            )

            let filtered = fetched.filter { $0.category.direction == direction }
            transactions = filtered
            total = filtered.reduce(0) { $0 + $1.amount }
            applySort()
        } catch {
            alertError = error.localizedDescription
        }
    }

    // MARK: — Sort
    private func applySort() {
        switch sortOption {
        case .byDate:   transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount: transactions.sort { $0.amount          > $1.amount }
        }
        onUpdate?()
    }
}
