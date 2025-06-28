import Foundation

final class CategoriesService {
    
    // MARK: - Data
    
    private let allCategories: [Category] = [
        .init(id: 1, name: "Зарплата", emoji: "💰", isIncome: true),
        .init(id: 2, name: "Квартира", emoji: "🏠", isIncome: false),
        .init(id: 3, name: "Продукты", emoji: "🍬", isIncome: false),
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
