import SwiftUI

// MARK: - TransactionsListView
struct TransactionsListView: View {
    let direction: Direction

    // MARK: - State
    @StateObject private var vm = TransactionsListViewModel()
    @State private var isShowingHistory = false

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack(alignment: .bottomTrailing) {
                // MARK: - Background
                Color(.systemGray6)
                    .ignoresSafeArea()

                // MARK: - Scroll Content
                ScrollView {
                    VStack(spacing: 0) {
                        // MARK: - Total Section
                        HStack {
                            Text("Всего")
                            Spacer()
                            Text(vm.totalFormatted(for: direction))
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .background(Color.white)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
                        .padding(.horizontal)
                        .padding(.top, 16)

                        // MARK: - Label
                        Text("ОПЕРАЦИИ")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .padding(.top, 8)

                        // MARK: - Transactions List
                        LazyVStack(spacing: 0) {
                            ForEach(vm.transactions.filter { $0.category.direction == direction }) { tx in
                                NavigationLink {
                                    // TODO: Экран Pедактирования
                                } label: {
                                    TransactionRow(transaction: tx)
                                        .padding(.horizontal, 8)
                                }
                                .buttonStyle(.plain)

                                Divider()
                                    .padding(.leading,
                                             tx.category.direction == .outcome
                                                ? 56 : 16)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 80)
                    }
                }

                // MARK: - Add Button
                Button {
                    // TODO: Переход на Экран "Мои Доходы/Расходы"
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 24))
                        .foregroundColor(.white)
                        .padding()
                        .background(Color("AccentColor"))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.2),
                                radius: 6, x: 0, y: 4)
                }
                .padding(.trailing, 24)
                .padding(.bottom, 24)
            }
            .navigationTitle(direction == .income ? "Доходы сегодня" : "Расходы сегодня")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                // MARK: - Toolbar
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
            // MARK: - Fetch Transactions
            await vm.fetchTransactionsForToday()
        }
    }
}
