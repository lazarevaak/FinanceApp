import Foundation

final class CategoriesService {
    
    // MARK: - Data
    
    private let allCategories: [Category] = [
        .init(id: 1, name: "Аренда квартиры", emoji: "🏠", isIncome: false),
        .init(id: 2, name: "Одежда", emoji: "👕", isIncome: false),
        .init(id: 3, name: "На собачку", emoji: "🐶", isIncome: false),
        .init(id: 4, name: "Ремонт квартиры", emoji: "🔨", isIncome: false),
        .init(id: 5, name: "Продукты", emoji: "🍏", isIncome: false),
        .init(id: 6, name: "Спортзал", emoji: "🏋️", isIncome: false),
        .init(id: 7, name: "Медицина", emoji: "💊", isIncome: false),
        .init(id: 8, name: "Аптека", emoji: "🏥", isIncome: false),
        .init(id: 9, name: "Машина", emoji: "🚗", isIncome: false),
    ]

    
    // MARK: - Public Methods
    
    func categories() async throws -> [Category] {
        try await Task.sleep(nanoseconds: 50_000_000)
        return allCategories
    }

    func categories(direction: Direction) async throws -> [Category] {
        try await Task.sleep(nanoseconds: 50_000_000)
        return allCategories.filter { $0.direction == direction }
    }
}
