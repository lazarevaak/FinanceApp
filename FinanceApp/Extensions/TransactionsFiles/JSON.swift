import Foundation

extension Transaction {
    
    // MARK: - JSON Parsing

    static func parse(jsonObject: Any) -> Transaction? {
        guard JSONSerialization.isValidJSONObject(jsonObject) else {
            return nil
        }
        do {
            let data = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return try decoder.decode(Transaction.self, from: data)
        } catch {
            print("Transaction.parse ошибка:", error)
            return nil
        }
    }

    // MARK: - JSON Serialization

    var jsonObject: Any {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(self)
            return try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            print("Transaction.jsonObject ошибка:", error)
            return NSNull()
        }
    }
}
