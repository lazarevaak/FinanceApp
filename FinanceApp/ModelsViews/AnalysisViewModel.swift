import Foundation

final class AnalysisViewModel {
    private let service = TransactionsService()
    private let direction: Direction

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

    var onUpdate: (() -> Void)?

    init(direction: Direction) {
        self.direction = direction
        let now = Date()
        self.endDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: now)!
        let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: now)!
        self.startDate = Calendar.current.startOfDay(for: oneMonthAgo)
        load()
    }

    private func load() {
        Task.detached { [weak self] in
            guard let self else { return }

            let all = await service.getTransactions(
                from: startDate.startOfDay(),
                to: endDate.endOfDay()
            )
            let filtered = all.filter { $0.category.direction == self.direction }
            let newTotal = filtered.reduce(Decimal(0)) { $0 + $1.amount }

            await MainActor.run {
                self.transactions = filtered
                self.total = newTotal
                self.sortTransactions()
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
