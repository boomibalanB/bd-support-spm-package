import Foundation

struct BrandFormModel: Codable {
    let orgBrandId: Int?
    let brandId: Int?
    let brandName: String?
    let formMappingDetails: [FormMappingDetail]?
    let isDefault: Bool?
    let isDeactivated: Bool?
    let isCustomerPortalActive: Bool?
    let fieldOptionId: Int?
    let logoLink: String?
    let defaultTicketFormId: Int?

    enum CodingKeys: String, CodingKey {
        case orgBrandId, brandId, brandName, formMappingDetails, isDefault,
             isDeactivated, isCustomerPortalActive, fieldOptionId, logoLink, defaultTicketFormId
    }

    // Custom Decoder
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        orgBrandId = try container.decodeIfPresent(Int.self, forKey: .orgBrandId)
        brandId = try container.decodeIfPresent(Int.self, forKey: .brandId)
        brandName = try container.decodeIfPresent(String.self, forKey: .brandName)
        formMappingDetails = try container.decodeIfPresent([FormMappingDetail].self, forKey: .formMappingDetails)
        isDefault = try container.decodeIfPresent(Bool.self, forKey: .isDefault)
        isDeactivated = try container.decodeIfPresent(Bool.self, forKey: .isDeactivated)
        isCustomerPortalActive = try container.decodeIfPresent(Bool.self, forKey: .isCustomerPortalActive)
        fieldOptionId = try container.decodeIfPresent(Int.self, forKey: .fieldOptionId)
        logoLink = try container.decodeIfPresent(String.self, forKey: .logoLink)
        defaultTicketFormId = try container.decodeIfPresent(Int.self, forKey: .defaultTicketFormId)
    }

    // Custom Encoder — exclude formMappingDetails
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(orgBrandId, forKey: .orgBrandId)
        try container.encodeIfPresent(brandId, forKey: .brandId)
        try container.encodeIfPresent(brandName, forKey: .brandName)
        try container.encodeIfPresent(isDefault, forKey: .isDefault)
        try container.encodeIfPresent(isDeactivated, forKey: .isDeactivated)
        try container.encodeIfPresent(isCustomerPortalActive, forKey: .isCustomerPortalActive)
        try container.encodeIfPresent(fieldOptionId, forKey: .fieldOptionId)
        try container.encodeIfPresent(logoLink, forKey: .logoLink)
        try container.encodeIfPresent(defaultTicketFormId, forKey: .defaultTicketFormId)
    }
}

struct FormMappingDetail: Decodable {
    let formId: Int
    let isDefault: Bool?
    let isEnabled: Bool?
    let isEnabledForWidgetOrWebForm: Bool?
    let isVisibleInCustomerPortal: Bool?
    let labelForAgentPortal: String?
    let labelForCustomerPortal: String?
    let sortOrder: Int?
}
