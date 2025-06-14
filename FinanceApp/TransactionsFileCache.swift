import Foundation

final class TransactionsFileCache {
    
    // MARK: - Properties
    
    private var transactions: [Transaction] = []
    var allTransactions: [Transaction] { transactions }
    
    private let fileURL: URL
    
    private enum FileCacheError: Error {
        case invalidFormat
    }
    
    // MARK: - Init
    
    init(filename: String = "transactions.json") {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        self.fileURL = docs.appendingPathComponent(filename)
    }
    
    // MARK: - CRUD
    
    func add(_ tx: Transaction) {
        guard !transactions.contains(where: { $0.id == tx.id }) else { return }
        transactions.append(tx)
    }
    
    func remove(id: Int) {
        transactions.removeAll { $0.id == id }
    }
    
    // MARK: - Persistence
    
    func saveAll() throws {
        let array = transactions.map { $0.jsonObject }
        let data = try JSONSerialization.data(withJSONObject: array, options: [.prettyPrinted])
        try data.write(to: fileURL, options: [.atomicWrite])
    }
    
    func loadAll() throws {
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            transactions = []
            return
        }
        let data = try Data(contentsOf: fileURL)
        let json = try JSONSerialization.jsonObject(with: data, options: [])
        guard let array = json as? [Any] else {
            throw FileCacheError.invalidFormat
        }
        var loaded: [Transaction] = []
        for item in array {
            if let tx = Transaction.parse(jsonObject: item),
               !loaded.contains(where: { $0.id == tx.id }) {
                loaded.append(tx)
            }
        }
        transactions = loaded
    }
}
