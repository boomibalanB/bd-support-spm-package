import Foundation

struct TicketFormModel: Decodable {
    let orgBrandId: Int?
    let brandId: Int?
    let brandName: String?
    let formMappingDetails: [FormMappingDetail]
    let isDefault: Bool?
    let isDeactivated: Bool?
    let isCustomerPortalActive: Bool?
    let fieldOptionId: Int?
    let logoLink: String?
    let defaultTicketFormId: Int?
}

struct LookUpFieldConfiguration : Encodable {
    let conditions: String?
    let filter: String?
}
