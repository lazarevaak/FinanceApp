import Foundation

@MainActor
final class TransactionsListViewModel: ObservableObject {
    // MARK: - Published
    @Published var transactions: [Transaction] = []
    @Published var total: Decimal = 0
    @Published var isLoading = false
    @Published var alertError: String?

    // MARK: - Dependencies
    private let direction: Direction
    private let service: TransactionsService
    private let accountId: Int

    // MARK: - Init
    init(direction: Direction, client: NetworkClient, accountId: Int) {
        self.direction = direction
        self.service = TransactionsService(client: client)
        self.accountId = accountId
        Task { await loadToday() }
    }

    // MARK: - Load
    func loadToday() async {
        isLoading = true
        defer { isLoading = false }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        do {
            let all = try await service.getTransactions(
                forAccount: accountId,
                from: startOfDay,
                to: tomorrow
            )
            let filtered = all.filter { $0.category.direction == direction }
            transactions = filtered
            total = filtered.reduce(0) { $0 + $1.amount }
        } catch {
            alertError = "Не удалось загрузить операции: \(error.localizedDescription)"
        }
    }
}
