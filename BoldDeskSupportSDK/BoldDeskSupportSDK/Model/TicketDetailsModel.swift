import Foundation

// MARK: - Root Response
struct TicketDetailResponse: Codable {
    let ticketDetails: TicketDetailObject
}

// MARK: - Ticket Details
struct TicketDetailObject: Codable {
    let ticketId: Int
    var title: String
    let description: String
    let dataToken: String?
    let hasAttachment: Bool
    let attachments: [Attachment]
    let createdBy: UserDetails
    let updatedBy: UserDetails
    let requester: UserDetails
    let updatedOn: String
    let updateCount: Int
    let status: String
    let createdOn: String
    let closedOn: String?
    let needToDisplayContactGroupField: Bool
    let updateFlagId: Int?
    let commentId: Int
    let updatedByUserId: Int
    let isArchived: Bool
    let ticketStatusId: Int
    let ticketFormId: Int

    enum CodingKeys: String, CodingKey {
        case ticketId, title, description, dataToken, hasAttachment, attachments, createdBy,
             updatedBy, requester, updatedOn, updateCount, status, createdOn,
             closedOn, needToDisplayContactGroupField, updateFlagId, commentId,
             updatedByUserId, isArchived, ticketStatusId, ticketFormId
    }
}

// MARK: - UserDetails
struct UserDetails: Codable {
    let shortCode: String
    let colorCode: String
    let displayName: String
    let userId: Int
    let isAgent: Bool
    let email: String
    let profileImageUrl: String?
}
