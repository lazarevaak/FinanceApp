import SwiftUI
import UIKit
import Charts

extension Notification.Name {
    static let operationsDidChange = Notification.Name("operationsDidChange")
}

struct AccountView: View {
    let client: NetworkClient

    @StateObject private var vm: AccountViewModel
    @FocusState private var isFocused: Bool
    @State private var showCurrencyDialog = false
    @State private var hideBalance = true

    init(client: NetworkClient) {
        self.client = client
        _vm = StateObject(wrappedValue: AccountViewModel(client: client))
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        balanceRow
                        currencyRow
                        chartSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                }
                .refreshable {
                    await vm.loadAccount()
                }
            }
            .background(Color(.systemGroupedBackground).ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    editButton
                }
            }
            .confirmationDialog("Валюта", isPresented: $showCurrencyDialog, titleVisibility: .visible) {
                ForEach(Currency.allCases) { cur in
                    Button(cur.displayName) {
                        vm.selectedCurrency = cur
                    }
                }
            }
            .tint(.black)
            .gesture(
                DragGesture().onChanged { _ in
                    UIApplication.shared.sendAction(
                        #selector(UIResponder.resignFirstResponder),
                        to: nil, from: nil, for: nil
                    )
                }
            )
            .overlay(
                ShakeDetectorView()
                    .allowsHitTesting(false)
                    .id(vm.isEditing)
            )
        }
        .alert("Ошибка", isPresented: Binding(
            get: { vm.error != nil },
            set: { _ in vm.error = nil }
        )) {
            Button("Ок", role: .cancel) {}
        } message: {
            Text(vm.error?.localizedDescription ?? "Неизвестная ошибка")
        }
        .onAppear {
            Task { await vm.loadAccount() }
        }
        .onReceive(NotificationCenter.default.publisher(for: .operationsDidChange)) { _ in
            Task { await vm.loadAccount() }
        }
    }

    // MARK: — Subviews

    private var header: some View {
        Text("Мой счёт")
            .font(.largeTitle.bold())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
    }

    private var balanceRow: some View {
        HStack {
            Text("💰 Баланс")
            Spacer()
            if vm.isEditing {
                TextField("", text: $vm.balanceInput)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .focused($isFocused)
                    .onChange(of: vm.balanceInput) { _, new in
                        vm.balanceInput = vm.sanitize(new)
                    }
            } else {
                Text(vm.account?.balance.formatted(
                    .currency(code: vm.selectedCurrency.rawValue)
                        .locale(Locale(identifier: "ru_RU"))
                        .precision(.fractionLength(0))
                ) ?? "—")
                .spoiler(isOn: $hideBalance)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(vm.isEditing ? Color(.systemBackground) : Color.accentColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .contentShape(Rectangle())
        .onTapGesture { if vm.isEditing { isFocused = true } }
    }

    private var currencyRow: some View {
        HStack {
            Text("Валюта")
            Spacer()
            Text(vm.selectedCurrency.symbol)
                .foregroundColor(vm.isEditing ? .black : .primary)
            if vm.isEditing {
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(vm.isEditing
                    ? Color(.systemBackground)
                    : Color.accentColor.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture {
            if vm.isEditing { showCurrencyDialog = true }
        }
    }

    private var chartSection: some View {
        Group {
            if !vm.isEditing {
                Picker("", selection: $vm.selectedChartMode) {
                    ForEach(AccountViewModel.ChartMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .onChange(of: vm.selectedChartMode) { _ in
                    handleChartModeChange()
                }

                BalanceChartView(entries: vm.balanceEntries)
                    .transition(.opacity.combined(with: .slide))
                    .animation(.easeInOut, value: vm.balanceEntries)
            }
        }
    }

    private var editButton: some View {
        Button(vm.isEditing ? "Сохранить" : "Редактировать") {
            UIApplication.shared.sendAction(
                #selector(UIResponder.resignFirstResponder),
                to: nil, from: nil, for: nil
            )
            hideBalance = true
            vm.toggleEditing()
            isFocused = false
        }
        .foregroundColor(.black)
    }

    // MARK: — Actions
    private func handleChartModeChange() {
        withAnimation(.easeInOut) {
            Task { await vm.loadAccount() }
        }
    }
}
