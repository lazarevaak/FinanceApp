import Foundation

final class AnalysisViewModel {
    private let service: TransactionsService
    private let direction: Direction
    private let accountId: Int

    private(set) var transactions: [Transaction] = []
    private(set) var total: Decimal = 0

    var startDate: Date {
        didSet { load() }
    }
    var endDate: Date {
        didSet { load() }
    }

    var sortTitle: String = "По дате" {
        didSet { sortTransactions() }
    }

    /// Колбэк для уведомления контроллера о том, что данные обновились
    var onUpdate: (() -> Void)?

    /// - Parameters:
    ///   - direction: фильтр по приходу/расходу
    ///   - accountId: идентификатор счёта, из которого берём транзакции
    ///   - client: сетевой клиент (по умолчанию URLSessionNetworkClient с вашим токеном)
    init(
        direction: Direction,
        accountId: Int,
        client: NetworkClient = URLSessionNetworkClient()
    ) {
        self.direction = direction
        self.accountId = accountId
        self.service = TransactionsService(client: client)

        let now = Date()
        self.endDate = Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: now
        )!
        let oneMonthAgo = Calendar.current.date(
            byAdding: .month, value: -1, to: now
        )!
        self.startDate = Calendar.current.startOfDay(for: oneMonthAgo)

        load()
    }

    private func load() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                // Подгрузка всех транзакций за период
                let all = try await service.fetchTransactions(
                    accountId: accountId,
                    from: startDate.startOfDay(),
                    to: endDate.endOfDay()
                )
                // Фильтрация по типу (доход/расход)
                let filtered = all.filter { $0.category.direction == self.direction }
                let newTotal = filtered.reduce(Decimal(0)) { $0 + $1.amount }

                // Обновляем на главном потоке
                await MainActor.run {
                    self.transactions = filtered
                    self.total = newTotal
                    self.sortTransactions()
                }
            } catch {
                // Обработка ошибки (можно добавить onError колбэк или published-свойство)
                print("AnalysisViewModel.load failed:", error)
            }
        }
    }

    private func sortTransactions() {
        if sortTitle == "По сумме" {
            transactions.sort { $0.amount > $1.amount }
        } else {
            transactions.sort { $0.transactionDate > $1.transactionDate }
        }
        onUpdate?()
    }
}

private extension Date {
    func startOfDay() -> Date {
        Calendar.current.startOfDay(for: self)
    }

    func endOfDay() -> Date {
        Calendar.current.date(
            bySettingHour: 23, minute: 59, second: 59, of: self
        )!
    }
}
