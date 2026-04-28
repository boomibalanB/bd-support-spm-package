import SwiftUI

struct DynamicDropdownModel: Identifiable, Codable {
    let id: Int?
    let name: String?
    let email: String?
    let isReadOnly: Bool?
    let isPrivate: Bool?
    let sortOrder: Int?
    let isSystemDefault: Bool?
}

struct PriorityModel: Identifiable, Decodable {
    let id: Int?
    let name: String?
}
