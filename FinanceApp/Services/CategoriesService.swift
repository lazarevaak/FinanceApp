// CategoriesService.swift

import Foundation

private struct EmptyCategoriesRequest: Encodable {}

final class CategoriesService {
    private let client: NetworkClient

    init(client: NetworkClient) {
        self.client = client
    }

    /// GET /categories → [Category]
    func fetchAll() async throws -> [Category] {
        try await client.request(
            path: "categories",
            method: "GET",
            body: nil as EmptyCategoriesRequest?,
            queryItems: []
        )
    }

    /// Фильтрация по направлению
    func fetch(direction: Direction) async throws -> [Category] {
        let all = try await fetchAll()
        return all.filter { $0.direction == direction }
    }
}
