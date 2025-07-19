import Foundation

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
    @Published var category: Category?
    @Published var amountString: String = ""
    @Published var date: Date = Date()
    @Published var comment: String = ""
    
    @Published var showCategoryPicker = false
    
    @Published var categories: [Category] = []
    
    let mode: TransactionFormModeInternal
    private let txService = TransactionsService()
    private let accService = BankAccountsService()
    private var original: Transaction?
    
    init(mode: TransactionFormModeInternal) {
        self.mode = mode
        
        if case .edit(let tx) = mode {
            original = tx
            category = tx.category
            amountString = tx.amount.description
            date = tx.transactionDate
            comment = tx.comment ?? ""
        }
        
        Task {
            let all = await txService.getTransactions(from: .distantPast, to: .distantFuture)
            let filtered = all.filter { $0.category.direction == direction }
            let cats = filtered.map(\.category)
            let unique = Dictionary(grouping: cats, by: \.id)
                .compactMap { $1.first }
            await MainActor.run { self.categories = unique }
        }
    }
    
    var direction: Direction {
        switch mode {
        case .create(let dir): return dir
        case .edit(let tx):    return tx.category.direction
        }
    }
    
    var canSave: Bool {
        category != nil
            && !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && Decimal(string:
                amountString
                  .replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
            ) != nil
    }
    
    func save() async {
        guard canSave,
              let cat    = category,
              let amount = Decimal(string:
                amountString.replacingOccurrences(of: Locale.current.decimalSeparator ?? ".", with: ".")
              ),
              let account = try? await accService.getAccount()
        else { return }
        
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
        
        if mode.isCreate {
            await txService.createTransaction(tx)
        } else {
            await txService.updateTransaction(tx)
        }
    }
    
    func delete() async {
        guard case .edit(let tx) = mode else { return }
        await txService.deleteTransaction(id: tx.id)
    }
}

