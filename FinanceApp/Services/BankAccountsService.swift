// BankAccountsService.swift

import Foundation

private struct EmptyAccountRequest: Encodable {}

final class BankAccountsService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    /// GET /accounts → [BankAccount] → возвращаем первый
    func getAccount() async throws -> BankAccount {
        let accounts: [BankAccount] = try await client.request(
            path: "accounts",
            method: "GET",
            body: nil as EmptyAccountRequest?,
            queryItems: []
        )
        guard let first = accounts.first else {
            throw NSError(domain: "BankAccountsService", code: 0, userInfo: [
                NSLocalizedDescriptionKey: "У пользователя нет ни одного счёта"
            ])
        }
        return first
    }

    /// GET /accounts → [BankAccount] → фильтрация по id
    func getAccount(withId id: Int) async throws -> BankAccount {
        let accounts: [BankAccount] = try await client.request(
            path: "accounts",
            method: "GET",
            body: nil as EmptyAccountRequest?,
            queryItems: []
        )
        guard let acct = accounts.first(where: { $0.id == id }) else {
            throw NSError(domain: "BankAccountsService", code: 404, userInfo: [
                NSLocalizedDescriptionKey: "Счёт с id \(id) не найден"
            ])
        }
        return acct
    }

    /// PUT /accounts/{id} → BankAccount
    func updateAccount(
        id: Int,
        name: String,
        balance: Decimal,
        currency: String
    ) async throws -> BankAccount {
        struct UpdateAccountRequest: Encodable {
            let name: String
            let balance: String
            let currency: String
        }
        let body = UpdateAccountRequest(
            name: name,
            balance: balance.description,
            currency: currency
        )
        return try await client.request(
            path: "accounts/\(id)",
            method: "PUT",
            body: body,
            queryItems: []
        )
    }
}
