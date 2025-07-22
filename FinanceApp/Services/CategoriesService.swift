import Foundation

private struct EmptyCategoriesRequest: Encodable {}

final class CategoriesService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    func fetchAll() async throws -> [Category] {
        try await client.request(
            path: "categories",
            method: "GET",
            body: nil as EmptyCategoriesRequest?,
            queryItems: []
        )
    }

    func fetch(direction: Direction) async throws -> [Category] {
        let all = try await fetchAll()
        return all.filter { $0.direction == direction }
    }

    func getCategory(withId id: Int) async throws -> Category {
        let all = try await fetchAll()
        guard let category = all.first(where: { $0.id == id }) else {
            throw NSError(domain: "CategoriesService",
                          code: 404,
                          userInfo: [NSLocalizedDescriptionKey: "Category with ID \(id) not found"])
        }
        return category
    }
}
