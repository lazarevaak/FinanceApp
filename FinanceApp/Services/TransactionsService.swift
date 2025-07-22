import Foundation

final class TransactionsService {
    // MARK: - Dependencies
    let client: NetworkClient
    private let fileCache: TransactionsFileCache
    private let fileURL: URL

    // MARK: - Init
    init(client: NetworkClient, fileName: String = "transactions") {
        self.client = client
        self.fileCache = TransactionsFileCache()
        self.fileURL = TransactionsFileCache.defaultFileURL(fileName: fileName)

        try? fileCache.load(from: fileURL)
    }

    // MARK: - Cached
    var cachedTransactions: [Transaction] {
        fileCache.transactions
    }

    func refreshFromCache() {
        try? fileCache.load(from: fileURL)
    }

    // MARK: - Load
    func getTransactions(forAccount accountId: Int, from start: Date, to end: Date) async throws -> [Transaction] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        let queryItems = [
            URLQueryItem(name: "startDate", value: formatter.string(from: start)),
            URLQueryItem(name: "endDate", value: formatter.string(from: end))
        ]

        let path = "transactions/account/\(accountId)/period"

        let txs: [Transaction] = try await client.request(
            path: path,
            method: "GET",
            body: Optional<EmptyRequest>.none,
            queryItems: queryItems
        )

        fileCache.replaceAll(txs)
        try? fileCache.save(to: fileURL)

        return txs
    }

    // MARK: - Create
    func createTransaction(_ tx: TransactionRequestBody) async throws -> Transaction {
        let response: TransactionResponseBody = try await client.request(
            path: "transactions",
            method: "POST",
            body: tx
        )

        let bankAccountsService = BankAccountsService(client: client)
        let categoriesService = CategoriesService(client: client)

        let account = try await bankAccountsService.getAccount(withId: response.accountId)
        let category = try await categoriesService.getCategory(withId: response.categoryId)

        let formatter = ISO8601DateFormatter()

        let transaction = Transaction(
            id: response.id,
            account: account,
            category: category,
            amount: Decimal(string: response.amount) ?? 0,
            transactionDate: formatter.date(from: response.transactionDate) ?? Date(),
            comment: response.comment,
            createdAt: formatter.date(from: response.createdAt) ?? Date(),
            updatedAt: formatter.date(from: response.updatedAt) ?? Date()
        )

        fileCache.add(transaction)
        try? fileCache.save(to: fileURL)

        return transaction
    }



    // MARK: - Update
    func updateTransaction(id: Int, with tx: TransactionRequestBody) async throws -> Transaction {
        let updated: Transaction = try await client.request(
            path: "transactions/\(id)",
            method: "PUT",
            body: tx
        )

        fileCache.remove(withId: id)
        fileCache.add(updated)
        try? fileCache.save(to: fileURL)

        return updated
    }

    // MARK: - Delete
    func deleteTransaction(id: Int) async throws {
        _ = try await client.request(
            path: "transactions/\(id)",
            method: "DELETE",
            body: EmptyRequest()
        ) as Void

        fileCache.remove(withId: id)
        try? fileCache.save(to: fileURL)
    }
}
