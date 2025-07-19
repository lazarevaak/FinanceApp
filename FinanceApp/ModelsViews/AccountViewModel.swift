import SwiftUI
import Combine

@MainActor
final class AccountViewModel: ObservableObject {
    @Published var account: BankAccount?
    @Published var isEditing = false

    @AppStorage("balanceText") private var storedBalanceText: String = ""
    @Published var balanceText: String = ""

    @Published var showCurrencyPicker = false
    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    var currency: Currency { Currency(rawValue: storedCurrency) ?? .ruble }

    private let service: BankAccountsService

    init(service: BankAccountsService = .init()) {
        self.service = service
        Task { await load() }
    }

    func load() async {
        let fetched = await service.getAccount()
        account = fetched
        balanceText = storedBalanceText.isEmpty ? fetched.balance.description : storedBalanceText
    }

    func save() async {
        guard var acc = account, let newBalance = Decimal(string: balanceText) else { return }
        acc.balance = newBalance
        await service.updateAccount(acc)
        storedBalanceText = balanceText
        isEditing = false
        hideKeyboard()
        await load()
    }

    func select(_ newCurrency: Currency) {
        guard storedCurrency != newCurrency.rawValue else { return }
        storedCurrency = newCurrency.rawValue
        showCurrencyPicker = false
        Task { await load() }
    }

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    func pasteBalanceFromClipboard() {
        if let clipboardText = UIPasteboard.general.string {
            let filtered = clipboardText.filter { "0123456789.".contains($0) }
            balanceText = filtered
        }
    }
}
