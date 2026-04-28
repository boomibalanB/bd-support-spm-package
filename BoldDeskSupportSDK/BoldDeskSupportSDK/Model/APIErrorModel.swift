struct APIErrorDetail: Codable {
    var field: String
    var errorMessage: String
    var errorType: String
}

struct APIErrorResponse: Codable {
    var errors: [APIErrorDetail]
    var message: String
    var statusCode: Int
}

