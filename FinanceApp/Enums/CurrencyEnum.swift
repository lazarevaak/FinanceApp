import UIKit

// MARK: — Модель валют
enum Currency: String, CaseIterable, Identifiable {
    case ruble  = "RUB"
    case dollar = "USD"
    case euro   = "EUR"

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .ruble:  return "₽"
        case .dollar: return "$"
        case .euro:   return "€"
        }
    }

    var displayName: String {
        switch self {
        case .ruble:  return "Российский рубль ₽"
        case .dollar: return "Американский доллар $"
        case .euro:   return "Евро €"
        }
    }
}
