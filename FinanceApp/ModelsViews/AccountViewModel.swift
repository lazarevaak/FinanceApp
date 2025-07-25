import SwiftUI

@MainActor
final class AccountViewModel: ObservableObject {
    enum ChartMode: String, CaseIterable, Identifiable {
        case daily   = "Дни"
        case monthly = "Месяцы"
        var id: String { rawValue }
    }

    // MARK: — Published
    @Published var account: BankAccount?
    @Published var isEditing = false
    @Published var balanceInput = ""
    @Published var selectedCurrency: Currency = .ruble
    @Published var error: Error?

    @Published var balanceEntries: [BalanceEntry] = []
    @Published var selectedChartMode: ChartMode = .daily

    // MARK: — Dependencies
    private let accountService: BankAccountsService
    private let txService: TransactionsService

    // MARK: — Init
    init(client: NetworkClient) {
        self.accountService = BankAccountsService(client: client)
        self.txService      = TransactionsService(client: client)
        Task { await loadAccount() }
    }

    func loadAccount() async {
        do {
            let acc = try await accountService.getAccount()
            self.account = acc
            self.balanceInput = Self.format(acc.balance)
            if let raw = UserDefaults.standard.string(forKey: "selectedCurrency"),
               let cur = Currency(rawValue: raw)
            {
                self.selectedCurrency = cur
            }

            let cal = Calendar.current
            let now = Date()
            let start: Date = {
                switch selectedChartMode {
                case .daily:   return cal.date(byAdding: .day,   value: -29, to: now)!
                case .monthly: return cal.date(byAdding: .month, value: -23, to: now)!
                }
            }()

            let txs = try await txService.getTransactions(
                forAccount: acc.id,
                from: start,
                to: now
            )

            updateChartEntries(from: txs)
        }
        catch {
            self.error = error
        }
    }

    func toggleEditing() {
        if isEditing {
            Task { await saveChanges() }
        } else if let acc = account {
            balanceInput = Self.format(acc.balance)
        }
        withAnimation { isEditing.toggle() }
    }

    private func saveChanges() async {
        guard let acc = account,
              let newBal = Decimal(string: sanitize(balanceInput))
        else { return }

        do {
            let updated = try await accountService.updateAccount(
                id: acc.id,
                name: acc.name,
                balance: newBal,
                currency: selectedCurrency.rawValue
            )
            self.account = updated
            self.balanceInput = Self.format(updated.balance)
            UserDefaults.standard.set(selectedCurrency.rawValue,
                                       forKey: "selectedCurrency")
        }
        catch {
            self.error = error
        }
    }

    // MARK: — Построение данных для графика

    private func updateChartEntries(from transactions: [Transaction]) {
        let cal = Calendar.current
        let now = Date()
        var buckets: [Date: Decimal] = [:]

        switch selectedChartMode {
        case .daily:
            for offset in (0..<30).reversed() {
                let day = cal.startOfDay(for:
                    cal.date(byAdding: .day, value: -offset, to: now)!
                )
                buckets[day] = 0
            }
            for tx in transactions {
                let day = cal.startOfDay(for: tx.transactionDate)
                if buckets.keys.contains(day) {
                    buckets[day]! += tx.amount
                }
            }

        case .monthly:
            for offset in (0..<24).reversed() {
                let raw = cal.date(byAdding: .month, value: -offset, to: now)!
                let comp = cal.dateComponents([.year, .month], from: raw)
                let mStart = cal.date(from: comp)!
                buckets[mStart] = 0
            }
            for tx in transactions {
                let comp = cal.dateComponents([.year, .month],
                                              from: tx.transactionDate)
                if let mStart = cal.date(from: comp),
                   buckets.keys.contains(mStart)
                {
                    buckets[mStart]! += tx.amount
                }
            }
        }

        balanceEntries = buckets
            .sorted(by: { $0.key < $1.key })
            .map { BalanceEntry(date: $0.key, balance: $0.value) }
    }

    // MARK: — Вспомогательные

    func sanitize(_ text: String) -> String {
        var s = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }
        if let dot = s.firstIndex(of: ".") {
            let rest = s[s.index(after: dot)...]
                .replacingOccurrences(of: ".", with: "")
            s = String(s[..<s.index(after: dot)]) + rest
        }
        return s
    }

    private static func format(_ value: Decimal) -> String {
        let fmt = NumberFormatter()
        fmt.numberStyle = .decimal
        fmt.maximumFractionDigits = 0
        return fmt.string(for: value) ?? "0"
    }
}
