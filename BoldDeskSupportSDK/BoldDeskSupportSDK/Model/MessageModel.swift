import Foundation

// MARK: - MessageResponse
struct MessageResponse: Codable {
    let ticketUpdates: [Message]
    let totalListCount: Int
    let listCount: Int
}

// MARK: - Message Model
struct Message: Codable, Identifiable {
    let id: Int
    let description: String
    let hasAttachment: Bool
    let attachments: [Attachment]
    let createdOn: String
    let updatedOn: String
    let updatedBy: UserDetails
    let isOdd: Bool
    let updateFlagId: Int?

    var message: String { description }

    var identity: String { String(id) }
    
    var idString: String { String(id) }
    
    var isLastMessage: Bool = false

    enum CodingKeys: String, CodingKey {
        case id = "commentId"
        case description
        case hasAttachment
        case attachments
        case createdOn
        case updatedOn
        case updatedBy
        case isOdd
        case updateFlagId
    }
}
