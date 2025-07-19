import SwiftUI

// MARK: – String+Fuzzy
extension String {
    fileprivate var normalized: String {
        folding(options: .diacriticInsensitive, locale: .current)
            .lowercased()
    }

    func levenshteinDistance(to other: String) -> Int {
        let s = Array(self)
        let t = Array(other)
        let n = s.count, m = t.count
        guard n > 0 else { return m }
        guard m > 0 else { return n }

        var dp = [[Int]](
            repeating: [Int](repeating: 0, count: m+1),
            count: n+1
        )
        for i in 0...n { dp[i][0] = i }
        for j in 0...m { dp[0][j] = j }

        for i in 1...n {
            for j in 1...m {
                if s[i-1] == t[j-1] {
                    dp[i][j] = dp[i-1][j-1]
                } else {
                    dp[i][j] = Swift.min(
                        dp[i-1][j] + 1,
                        dp[i][j-1] + 1,
                        dp[i-1][j-1] + 1
                    )
                }
            }
        }
        return dp[n][m]
    }
}

// MARK: – CategoriesViewModel с fuzzy-фильтром
@MainActor
final class CategoriesViewModel: ObservableObject {
    @Published private(set) var allCategories: [Category] = []
    @Published var searchText: String = ""

    private let service: CategoriesService

    init(
        service: CategoriesService = .init(
            client: URLSessionNetworkClient()
        )
    ) {
        self.service = service
        Task { await loadCategories() }
    }

    private func loadCategories() async {
        do {
            allCategories = try await service.fetchAll()
        } catch {
            print()
        }
    }

    var filteredCategories: [Category] {
        guard !searchText.isEmpty else { return allCategories }

        let q = searchText.normalized

        let withDistance: [(Category, Int)] = allCategories.map { cat in
            let dist = cat.name.normalized.levenshteinDistance(to: q)
            return (cat, dist)
        }
        let threshold = max(2, q.count / 2)

        return withDistance
            .filter { _, dist in dist <= threshold }
            .sorted { $0.1 < $1.1 }
            .map { $0.0 }
    }
}
