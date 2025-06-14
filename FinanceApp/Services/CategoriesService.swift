import Foundation

final class CategoriesService {
    
    // MARK: - Data
    
    private let allCategories: [Category] = [
        .init(id: 1, name: "Зарплата", emoji: "💰", isIncome: true)
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
