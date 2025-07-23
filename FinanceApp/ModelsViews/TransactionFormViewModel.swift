import SwiftUI
import Foundation

enum TransactionFormModeInternal {
    case create(direction: Direction, accountId: Int)
    case edit(transaction: Transaction)

    var isCreate: Bool {
        if case .create = self { return true }
        else { return false }
    }
    var isEdit: Bool { !isCreate }

    var direction: Direction {
        switch self {
        case .create(let d, _): return d
        case .edit(let tx):     return tx.category.direction
        }
    }

    var accountId: Int {
        switch self {
        case .create(_, let id): return id
        case .edit(let tx):      return tx.account.id
        }
    }
}

@MainActor
final class TransactionFormViewModel: ObservableObject {
    // MARK: - Published state
    @Published var category: Category?
    @Published var amountString: String = ""
    @Published var date: Date = Date()
    @Published var comment: String = ""
    @Published var showCategoryPicker = false
    @Published var categories: [Category] = []
    @Published var errorWrapper: ErrorWrapper?

    // MARK: - Dependencies & mode
    let mode: TransactionFormModeInternal
    private let txService: TransactionsService
    private let accService: BankAccountsService
    private var original: Transaction?

    // MARK: - Init
    init(
        mode: TransactionFormModeInternal,
        txService: TransactionsService? = nil,
        accService: BankAccountsService? = nil
    ) {
        self.mode = mode
        self.txService = txService
            ?? TransactionsService(client: NetworkClient(token: "jkUZptMlYVqSaxWdzuQWKi1B"))
        self.accService = accService
            ?? BankAccountsService(client: NetworkClient(token: "jkUZptMlYVqSaxWdzuQWKi1B"))

        if case .edit(let tx) = mode {
            original = tx
            category = tx.category
            amountString = tx.amount.description
            date = tx.transactionDate
            comment = tx.comment ?? ""
        }

        Task {
            do {
                _ = try await self.accService.getAccount(withId: self.mode.accountId)
                let allTx = try await self.txService.getTransactions(
                    forAccount: self.mode.accountId,
                    from: .distantPast,
                    to: .distantFuture
                )
                let filtered = allTx.filter { $0.category.direction == self.direction }
                let cats = filtered.map(\.category)
                let unique = Dictionary(grouping: cats, by: \.id)
                    .compactMap { _, group in group.first }
                self.categories = unique
            } catch {
                self.errorWrapper = ErrorWrapper(
                    message: "Не удалось загрузить категории: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Helpers

    var direction: Direction {
        mode.direction
    }

    var canSave: Bool {
        category != nil
            && !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Decimal(
                string: amountString
                    .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
            ) != nil
    }

    // MARK: - Actions

    func save() async {
        guard canSave,
              let cat = category,
              let amount = Decimal(
                  string: amountString
                    .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
              )
        else { return }

        do {
            let account = try await accService.getAccount(withId: mode.accountId)
            let tx = Transaction(
                id: original?.id ?? Int(Date().timeIntervalSince1970),
                account: account,
                category: cat,
                amount: amount,
                transactionDate: date,
                comment: comment,
                createdAt: original?.createdAt ?? Date(),
                updatedAt: Date()
            )
            let body = TransactionRequestBody(from: tx)

            if mode.isCreate {
                _ = try await txService.createTransaction(body)
            } else if let id = original?.id {
                _ = try await txService.updateTransaction(id: id, with: body)
            }

            NotificationCenter.default.post(
                name: .operationsDidChange,
                object: nil
            )
        } catch {
            self.errorWrapper = ErrorWrapper(message: error.localizedDescription)
        }
    }

    func delete() async {
        guard case .edit(let tx) = mode else { return }
        do {
            try await txService.deleteTransaction(id: tx.id)
            NotificationCenter.default.post(
                name: .operationsDidChange,
                object: nil
            )
        } catch {
            self.errorWrapper = ErrorWrapper(message: error.localizedDescription)
        }
    }
}
