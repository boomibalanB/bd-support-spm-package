public struct OfflineSettings: Codable {
    public var formIds: [Int]?
    public var brandOptionId: Int?
    public var offlineMessage: String?
    public var fileUploadOption: Int?
    public var submitButtonText: String?
    public var headerDescription: String?
    public var offlineSupportMode: Int?
    public var confirmationMessage: String?
    public var createTicketButtonText: String?

    public init(
        formIds: [Int]? = nil,
        brandOptionId: Int? = nil,
        offlineMessage: String? = nil,
        fileUploadOption: Int? = nil,
        submitButtonText: String? = nil,
        headerDescription: String? = nil,
        offlineSupportMode: Int? = nil,
        confirmationMessage: String? = nil,
        createTicketButtonText: String? = nil
    ) {
        self.formIds = formIds
        self.brandOptionId = brandOptionId
        self.offlineMessage = offlineMessage
        self.fileUploadOption = fileUploadOption
        self.submitButtonText = submitButtonText
        self.headerDescription = headerDescription
        self.offlineSupportMode = offlineSupportMode
        self.confirmationMessage = confirmationMessage
        self.createTicketButtonText = createTicketButtonText
    }
}

public struct GeneralSettingsForChat: Codable {
    public var allowedFileExtensions: String?
    public var includePoweredBy: Bool?
    public var uploadFileSize: Int?
    public var isMultiLanguageEnabled: Bool?

    public init(
        allowedFileExtensions: String? = nil,
        includePoweredBy: Bool? = false,
        uploadFileSize: Int? = nil,
        isMultiLanguageEnabled: Bool? = false
    ) {
        self.allowedFileExtensions = allowedFileExtensions
        self.includePoweredBy = includePoweredBy
        self.uploadFileSize = uploadFileSize
        self.isMultiLanguageEnabled = isMultiLanguageEnabled
    }
}

public class ChatConfiguration {

    public var isFromChatSDK: Bool
    public var appKey: String
    public var brandURL: String
    public var email: String?
    public var name: String?
    public var phoneNo: String?
    public var offlineSettings: OfflineSettings?
    public var generalSettings: GeneralSettingsForChat?

    public init(
        isFromChatSDK: Bool,
        appKey: String,
        brandURL: String,
        email: String? = nil,
        name: String? = nil,
        phoneNo: String? = nil,
        offlineSettings: OfflineSettings? = nil,
        generalSettings: GeneralSettingsForChat? = nil
    ) {
        self.isFromChatSDK = isFromChatSDK
        self.appKey = appKey
        self.brandURL = brandURL
        self.email = email
        self.name = name
        self.phoneNo = phoneNo
        self.offlineSettings = offlineSettings
        self.generalSettings = generalSettings
    }
}
