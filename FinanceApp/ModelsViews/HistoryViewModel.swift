import SwiftUI

@MainActor
final class HistoryViewModel: ObservableObject {
    enum SortingType: String, CaseIterable, Identifiable {
        var id: String { rawValue }
        case byDate
        case byAmount
    }

    // MARK: — Входные параметры
    let direction: Direction
    let accountId: Int

    // MARK: — Параметры фильтрации
    @Published var startDate: Date
    @Published var endDate: Date
    @Published var sorting: SortingType = .byDate {
        didSet { Task { await reload() } }
    }

    // MARK: — Результат и состояние
    @Published private(set) var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var alertError: String?

    // MARK: — Сервис
    private let service: TransactionsService

    init(
        direction: Direction,
        accountId: Int,
        service: TransactionsService = .init(client: URLSessionNetworkClient())
    ) {
        self.direction = direction
        self.accountId = accountId
        self.service = service

        let now = Date()
        self.endDate = now
        self.startDate = Calendar.current
            .date(byAdding: .month, value: -1, to: now)!
        Task { await reload() }
    }

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

    func reload() async {
        // Защита диапазона
        if endDate < startDate { endDate = startDate }
        if startDate > endDate { startDate = endDate }

        let from = Calendar.current.startOfDay(for: startDate)
        let to = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: endDate
        )!

        isLoading = true
        defer { isLoading = false }

        do {
            let all = try await service.fetchTransactions(
                accountId: accountId,
                from: from,
                to: to
            )
            var filtered = all.filter { $0.category.direction == direction }
            switch sorting {
            case .byDate:
                filtered.sort { $0.transactionDate > $1.transactionDate }
            case .byAmount:
                filtered.sort { $0.amount > $1.amount }
            }
            transactions = filtered
        } catch {
            alertError = error.localizedDescription
        }
    }
}
