import XCTest
@testable import FinanceApp

final class TransactionsFileCacheTests: XCTestCase {
    private let testFilename = "test_transactions.json"
    private var fileURL: URL!
    private var cache: TransactionsFileCache!
    private let formatter: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt
    }()

    private var sampleTransaction: Transaction {
        let date = formatter.date(from: "2025-06-14T12:34:56.000Z")!
        let account = BankAccount(
            id: 1,
            name: "TestAcct",
            balance: Decimal(string: "100.00")!,
            currency: "USD"
        )
        let category = Category(
            id: 2,
            name: "TestCat",
            emoji: "✅",
            isIncome: true
        )
        return Transaction(
            id: 42,
            account: account,
            category: category,
            amount: Decimal(string: "50.00")!,
            transactionDate: date,
            comment: "cache test",
            createdAt: date,
            updatedAt: date
        )
    }

    override func setUp() {
        super.setUp()
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        fileURL = docs.appendingPathComponent(testFilename)
        try? FileManager.default.removeItem(at: fileURL)
        cache = TransactionsFileCache(filename: testFilename)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: fileURL)
        cache = nil
        super.tearDown()
    }

    func testAddAndRemoveTransactions() {
        XCTAssertTrue(cache.allTransactions.isEmpty)

        let tx = sampleTransaction
        cache.add(tx)
        XCTAssertEqual(cache.allTransactions.count, 1)
        XCTAssertEqual(cache.allTransactions.first?.id, tx.id)

        cache.add(tx)
        XCTAssertEqual(cache.allTransactions.count, 1)

        cache.remove(id: tx.id)
        XCTAssertTrue(cache.allTransactions.isEmpty)
    }

    func testLoadAllWhenNoFileYieldsEmptyTransactions() throws {
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        cache.add(sampleTransaction)
        XCTAssertFalse(cache.allTransactions.isEmpty)
        try cache.loadAll()
        XCTAssertTrue(cache.allTransactions.isEmpty)
    }

    func testLoadAllThrowsOnInvalidFormat() throws {
        let bad = ["not": "an array"]
        let data = try JSONSerialization.data(withJSONObject: bad, options: [])
        try data.write(to: fileURL)
        XCTAssertThrowsError(try cache.loadAll(), "loadAll должен бросать ошибку при неверном формате JSON")
    }

    func testLoadAllDeduplicatesById() throws {
        let tx = sampleTransaction
        let obj = tx.jsonObject as! [String: Any]
        var duplicate = obj
        duplicate["comment"] = "duplicate"
        let array = [obj, duplicate]
        let data = try JSONSerialization.data(withJSONObject: array, options: [])
        try data.write(to: fileURL)

        try cache.loadAll()
        let loaded = cache.allTransactions
        XCTAssertEqual(loaded.count, 1, "Дубликаты по id должны удаляться")
        XCTAssertEqual(loaded[0].comment, tx.comment)
    }
}
