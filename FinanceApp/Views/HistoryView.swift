import SwiftUI

// MARK: - HistoryView
struct HistoryView: View {
    // MARK: - Properties
    let direction: Direction
    @StateObject private var vm: HistoryViewModel
    @Environment(\.presentationMode) private var presentationMode

    // Persist selected currency
    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    private var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    // MARK: - Init
    init(direction: Direction) {
        self.direction = direction
        _vm = StateObject(wrappedValue: HistoryViewModel(direction: direction))
    }

    // MARK: - Body
    var body: some View {
        NavigationView {
            ZStack {
                Color(.systemGray6).ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 16) {
                        // MARK: - Date Filter & Controls
                        VStack(spacing: 0) {
                            periodRow(
                                title: "Начало",
                                date: Binding(
                                    get: { vm.startDate },
                                    set: { new in
                                        vm.startDate = new
                                        if new > vm.endDate { vm.endDate = new }
                                        Task { await vm.reload() }
                                    }
                                )
                            )
                            Divider()
                            periodRow(
                                title: "Конец",
                                date: Binding(
                                    get: { vm.endDate },
                                    set: { new in
                                        vm.endDate = new
                                        if new < vm.startDate { vm.startDate = new }
                                        Task { await vm.reload() }
                                    }
                                )
                            )
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
                                // Compute total and format
                                Text(format(amount: vm.transactions.map(\.amount).reduce(0, +)))
                            }
                            .padding(.vertical, 10)
                        }
                        .padding(.horizontal)
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.top)

                        // MARK: - Transactions List
                        Text("ОПЕРАЦИИ")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.horizontal, 8)

                        LazyVStack(spacing: 0) {
                            ForEach(vm.transactions) { tx in
                                TransactionRow(transaction: tx)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                Divider().padding(.leading, 48)
                            }
                        }
                        .background(Color.white)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Моя история")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.backward")
                            Text("Назад")
                        }
                        .foregroundColor(Color("IconColor"))
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        // future action
                    } label: {
                        Image("icon_trailing")
                            .renderingMode(.template)
                            .foregroundColor(Color("IconColor"))
                    }
                }
            }
            .onAppear { Task { await vm.reload() } }
        }
        .environment(\.locale, Locale(identifier: "ru"))
        .navigationBarBackButtonHidden(true)
        .interactiveDismissDisabled(true)
    }

    // MARK: - Private Helpers
    @ViewBuilder
    private func periodRow(title: String, date: Binding<Date>) -> some View {
        HStack {
            Text(title)
            Spacer()
            ZStack {
                Text(
                    date.wrappedValue,
                    format: Date.FormatStyle()
                        .day()
                        .month(.wide)
                        .year()
                )
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
                    .onChange(of: date.wrappedValue) { _, _ in
                        Task { await vm.reload() }
                    }
            }
        }
        .padding(.vertical, 6)
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
