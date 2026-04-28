import Foundation

struct GeneralSettingResponse: Codable {
    let result: GeneralSettingResult
}

struct GeneralSettingResult: Codable {
    let knowledgeBase: KnowledgeBase
    let contactUs: ContactUs
    let generalSettings: GeneralSettings
}

struct KnowledgeBase: Codable {
    let isEnabled: Bool
    let categoryIds: [Int]?
    let categoryDetails: [CategoryDetail]?
    let visiblityOptionId: Int64?

    enum CodingKeys: String, CodingKey {
        case isEnabled = "isKBEnabled"
        case categoryIds
        case categoryDetails
        case visiblityOptionId
    }
}

struct CategoryDetail: Codable {
    let id: Int
    let name: String
}

extension KnowledgeBase {
    static var current: KnowledgeBase? {
        AppSettingsManager.shared.knowledgeBase
    }

    static var isEnabled: Bool {
        AppSettingsManager.shared.knowledgeBase?.isEnabled ?? false
    }
    
    static var visiblityOptionId: Int64 {
        AppSettingsManager.shared.knowledgeBase?.visiblityOptionId ?? 0
    }
}

struct ContactUs: Codable {
    let isEnabled: Bool
    let isSimpleContactForm: Bool
}

extension ContactUs {
    static var current: ContactUs? {
        AppSettingsManager.shared.contactUs
    }

    static var isEnabled: Bool {
        AppSettingsManager.shared.contactUs?.isEnabled ?? false
    }

    static var isSimpleContactForm: Bool {
        AppSettingsManager.shared.contactUs?.isSimpleContactForm ?? false
    }
}

struct GeneralSettings: Codable {
    let allowedFileExtensions: String
    let includePoweredBy: Bool
    let uploadFileSize: Int
    let isMultiLanguageEnabled: Bool
    let customerPortalEnabledLanguages: String
    let allowUnauthenticatedUserToCreateTicket: Bool
    let restrictCcUsersFromUpdatingTicket: Bool
    let restrictClosingTicketViaCustomerPortal: Bool
    let restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal: Bool
    let dateFormatId: Int
    let ianaTimeZoneName: String
    let timeFormatId: Int
    let timeFormat: String
    let timeZoneId: Int
    let timeZoneName: String
    let timeZoneOffset: String
    let timeZoneShortCode: String
    let utcTimeZoneName: String
    let closedTicketStatusConfig: ClosedTicketStatusConfig
    let isMultipleTicketFormEnabled: Bool?
    let isMyOrganizationViewDisabledInCustomerPortal: Bool?
    let ccConfiguration: CCConfiguration?
}

extension GeneralSettings {
    static var current: GeneralSettings? {
        AppSettingsManager.shared.settings
    }
    
    static var uploadFileSize: Int {
        AppSettingsManager.shared.settings?.uploadFileSize ?? 0
    }

    static var restrictClosingTicketViaCustomerPortal: Bool {
        AppSettingsManager.shared.settings?.restrictClosingTicketViaCustomerPortal ?? false
    }

    static var restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal: Bool {
        AppSettingsManager.shared.settings?.restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal ?? false
    }

    static var allowUnauthenticatedUserToCreateTicket: Bool {
        AppSettingsManager.shared.settings?.allowUnauthenticatedUserToCreateTicket ?? false
    }
    
    static var restrictActionsOnClosedTickets: Bool {
        return (AppSettingsManager.shared.settings?.closedTicketStatusConfig.needToCreateFollowUpTicketOnEndUserReply ?? false) == true
    }
    
    static var closedTicketStatusConfig : ClosedTicketStatusConfig? {
        return AppSettingsManager.shared.settings?.closedTicketStatusConfig
    }
    
    static var includePoweredBy : Bool {
        return AppSettingsManager.shared.settings?.includePoweredBy ?? false
    }
    
    static var isMultipleTicketFormEnabled: Bool {
        AppSettingsManager.shared.settings?.isMultipleTicketFormEnabled ?? false
    }
    
    static var dateFormatId: Int {
        AppSettingsManager.shared.settings?.dateFormatId ?? 5
    }
    
    static var ianaTimeZoneName: String {
        AppSettingsManager.shared.settings?.ianaTimeZoneName ?? "UTC"
    }
    
    static var timeFormatId: Int {
        AppSettingsManager.shared.settings?.timeFormatId ?? 2
    }
    
    static var timeZoneId: Int {
        AppSettingsManager.shared.settings?.timeZoneId ?? 0
    }
    
    static var timeZoneName: String {
        AppSettingsManager.shared.settings?.timeZoneName ?? "UTC"
    }

    static var utcTimeZoneName: String {
        AppSettingsManager.shared.settings?.utcTimeZoneName ?? "UTC"
    }
    
    static var isMyOrganizationViewDisabledInCustomerPortal: Bool {
        AppSettingsManager.shared.settings?.isMyOrganizationViewDisabledInCustomerPortal ?? false
    }
    
    static var restrictCcUsersFromUpdatingTicket : Bool {
        return AppSettingsManager.shared.settings?.restrictCcUsersFromUpdatingTicket ?? false
    }
    
    static var ccConfiguration: CCConfiguration? {
        AppSettingsManager.shared.settings?.ccConfiguration
    }
}


struct ClosedTicketStatusConfig: Codable {
    let fallbackStatusId: Int
    let needToCreateFollowUpTicketOnEndUserReply: Bool
}

final class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()
    
    @Published private(set) var settings: GeneralSettings?
    @Published private(set) var knowledgeBase: KnowledgeBase?
    @Published private(set) var contactUs: ContactUs?
    
    private init() {}
    
    func updateSettings(
        general: GeneralSettings,
        knowledgeBase: KnowledgeBase,
        contactUs: ContactUs
    ) {
        self.settings = general
        self.knowledgeBase = knowledgeBase
        self.contactUs = contactUs
    }
    
    func updateGeneralSettings(_ newSettings: GeneralSettings) {
        self.settings = newSettings
    }
    
    func updateKnowledgeBase(_ newSettings: KnowledgeBase) {
        self.knowledgeBase = newSettings
    }
    
    func updateContactUs(_ newSettings: ContactUs) {
        self.contactUs = newSettings
    }
}

struct CCConfiguration: Codable {
    let allowContactCreationFromEmail: Bool
    let isCCEnabledInCustomerPortal: Bool
    let isCCEnabledinEmail: Bool
    let allowContactCreationFromCustomerPortal: Bool
    let isCcEnabled: Bool
}
