// TransactionFormView.swift

import SwiftUI

// MARK: — Подвьюы

struct CategoryRowView: View {
    @Binding var category: Category?
    @Binding var showPicker: Bool

    var body: some View {
        Button {
            showPicker = true
        } label: {
            HStack {
                Text("Статья")
                    .foregroundColor(.black)
                Spacer()
                Text(category?.name ?? "Выберите статью")
                    .foregroundColor(category == nil ? .secondary : .primary)
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .listRowBackground(Color.white)
    }
}

struct AmountRowView: View {
    @Binding var amountString: String
    let currencySymbol: String
    var onChange: (String) -> Void
    var isFocused: FocusState<Bool>.Binding

    var body: some View {
        HStack {
            Text("Сумма")
            Spacer()
            TextField("0", text: $amountString)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .focused(isFocused)
                .onChange(of: amountString, perform: onChange)
            Text(currencySymbol)
                .foregroundColor(.secondary)
        }
        .listRowBackground(Color.white)
    }
}

struct DateRowView: View {
    @Binding var date: Date

    var body: some View {
        HStack {
            Text("Дата")
            Spacer()
            ZStack {
                Text(
                    date,
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

                DatePicker(
                    "",
                    selection: $date,
                    in: ...Date(),
                    displayedComponents: [.date]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(.accentColor)
                .frame(width: 142, height: 36)
                .blendMode(.destinationOver)
            }
        }
        .listRowBackground(Color.white)
    }
}

struct TimeRowView: View {
    @Binding var date: Date

    var body: some View {
        HStack {
            Text("Время")
            Spacer()
            ZStack {
                Text(
                    date,
                    format: Date.FormatStyle()
                        .hour(.twoDigits(amPM: .omitted))
                        .minute(.twoDigits)
                )
                .font(.callout)
                .foregroundColor(.primary)
                .frame(width: 142, height: 36)
                .background(Color.accentColor.opacity(0.2))
                .cornerRadius(8)

                DatePicker(
                    "",
                    selection: $date,
                    displayedComponents: [.hourAndMinute]
                )
                .labelsHidden()
                .datePickerStyle(.compact)
                .tint(.accentColor)
                .frame(width: 142, height: 36)
                .blendMode(.destinationOver)
            }
        }
        .listRowBackground(Color.white)
    }
}

struct CommentSectionView: View {
    @Binding var comment: String

    var body: some View {
        ZStack(alignment: .topLeading) {
            if comment.isEmpty {
                Text("Комментарий")
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 12)
            }
            TextEditor(text: $comment)
                .padding(4)
                .frame(minHeight: 44, maxHeight: 100)
        }
        .background(Color.white)
        .cornerRadius(6)
        .listRowInsets(
            EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        )
    }
}

struct DeleteSectionView: View {
    let action: () -> Void
    let isOutcome: Bool

    var body: some View {
        Section {
            Button("Удалить \(isOutcome ? "расход" : "доход")") {
                action()
            }
            .foregroundColor(.red)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
        }
        .listRowBackground(Color.white)
    }
}

// MARK: — Выбор категории

struct CategoryPickerView: View {
    @Binding var selected: Category?
    let categories: [Category]
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            List(categories) { cat in
                Button(cat.name) {
                    selected = cat
                    onDismiss()
                }
                .foregroundColor(.primary)
            }
            .navigationTitle("Выберите статью")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена", action: onDismiss)
                }
            }
        }
    }
}

// MARK: — Главный экран формы

struct TransactionFormView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm: TransactionFormViewModel
    @FocusState private var amountFocused: Bool
    @State private var showValidationAlert = false

    // теперь храним accountId в самом вью
    private let accountId: Int

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    private var currencySymbol: String {
        Currency(rawValue: storedCurrency)?.symbol ?? ""
    }

    init(mode: TransactionFormMode, accountId: Int) {
        self.accountId = accountId

        // Настраиваем внешний вид навбара
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.backgroundEffect = nil
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance

        // Преобразуем внешний режим в внутренний
        let internalMode: TransactionFormModeInternal = {
            switch mode {
            case .create(let dir): return .create(direction: dir)
            case .edit(let tx):    return .edit(transaction: tx)
            }
        }()

        // Инициализируем ViewModel с реальным accountId
        _vm = StateObject(
            wrappedValue: TransactionFormViewModel(
                mode: internalMode,
                accountId: accountId
            )
        )
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    CategoryRowView(
                        category: $vm.category,
                        showPicker: $vm.showCategoryPicker
                    )
                    AmountRowView(
                        amountString: $vm.amountString,
                        currencySymbol: currencySymbol,
                        onChange: filterAmount,
                        isFocused: $amountFocused
                    )
                    DateRowView(date: $vm.date)
                    TimeRowView(date: $vm.date)
                    CommentSectionView(comment: $vm.comment)
                }
                .listSectionSeparator(.hidden, edges: .top)

                if vm.mode.isEdit {
                    DeleteSectionView(
                        action: { Task { await vm.delete(); dismiss() } },
                        isOutcome: vm.direction == .outcome
                    )
                    .listSectionSeparator(.hidden, edges: .top)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(.systemGroupedBackground))
            .listSectionSeparator(.hidden)
            .listStyle(.plain)
            .navigationTitle(
                vm.mode.isCreate
                    ? (vm.direction == .income ? "Мои Доходы" : "Мои Расходы")
                    : "Редактировать"
            )
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarBackground(
                Color(.systemGroupedBackground),
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Отмена") { dismiss() }
                        .tint(Color("IconColor"))
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(vm.mode.isCreate ? "Создать" : "Сохранить") {
                        if vm.canSave {
                            Task {
                                await vm.save()
                                dismiss()
                            }
                        } else {
                            showValidationAlert = true
                        }
                    }
                    .tint(Color("IconColor"))
                }
            }
            .alert("Заполните все поля", isPresented: $showValidationAlert) {
                Button("OK", role: .cancel) {}
            }
            .sheet(isPresented: $vm.showCategoryPicker) {
                CategoryPickerView(
                    selected: $vm.category,
                    categories: vm.categories,
                    onDismiss: { vm.showCategoryPicker = false }
                )
            }
            .onAppear {
                if vm.mode.isCreate {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        amountFocused = true
                    }
                }
            }
        }
    }

    private func filterAmount(_ newValue: String) {
        let sep = Locale.current.decimalSeparator ?? "."
        var filtered = newValue.filter { ch in
            ch.isNumber || String(ch) == sep
        }
        let parts = filtered.components(separatedBy: sep)
        if parts.count > 2 {
            filtered = parts[0] + sep + parts[1]
        }
        if filtered != vm.amountString {
            vm.amountString = filtered
        }
    }
}
