import SwiftUI

enum TransactionFormMode: Identifiable {
    case create(direction: Direction, accountId: Int)
    case edit(transaction: Transaction)

    var id: String {
        switch self {
        case .create(let d, let id): return "create-\(d)-\(id)"
        case .edit(let tx): return "edit-\(tx.id)"
        }
    }
}

struct TransactionsListView: View {
    let direction: Direction
    let client: NetworkClient
    let accountId: Int

    @StateObject private var vm: TransactionsListViewModel
    @State private var formMode: TransactionFormMode?

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    private var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    private var filteredTransactions: [Transaction] {
        vm.transactions.filter { $0.category.direction == direction }
    }

    init(direction: Direction, client: NetworkClient, accountId: Int) {
        self.direction = direction
        self.client = client
        self.accountId = accountId
        _vm = StateObject(wrappedValue:
            TransactionsListViewModel(direction: direction, client: client, accountId: accountId)
        )
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGray6).ignoresSafeArea()

                content
                    .loading(vm.isLoading)
                    .refreshable { await vm.loadToday() }

                addButton
            }
            .navigationTitle(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .navigationBarTitleDisplayMode(.large)
            .toolbar { clockButton }
            .sheet(item: $formMode, onDismiss: {
                Task { await vm.loadToday() }
            }) { mode in
                switch mode {
                case .create(let dir, let acc):
                    TransactionFormView(mode: .create(direction: dir, accountId: acc))
                case .edit(let tx):
                    TransactionFormView(mode: .edit(transaction: tx))
                }
            }
            .task { await vm.loadToday() }
            
        }
    }

    private var content: some View {
        ScrollView {
            VStack(spacing: 0) {
                totalAmountCard
                operationsSection
                    .padding(.bottom, 80)
            }
        }
    }

    private var totalAmountCard: some View {
        HStack {
            Text("Всего")
            Spacer()
            Text(format(amount: vm.total))
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 4, y: 2)
        .padding(.horizontal)
        .padding(.top, 16)
    }

    private var operationsSection: some View {
        VStack(spacing: 0) {
            Text("ОПЕРАЦИИ")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .padding(.top, 8)

            LazyVStack(spacing: 0) {
                ForEach(filteredTransactions) { tx in
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
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private var addButton: some View {
        Button {
            formMode = .create(direction: direction, accountId: accountId)
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24))
                .foregroundColor(.white)
                .padding()
                .background(Color("AccentColor"))
                .clipShape(Circle())
                .shadow(radius: 6, y: 4)
        }
        .padding(.trailing, 24)
        .padding(.bottom, 24)
    }

    private var clockButton: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            NavigationLink {
                HistoryView(direction: direction,
                            client: client,
                            accountId: accountId)
                .navigationBarBackButtonHidden(true)
            } label: {
                Image(systemName: "clock")
                    .font(.system(size: 20))
                    .foregroundColor(Color("IconColor"))
            }
        }
    }

    private func format(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "0 \(currency.symbol)"
    }
}
