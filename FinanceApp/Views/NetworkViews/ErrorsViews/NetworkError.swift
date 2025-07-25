import Foundation

// MARK: - Ошибки сети
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String)
    case decodingError
    case encodingError
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Некорректный URL запроса."
        case .invalidResponse:
            return "Некорректный ответ сервера."
        case .httpError(let code, let message):
            return "Ошибка HTTP \(code): \(message)"
        case .decodingError:
            return "Не удалось разобрать ответ сервера."
        case .encodingError:
            return "Не удалось сформировать тело запроса."
        case .unknown(let error):
            return "Неизвестная ошибка: \(error.localizedDescription)"
        }
    }
}

