import Foundation

// MARK: - Status Response Model
struct StatusResponse: Codable {
    let result: [TicketFilterStatus]
    let count: Int?
}

// MARK: - Original Status Model (for API response)
struct TicketFilterStatus: Codable, Identifiable, Hashable {
    let id: String
    let value: String
    let text: String
    
    var intId: Int {
        return Int(id) ?? 0
    }
    
    // Convert to DropdownItemModel
    func toDropdownItem() -> DropdownItemModel {
        return DropdownItemModel(
            id: self.intId,
            itemName: self.text,
            displayName: self.text,
            stringId: self.value
        )
    }
}
