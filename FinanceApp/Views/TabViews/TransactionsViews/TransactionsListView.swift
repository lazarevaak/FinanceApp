import SwiftUI

// MARK: — Режим показа формы
enum TransactionFormMode: Identifiable {
    case create(direction: Direction)
    case edit(transaction: Transaction)

    var id: String {
        switch self {
        case .create(let direction):
            return "create-\(direction)"
        case .edit(let tx):
            return "edit-\(tx.id)"
        }
    }
}

// MARK: — Список операций с кнопкой “+”
struct TransactionsListView: View {
    let direction: Direction
    let accountId: Int

    @StateObject private var viewModel: TransactionsListViewModel
    @State private var isShowingHistory = false
    @State private var formMode: TransactionFormMode?

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    private var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    init(direction: Direction, accountId: Int) {
        self.direction = direction
        self.accountId = accountId
        _viewModel = StateObject(
            wrappedValue: TransactionsListViewModel(accountId: accountId)
        )
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGray6)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        totalAmountCard
                        operationsHeader
                        transactionsCard
                            .padding(.bottom, 80)
                    }
                }
                .refreshable {
                    await viewModel.fetchTransactionsForToday()
                }

                addButton
            }
            .navigationTitle(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowingHistory = true
                    } label: {
                        Image(systemName: "clock")
                            .font(.system(size: 20))
                            .foregroundColor(Color("IconColor"))
                    }
                }
            }
            .task {
                await viewModel.fetchTransactionsForToday()
            }
            .sheet(item: $formMode, onDismiss: {
                Task { await viewModel.fetchTransactionsForToday() }
            }) { mode in
                TransactionFormView(mode: mode, accountId: accountId)
            }
        }
    }

    // MARK: — Фильтрация и заголовки
    private var filteredTransactions: [Transaction] {
        viewModel.transactions
            .filter { $0.category.direction == direction }
    }

    private var operationsHeader: some View {
        Text("ОПЕРАЦИИ")
            .font(.system(size: 12))
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .padding(.top, 8)
    }

    private var transactionsCard: some View {
        LazyVStack(spacing: 0) {
            ForEach(filteredTransactions) { tx in
                transactionRow(for: tx)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
    }

    @ViewBuilder
    private func transactionRow(for tx: Transaction) -> some View {
        Button {
            formMode = .edit(transaction: tx)
        } label: {
            TransactionRow(transaction: tx)
                .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)

        Divider()
            .padding(.leading, tx.category.direction == .outcome ? 56 : 16)
    }

    // MARK: — Карточка с общей суммой
    private var totalAmountCard: some View {
        HStack {
            Text("Всего")
            Spacer()
            Text(format(amount: totalAmount))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        .padding(.horizontal)
        .padding(.top, 16)
    }

    // MARK: — Кнопка “+”
    private var addButton: some View {
        Button {
            formMode = .create(direction: direction)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding()
                .background(Color("AccentColor"))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }

    // MARK: — Подсчет и форматирование
    private var totalAmount: Decimal {
        filteredTransactions
            .map(\.amount)
            .reduce(0, +)
    }

    private func format(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber)
            ?? "0 \(currency.symbol)"
    }
}
