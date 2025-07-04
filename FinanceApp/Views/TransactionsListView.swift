import SwiftUI

// MARK: - TransactionsListView
struct TransactionsListView: View {
    let direction: Direction

    @StateObject private var vm = TransactionsListViewModel()
    @State private var isShowingHistory = false

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    private var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                Color(.systemGray6)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
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

                        Text("ОПЕРАЦИИ")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .padding(.top, 8)

                        LazyVStack(spacing: 0) {
                            ForEach(vm.transactions.filter { $0.category.direction == direction }) { tx in
                                NavigationLink {
                                    // TODO: Edit screen
                                } label: {
                                    TransactionRow(transaction: tx)
                                        .padding(.horizontal, 8)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading,
                                             tx.category.direction == .outcome ? 56 : 16)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                }

                Button {
                    // TODO: Add transaction
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
            .navigationTitle(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(
                        destination: HistoryView(direction: direction),
                        isActive: $isShowingHistory
                    ) {
                        Image(systemName: "clock")
                            .font(.system(size: 20))
                            .foregroundColor(Color("IconColor"))
                    }
                    .onTapGesture { isShowingHistory = true }
                }
            }
        }
        .task {
            await vm.fetchTransactionsForToday()
        }
    }

    // MARK: - Computed Properties
    private var totalAmount: Decimal {
        vm.transactions
            .filter { $0.category.direction == direction }
            .map(\.amount)
            .reduce(0, +)
    }

    // MARK: - Amount Formatting
    private func format(amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = currency.symbol
        formatter.maximumFractionDigits = 0
        return formatter.string(from: amount as NSDecimalNumber) ?? "0 \(currency.symbol)"
    }
}

