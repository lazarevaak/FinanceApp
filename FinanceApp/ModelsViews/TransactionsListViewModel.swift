// TransactionsListViewModel.swift

import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject {
    // MARK: - Published
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var alertError: String?

    // MARK: - Dependencies
    private let service: TransactionsService
    private let accountId: Int

    // MARK: - Init
    init(
        accountId: Int,
        service: TransactionsService = .init(client: URLSessionNetworkClient())
    ) {
        self.accountId = accountId
        self.service = service
        Task { await fetchTransactionsForToday() }
    }

    // MARK: - Fetch
    /// Загружает транзакции за сегодня
    func fetchTransactionsForToday() async {
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        let endOfDay = calendar.date(
            bySettingHour: 23,
            minute: 59,
            second: 59,
            of: now
        )!

        isLoading = true
        defer { isLoading = false }

        do {
            let fetched = try await service.fetchTransactions(
                accountId: accountId,
                from: startOfDay,
                to: endOfDay
            )
            transactions = fetched
        } catch {
            alertError = error.localizedDescription
        }
    }

    // MARK: - Helpers
    /// Общая сумма по направлению
    func totalAmount(for direction: Direction) -> Decimal {
        transactions
            .filter { $0.category.direction == direction }
            .reduce(0) { $0 + $1.amount }
    }

    /// Отформатированная сумма
    func totalFormatted(for direction: Direction) -> String {
        let amount = totalAmount(for: direction)
        let fmt = NumberFormatter()
        fmt.numberStyle = .currency
        fmt.currencySymbol = "₽"
        fmt.maximumFractionDigits = 0
        return fmt.string(from: amount as NSDecimalNumber) ?? "0 ₽"
    }
}

// Чтобы можно было использовать .alert(item:) с String
extension String: Identifiable {
    public var id: String { self }
}
