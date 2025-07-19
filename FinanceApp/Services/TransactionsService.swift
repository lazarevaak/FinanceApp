// TransactionsService.swift

import Foundation

private struct EmptyTransactionsRequest: Encodable {}
private struct EmptyTransactionsResponse: Decodable {}

struct NewTransactionRequest: Encodable {
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: String
    let comment: String?
}

struct UpdateTransactionRequest: Encodable {
    let id: Int
    let accountId: Int
    let categoryId: Int
    let amount: Decimal
    let transactionDate: String
    let comment: String?
}

final class TransactionsService {
    private let client: NetworkClient
    private let isoFormatter = ISO8601DateFormatter()

    init(client: NetworkClient) {
        self.client = client
    }

    /// GET /transactions?accountId=…&startDate=…&endDate=… → [Transaction]
    func fetchTransactions(accountId: Int, from start: Date, to end: Date) async throws -> [Transaction] {
        let items = [
            URLQueryItem(name: "accountId", value: "\(accountId)"),
            URLQueryItem(name: "startDate", value: isoFormatter.string(from: start)),
            URLQueryItem(name: "endDate", value: isoFormatter.string(from: end))
        ]
        return try await client.request(
            path: "transactions",
            method: "GET",
            body: nil as EmptyTransactionsRequest?,
            queryItems: items
        )
    }

    /// POST /transactions → Transaction
    func createTransaction(
        accountId: Int,
        categoryId: Int,
        amount: Decimal,
        date: Date,
        comment: String?
    ) async throws -> Transaction {
        let body = NewTransactionRequest(
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: isoFormatter.string(from: date),
            comment: comment
        )
        return try await client.request(
            path: "transactions",
            method: "POST",
            body: body,
            queryItems: []
        )
    }

    /// PUT /transactions/{id} → Transaction
    func updateTransaction(
        id: Int,
        accountId: Int,
        categoryId: Int,
        amount: Decimal,
        date: Date,
        comment: String?
    ) async throws -> Transaction {
        let body = UpdateTransactionRequest(
            id: id,
            accountId: accountId,
            categoryId: categoryId,
            amount: amount,
            transactionDate: isoFormatter.string(from: date),
            comment: comment
        )
        return try await client.request(
            path: "transactions/\(id)",
            method: "PUT",
            body: body,
            queryItems: []
        )
    }

    /// DELETE /transactions/{id}
    func deleteTransaction(id: Int) async throws {
        try await client.request(
            path: "transactions/\(id)",
            method: "DELETE",
            body: nil as EmptyTransactionsRequest?,
            queryItems: []
        )
    }
}
