import Foundation

struct TicketSearchResponse: Codable {
    let result: [TicketSearchModel]
    
    enum CodingKeys: String, CodingKey {
        case result = "searchResult"
    }
}

struct TicketSearchModel: Codable {
    let ticketId: Int
    let title: String
    let status: Status?
    let requestedBy: RequestedBy?
    let createdOn: String
    let formattedCreatedOn: String
}

struct Status: Codable {
    let id: Int
    let description: String
    let backgroundColor: String
    let textColor: String
}

struct RequestedBy: Codable {
    let name: String
    let displayName: String
    let userId: Int
}

extension TicketSearchModel {
    var safeStatus: Status {
        return status ?? Status(id: 2, description: "open", backgroundColor: "#0c2098", textColor: "#000000")
    }

    var safeRequestedBy: RequestedBy {
        return requestedBy ?? RequestedBy(name: "Soma Prasanna M", displayName: "Soma Prasanna Muthukumaran", userId: 11685)
    }
    
    var shortCode: String {
        let words = safeRequestedBy.displayName.split(separator: " ").map { String($0) }
        if words.isEmpty {
            return safeRequestedBy.displayName.prefix(2).uppercased()
        } else if words.count == 1 {
            return words[0].prefix(2).uppercased()
        } else {
            let firstLetters = words.prefix(2).map { $0.prefix(1).uppercased() }
            return firstLetters.joined()
        }
    }
}
