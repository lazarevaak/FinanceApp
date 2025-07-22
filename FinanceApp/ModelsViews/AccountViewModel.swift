import SwiftUI
import Foundation

@MainActor
final class AccountViewModel: ObservableObject {

    // MARK: - Published
    @Published var account: BankAccount?
    @Published var isEditing = false
    @Published var balanceInput = ""
    @Published var showCurrencyPicker = false
    @Published var error: Error?

    @AppStorage("selectedCurrency") private var storedCurrency: String = Currency.ruble.rawValue
    @Published var selectedCurrency = Currency.ruble

    // MARK: - Dependencies
    private let service: BankAccountsService

    // MARK: - Init
    init(client: NetworkClient) {
        self.service = BankAccountsService(client: client)
        Task { await loadAccount() }
    }

    func loadAccount() async {
        do {
            let acc = try await service.getAccount()
            account = acc
            selectedCurrency = Currency(rawValue: storedCurrency) ?? .ruble
            balanceInput = Self.format(acc.balance)
        } catch {
            self.error = error
        }
    }

    func toggleEditing() {
        if isEditing {
            Task { await saveChanges() }
        } else if let acc = account {
            balanceInput = Self.format(acc.balance)
            selectedCurrency = Currency(rawValue: storedCurrency) ?? .ruble
        }
        isEditing.toggle()
    }

    private func saveChanges() async {
        guard let acc = account,
              let newBal = Decimal(string: sanitize(balanceInput))
        else { return }

        do {
            let updated = try await service.updateAccount(
                id: acc.id,
                name: acc.name,
                balance: newBal,
                currency: selectedCurrency.rawValue
            )
            account = updated
            balanceInput = Self.format(updated.balance)
            storedCurrency = selectedCurrency.rawValue
        } catch {
            self.error = error
        }
    }

    func sanitize(_ text: String) -> String {
        var clean = text
            .replacingOccurrences(of: ",", with: ".")
            .filter { "0123456789.".contains($0) }

        if let dot = clean.firstIndex(of: ".") {
            let after = clean.index(after: dot)
            clean = String(clean[..<after]) + clean[after...].replacingOccurrences(of: ".", with: "")
        }
        return clean
    }

    private static func format(_ value: Decimal) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f.string(for: value) ?? "0"
    }
}
