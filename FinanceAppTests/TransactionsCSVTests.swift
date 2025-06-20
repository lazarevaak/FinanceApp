import XCTest
@testable import FinanceApp

final class TransactionsCSVTests: XCTestCase {
    private let formatter: ISO8601DateFormatter = {
        let fmt = ISO8601DateFormatter()
        return fmt
    }()

    private var sampleTransaction: Transaction {
        let dateString = "2025-06-14T12:34:56Z"
        guard let date = formatter.date(from: dateString) else {
            fatalError("Не удалось распарсить дату")
        }
        let account = BankAccount(
            id: 42,
            name: "My Account",
            balance: Decimal(string: "1234.56")!,
            currency: "EUR"
        )
        let category = Category(
            id: 7,
            name: "Groceries",
            emoji: "🛒",
            isIncome: false
        )
        return Transaction(
            id: 99,
            account: account,
            category: category,
            amount: Decimal(string: "78.90")!,
            transactionDate: date,
            comment: "Покупки на неделю",
            createdAt: date,
            updatedAt: date
        )
    }

    func testToCSVProducesCorrectNumberOfFieldsAndValues() {
        let tx = sampleTransaction
        let csv = tx.toCSV
        let parts = csv.split(separator: ",", omittingEmptySubsequences: false).map(String.init)

        XCTAssertEqual(parts.count, 14, "CSV должен содержать ровно 14 полей")

        XCTAssertEqual(Int(parts[0]), tx.id)
        XCTAssertEqual(Int(parts[1]), tx.account.id)
        XCTAssertEqual(parts[2], tx.account.name)
        XCTAssertEqual(Decimal(string: parts[3]), tx.account.balance)
        XCTAssertEqual(parts[4], tx.account.currency)
        XCTAssertEqual(Int(parts[5]), tx.category.id)
        XCTAssertEqual(parts[6], tx.category.name)
        XCTAssertEqual(parts[7].first, tx.category.emoji)
        XCTAssertEqual(Bool(parts[8]), tx.category.isIncome)
        XCTAssertEqual(Decimal(string: parts[9]), tx.amount)

        guard let txDate = formatter.date(from: parts[10]) else {
            XCTFail("Поле transactionDate не является корректной датой")
            return
        }
        XCTAssertEqual(txDate, tx.transactionDate)

        XCTAssertEqual(parts[11].isEmpty ? nil : parts[11], tx.comment)

        guard let created = formatter.date(from: parts[12]) else {
            XCTFail("Поле createdAt не является корректной датой")
            return
        }
        XCTAssertEqual(created, tx.createdAt)

        guard let updated = formatter.date(from: parts[13]) else {
            XCTFail("Поле updatedAt не является корректной датой")
            return
        }
        XCTAssertEqual(updated, tx.updatedAt)
    }

    func testFromCSVValidLineReturnsEquivalentTransaction() {
        let original = sampleTransaction
        let csv = original.toCSV

        guard let parsed = Transaction.fromCSV(csv) else {
            XCTFail("fromCSV должен вернуть объект Transaction при корректной строке CSV")
            return
        }

        XCTAssertEqual(parsed.id, original.id)
        XCTAssertEqual(parsed.account.id, original.account.id)
        XCTAssertEqual(parsed.account.name, original.account.name)
        XCTAssertEqual(parsed.account.balance, original.account.balance)
        XCTAssertEqual(parsed.account.currency, original.account.currency)
        XCTAssertEqual(parsed.category.id, original.category.id)
        XCTAssertEqual(parsed.category.name, original.category.name)
        XCTAssertEqual(parsed.category.emoji, original.category.emoji)
        XCTAssertEqual(parsed.category.isIncome, original.category.isIncome)
        XCTAssertEqual(parsed.amount, original.amount)
        XCTAssertEqual(parsed.transactionDate, original.transactionDate)
        XCTAssertEqual(parsed.comment, original.comment)
        XCTAssertEqual(parsed.createdAt, original.createdAt)
        XCTAssertEqual(parsed.updatedAt, original.updatedAt)
    }

    func testFromCSVLineWithEmptyCommentFieldYieldsNilComment() {
        var parts = sampleTransaction.toCSV
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(String.init)
        parts[11] = ""
        let csv = parts.joined(separator: ",")

        guard let parsed = Transaction.fromCSV(csv) else {
            XCTFail("fromCSV должен успешно разобрать строку даже с пустым комментарием")
            return
        }
        XCTAssertNil(parsed.comment, "Пустое поле комментария должно давать nil")
    }

    func testFromCSVInvalidNumberOfFieldsReturnsNil() {
        let tooFew = "1,2,Three,4"
        XCTAssertNil(Transaction.fromCSV(tooFew), "fromCSV должен возвращать nil, если полей меньше 14")

        let tooMany = Array(repeating: "x", count: 15).joined(separator: ",")
        XCTAssertNil(Transaction.fromCSV(tooMany), "fromCSV должен возвращать nil, если полей больше 14")
    }

    func testFromCSVWithMalformedFieldsReturnsNil() {
        var parts = sampleTransaction.toCSV
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(String.init)
        parts[0] = "не число"
        let csvBadId = parts.joined(separator: ",")
        XCTAssertNil(Transaction.fromCSV(csvBadId), "fromCSV должен возвращать nil, если поле id некорректное")

        parts = sampleTransaction.toCSV
            .split(separator: ",", omittingEmptySubsequences: false)
            .map(String.init)
        parts[10] = "не дата"
        let csvBadDate = parts.joined(separator: ",")
        XCTAssertNil(Transaction.fromCSV(csvBadDate), "fromCSV должен возвращать nil, если поле даты некорректное")
    }
}
