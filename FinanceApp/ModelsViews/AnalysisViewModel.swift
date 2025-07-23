import Foundation
import Combine
import PieChart

// MARK: — Сортировка
enum SortOption: String, CaseIterable, Identifiable {
    case byDate, byAmount
    var id: String { rawValue }
}

@MainActor
final class AnalysisViewModel: ObservableObject {

    // MARK: — Dependencies
    private let service: TransactionsService
    private let accountId: Int
    private let direction: Direction

    // MARK: — Published
    @Published private(set) var transactions: [Transaction] = []
    @Published private(set) var total: Decimal = 0
    @Published var isLoading: Bool = false
    @Published var alertError: String?
    @Published var startDate: Date { didSet { Task { await load() } } }
    @Published var endDate: Date   { didSet { Task { await load() } } }
    @Published var sortOption: SortOption = .byDate { didSet { applySort() } }

    /// Коллбек для обновления экрана
    var onUpdate: (() -> Void)?

    // MARK: — Init
    init(
        client: NetworkClient,
        accountId: Int,
        direction: Direction
    ) {
        self.service   = TransactionsService(client: client)
        self.accountId = accountId
        self.direction = direction

        let now = Date()
        self.startDate = Calendar.current.startOfDay(for: now)
        self.endDate   = Calendar.current.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        )!

        Task { await load() }
    }

    // MARK: — Load
    func load() async {
        if startDate > endDate { endDate = startDate }
        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.getTransactions(
                forAccount: accountId,
                from: startDate,
                to:   endDate
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
        case .byDate:
            transactions.sort { $0.transactionDate > $1.transactionDate }
        case .byAmount:
            transactions.sort { $0.amount > $1.amount }
        }
        onUpdate?()
    }

    // MARK: — Для PieChart
    public var chartEntities: [Entity] {
        let sums = transactions.reduce(into: [String: Decimal]()) { acc, tx in
            acc[tx.category.name, default: 0] += tx.amount
        }
        
        let sorted = sums
            .map { Entity(value: $0.value, label: $0.key) }
            .sorted { $0.value > $1.value }

        if sorted.count > 5 {
            let top5 = sorted.prefix(5)
            let othersValue = sorted.dropFirst(5).reduce(0) { $0 + $1.value }
            return Array(top5) + [Entity(value: othersValue, label: "Остальные")]
        }
        return sorted
    }
}
