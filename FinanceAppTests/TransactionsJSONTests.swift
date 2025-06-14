import XCTest
@testable import FinanceApp

final class TransactionsJSONTests: XCTestCase {
    private let formatter: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return fmt
    }()

    private var sampleTransaction: Transaction {
        let dateString = "2025-06-14T12:34:56.000Z"
        guard let date = formatter.date(from: dateString) else {
            fatalError("Не удалось создать дату из строки")
        }
        let account = BankAccount(
            id: 1,
            name: "Test Account",
            balance: Decimal(string: "100.00")!,
            currency: "USD"
        )
        let category = Category(
            id: 2,
            name: "Test Category",
            emoji: "🔧",
            isIncome: false
        )
        return Transaction(
            id: 123,
            account: account,
            category: category,
            amount: Decimal(string: "25.50")!,
            transactionDate: date,
            comment: "Unit test",
            createdAt: date,
            updatedAt: date
        )
    }

    func testJsonObjectProducesValidDictionary() {
        let tx = sampleTransaction
        let jsonObj = tx.jsonObject
        guard let dict = jsonObj as? [String: Any] else {
            XCTFail("jsonObject должен быть словарём [String: Any]")
            return
        }
        XCTAssertEqual(dict["id"] as? Int, tx.id, "Поле id должно совпадать")
        XCTAssertEqual((dict["amount"] as? NSNumber)?.decimalValue, tx.amount, "Поле amount должно совпадать")
        XCTAssertEqual(dict["comment"] as? String, tx.comment, "Поле comment должно совпадать")

        if let dateStr = dict["transactionDate"] as? String,
           let parsed = ISO8601DateFormatter().date(from: dateStr) {
            XCTAssertEqual(parsed, tx.transactionDate, "transactionDate должно совпадать")
        } else {
            XCTFail("transactionDate отсутствует или некорректно парсится")
        }
        if let dateStr = dict["createdAt"] as? String,
           let parsed = ISO8601DateFormatter().date(from: dateStr) {
            XCTAssertEqual(parsed, tx.createdAt, "createdAt должно совпадать")
        } else {
            XCTFail("createdAt отсутствует или некорректно парсится")
        }
        if let dateStr = dict["updatedAt"] as? String,
           let parsed = ISO8601DateFormatter().date(from: dateStr) {
            XCTAssertEqual(parsed, tx.updatedAt, "updatedAt должно совпадать")
        } else {
            XCTFail("updatedAt отсутствует или некорректно парсится")
        }
    }

    func testParseValidJSONObjectReturnsTransaction() {
        let original = sampleTransaction
        let jsonObj = original.jsonObject
        guard let parsed = Transaction.parse(jsonObject: jsonObj) else {
            XCTFail("Парсинг корректного JSON-объекта не должен возвращать nil")
            return
        }
        XCTAssertEqual(parsed.id, original.id, "id должен совпадать")
        XCTAssertEqual(parsed.account.id, original.account.id, "account.id должен совпадать")
        XCTAssertEqual(parsed.account.name, original.account.name, "account.name должен совпадать")
        XCTAssertEqual(parsed.account.balance, original.account.balance, "account.balance должен совпадать")
        XCTAssertEqual(parsed.account.currency, original.account.currency, "account.currency должен совпадать")
        XCTAssertEqual(parsed.category.id, original.category.id, "category.id должен совпадать")
        XCTAssertEqual(parsed.category.name, original.category.name, "category.name должен совпадать")
        XCTAssertEqual(parsed.category.emoji, original.category.emoji, "category.emoji должен совпадать")
        XCTAssertEqual(parsed.category.isIncome, original.category.isIncome, "category.isIncome должен совпадать")
        XCTAssertEqual(parsed.amount, original.amount, "amount должен совпадать")
        XCTAssertEqual(parsed.transactionDate, original.transactionDate, "transactionDate должен совпадать")
        XCTAssertEqual(parsed.comment, original.comment, "comment должен совпадать")
        XCTAssertEqual(parsed.createdAt, original.createdAt, "createdAt должен совпадать")
        XCTAssertEqual(parsed.updatedAt, original.updatedAt, "updatedAt должен совпадать")
    }

    func testParseInvalidJSONObjectReturnsNil() {
        let nullObj = NSNull()
        XCTAssertNil(Transaction.parse(jsonObject: nullObj), "parse должен вернуть nil для NSNull")

        let incomplete: [String: Any] = ["id": 1]
        XCTAssertNil(Transaction.parse(jsonObject: incomplete), "parse должен вернуть nil для неполного словаря")
    }

    func testRoundTripSerializationAndParsing() {
        let original = sampleTransaction
        let origJson = original.jsonObject as? [String: Any]
        XCTAssertNotNil(origJson, "jsonObject исходного объекта не должен быть nil")

        guard let roundTrip = Transaction.parse(jsonObject: origJson as Any) else {
            XCTFail("Круговой парсинг не должен провалиться")
            return
        }
        let reJson = roundTrip.jsonObject as? [String: Any]
        XCTAssertNotNil(reJson, "jsonObject после парсинга не должен быть nil")

        let primitiveKeys: Set<String> = [
            "id", "amount", "comment",
            "transactionDate", "createdAt", "updatedAt"
        ]
        for key in primitiveKeys {
            let lhs = origJson![key]
            let rhs = reJson![key]
            if let num1 = lhs as? NSNumber, let num2 = rhs as? NSNumber {
                XCTAssertEqual(num1, num2, "Несоответствие по ключу \(key)")
            } else if let str1 = lhs as? String, let str2 = rhs as? String {
                XCTAssertEqual(str1, str2, "Несоответствие по ключу \(key)")
            } else {
                XCTFail("Невозможный или отсутствующий примитив для ключа \(key)")
            }
        }

        XCTAssertTrue(origJson!["account"] is [String: Any], "account должен быть словарём")
        XCTAssertTrue(origJson!["category"] is [String: Any], "category должен быть словарём")
        XCTAssertTrue(reJson!["account"] is [String: Any], "account после round-trip должен быть словарём")
        XCTAssertTrue(reJson!["category"] is [String: Any], "category после round-trip должен быть словарём")
    }

    func testJsonObjectErrorReturnsNSNull() {
        let date = formatter.date(from: "2025-06-14T12:34:56.000Z")!
        let badTransaction = Transaction(
            id: 999,
            account: BankAccount(
                id: 1,
                name: "Broken Account",
                balance: Decimal.nan,
                currency: "USD"
            ),
            category: Category(
                id: 1,
                name: "Broken Category",
                emoji: "❌",
                isIncome: true
            ),
            amount: Decimal.nan,
            transactionDate: date,
            comment: nil,
            createdAt: date,
            updatedAt: date
        )

        let jsonObj = badTransaction.jsonObject
        XCTAssertTrue(jsonObj is NSNull, "jsonObject должен возвращать NSNull() при ошибке кодирования")
    }
}
