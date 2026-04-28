import Foundation

struct ExceptionMessage: Codable {
    var type: String?
    var title: String?
    var status: Int?
    var detail: String?
    var instance: String?
    var errors: [ErrorDetail]?
    var message: String?
    var statusCode: Int?
    var result: ResultDetail?

    enum CodingKeys: String, CodingKey {
        case type, title, status, detail, instance, errors, message, statusCode, result
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        type = try container.decodeIfPresent(String.self, forKey: .type)
        title = try container.decodeIfPresent(String.self, forKey: .title)
        status = try container.decodeIfPresent(Int.self, forKey: .status)
        detail = try container.decodeIfPresent(String.self, forKey: .detail)
        instance = try container.decodeIfPresent(String.self, forKey: .instance)
        message = try container.decodeIfPresent(String.self, forKey: .message)
        statusCode = try container.decodeIfPresent(Int.self, forKey: .statusCode)
        errors = try container.decodeIfPresent([ErrorDetail].self, forKey: .errors)

        // Decode result from array if possible
        if let resultArray = try? container.decodeIfPresent([ResultDetail].self, forKey: .result),
           let firstResult = resultArray.first {
            result = firstResult
        }
    }
}

struct ErrorDetail: Codable {
    var field: String?
    var errorMessage: String?
    var errorType: String?
}

struct ResultDetail: Codable {
    var id: Int?
    var isSuccess: Bool?
    var reason: String?
}
