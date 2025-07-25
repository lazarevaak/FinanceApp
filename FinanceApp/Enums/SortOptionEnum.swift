import Foundation

// MARK: — Sorts
enum SortOptionEnum: String, CaseIterable, Identifiable {
    case byDate, byAmount
    var id: String { rawValue }
}
