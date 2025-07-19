import SwiftUI
import Combine

/// Внутренний режим формы: создание или редактирование
enum TransactionFormModeInternal {
    case create(direction: Direction)
    case edit(transaction: Transaction)

    var isCreate: Bool {
        if case .create = self { return true }
        else { return false }
    }
    var isEdit: Bool { !isCreate }
}

@MainActor
final class TransactionFormViewModel: ObservableObject {
    // MARK: - Input
    @Published var category: Category?
    @Published var amountString: String = ""
    @Published var date: Date = Date()
    @Published var comment: String = ""
    @Published var showCategoryPicker = false
    @Published var categories: [Category] = []

    // MARK: - Dependencies
    let mode: TransactionFormModeInternal
    private let txService: TransactionsService
    private let accService: BankAccountsService
    private let accountId: Int
    private var original: Transaction?
    private let isoFormatter = ISO8601DateFormatter()

    // MARK: - Init
    init(
        mode: TransactionFormModeInternal,
        accountId: Int,
        txService: TransactionsService = .init(client: URLSessionNetworkClient()),
        accService: BankAccountsService = .init(client: URLSessionNetworkClient())
    ) {
        self.mode = mode
        self.accountId = accountId
        self.txService = txService
        self.accService = accService

        if case .edit(let tx) = mode {
            original = tx
            category = tx.category
            amountString = tx.amount.description
            date = tx.transactionDate
            comment = tx.comment ?? ""
        }

        Task { await loadCategories() }
    }

    // MARK: - Load categories
    private func loadCategories() async {
        do {
            // Получаем транзакции по заданному аккаунту
            let allTx = try await txService.fetchTransactions(
                accountId: accountId,
                from: .distantPast,
                to: .distantFuture
            )
            // Фильтрация по направлению
            let filtered = allTx.filter { $0.category.direction == direction }
            // Уникальные категории
            let cats = filtered.map { $0.category }
            let unique = Dictionary(grouping: cats, by: \ .id)
                .compactMap { $1.first }
            categories = unique
        } catch {
            print("Error loading categories: \(error)")
        }
    }

    // MARK: - Computed
    var direction: Direction {
        switch mode {
        case .create(let dir): return dir
        case .edit(let tx):    return tx.category.direction
        }
    }

    var canSave: Bool {
        guard category != nil,
              !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              Decimal(string:
                amountString.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
              ) != nil
        else { return false }
        return true
    }

    // MARK: - Save transaction
    func save() async {
        guard canSave,
              let cat = category,
              let amount = Decimal(string:
                amountString.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
              )
        else { return }

        do {
            // Получаем актуальный аккаунт
            let account = try await accService.getAccount(withId: 100)
            if mode.isCreate {
                _ = try await txService.createTransaction(
                    accountId: account.id,
                    categoryId: cat.id,
                    amount: amount,
                    date: date,
                    comment: comment
                )
            } else if let original = original {
                _ = try await txService.updateTransaction(
                    id: original.id,
                    accountId: account.id,
                    categoryId: cat.id,
                    amount: amount,
                    date: date,
                    comment: comment
                )
            }
        } catch {
            print("Error saving transaction: \(error)")
        }
    }

    // MARK: - Delete transaction
    func delete() async {
        guard case .edit(let tx) = mode else { return }
        do {
            try await txService.deleteTransaction(id: tx.id)
        } catch {
            print("Error deleting transaction: \(error)")
        }
    }
}
