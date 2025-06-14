import Foundation

enum Direction {
    case income, outcome
}

struct Category: Codable, Identifiable {
    let id: Int
    let name: String
    let emoji: Character
    let isIncome: Bool

    var direction: Direction {
        isIncome ? .income : .outcome
    }

    // MARK: - CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id, name, emoji, isIncome
    }

    // MARK: - Init

    init(id: Int, name: String, emoji: Character, isIncome: Bool) {
        self.id = id
        self.name = name
        self.emoji = emoji
        self.isIncome = isIncome
    }

    // MARK: - Decodable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(Int.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)

        let emojiString = try container.decode(String.self, forKey: .emoji)
        guard let firstChar = emojiString.first else {
            throw DecodingError.dataCorruptedError(forKey: .emoji, in: container,
                                                   debugDescription: "Строка не один эмоджи или пустая строка.")
        }
        self.emoji = firstChar
        self.isIncome = try container.decode(Bool.self, forKey: .isIncome)
    }

    // MARK: - Encodable

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(String(emoji), forKey: .emoji)
        try container.encode(isIncome, forKey: .isIncome)
    }
}
