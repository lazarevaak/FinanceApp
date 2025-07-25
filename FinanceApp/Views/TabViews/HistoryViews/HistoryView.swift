import SwiftUI

struct HistoryView: View {
    let direction: Direction
    let accountId: Int
    let client: NetworkClient

    @StateObject private var vm: HistoryViewModel
    @Environment(\.dismiss) private var dismiss

    @AppStorage("selectedCurrency") private var storedCurrency = Currency.ruble.rawValue
    private var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    init(direction: Direction, client: NetworkClient, accountId: Int) {
        self.direction = direction
        self.accountId = accountId
        self.client = client
        _vm = StateObject(wrappedValue:
            HistoryViewModel(direction: direction,
                             accountId: accountId,
                             client: client)
        )
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        filterBlock
                        transactionsList
                    }
                    .padding(.bottom, 32)
                }
                .loading(vm.isLoading)
            }
            .navigationTitle("Моя история")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Назад")
                        }
                        .foregroundColor(Color("IconColor"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        AnalysisViewControllerWrapper(
                            direction: direction,
                            accountId: accountId,
                            client: client
                        )
                        .edgesIgnoringSafeArea(.top)
                        .navigationBarBackButtonHidden(true)
                    } label: {
                        Image(systemName: "doc")
                            .foregroundColor(Color("IconColor"))
                    }
                }
            }
            .onAppear { Task { await vm.reload() } }
            
        }
    }

    private var filterBlock: some View {
        VStack(spacing: 0) {
            periodRow(title: "Начало", date: $vm.startDate)
            Divider()
            periodRow(title: "Конец", date: $vm.endDate)
            Divider()
            HStack {
                Text("Сортировка")
                Spacer()
                Picker("", selection: $vm.sorting) {
                    Text("По дате").tag(HistoryViewModel.SortingType.byDate)
                    Text("По сумме").tag(HistoryViewModel.SortingType.byAmount)
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }
            .padding(.vertical, 10)
            Divider()
            HStack {
                Text("Сумма")
                Spacer()
                Text(format(amount: vm.total))
            }
            .padding(.vertical, 10)
        }
        .padding(.horizontal)
        .background(Color.white)
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top)
    }

    private var transactionsList: some View {
        Group {
            Text("ОПЕРАЦИИ")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)

            LazyVStack(spacing: 0) {
                ForEach(vm.transactions) { tx in
                    TransactionRow(transaction: tx)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                    Divider()
                        .padding(.leading, 48)
                }
            }
            .background(Color.white)
            .cornerRadius(12)
            .padding(.horizontal)
        }
    }

    private func periodRow(title: String, date: Binding<Date>) -> some View {
        HStack {
            Text(title)
            Spacer()
            ZStack {
                Text(date.wrappedValue,
                     format: Date.FormatStyle().day().month(.wide).year())
                    .font(.callout)
                    .foregroundColor(.primary)
                    .frame(width: 142, height: 36)
                    .background(Color.accentColor.opacity(0.2))
                    .cornerRadius(8)

                DatePicker("", selection: date, in: ...Date(), displayedComponents: [.date])
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .tint(.accentColor)
                    .frame(width: 142, height: 36)
                    .blendMode(.destinationOver)
            }
        }
        .padding(.vertical, 6)
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
