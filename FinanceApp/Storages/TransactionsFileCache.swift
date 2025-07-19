import Foundation

final class TransactionsFileCache {

    // MARK: - Storage
    private(set) var transactions: [Transaction] = []

    // MARK: CRUD
    func add(_ tx: Transaction) { guard !transactions.contains(where: { $0.id == tx.id }) else { return }; transactions.append(tx) }
    func remove(withId id: Int) { transactions.removeAll { $0.id == id } }
    func replaceAll(_ all: [Transaction]) { transactions = all }

    // MARK: Save
    func save(to url: URL) throws {
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
        enc.dateEncodingStrategy = .iso8601
        try enc.encode(transactions).write(to: url, options: .atomic)
    }

    // MARK: Load
    func load(from url: URL) throws {
        guard FileManager.default.fileExists(atPath: url.path) else { transactions = []; return }

        let data = try Data(contentsOf: url)
        let dec  = JSONDecoder()
        dec.dateDecodingStrategy = .custom { d in
            let s = try d.singleValueContainer().decode(String.self)
            if let date = ISO8601Any.date(from: s) { return date }
            throw DecodingError.dataCorruptedError(in: try d.singleValueContainer(),
                                                   debugDescription: "Bad date: \(s)")
        }
        transactions = try dec.decode([Transaction].self, from: data)
    }

    // MARK: Helpers
    static func defaultFileURL(fileName: String) -> URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("\(fileName).json")
    }
}
