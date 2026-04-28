import Foundation

struct UserInfoResponse: Codable {
    let result: UserInfo
}

struct UserInfo: Codable {
    let name: String
    let displayName: String
    let email: String
    let userId: Int
    let phone: String?
    let timeZoneId: Int?
    let password: String?
    let currentPassword: String?
    let newPassword: String?
    let confirmPassword: String?
    let shortCode: String?
    let languageId: Int?
    let jobTitle: String?
    let address: String?
    let mobileNumber: String?
    let customFields: String?
    let countryId: Int?
}

extension UserInfo {
    static var current: UserInfo? {
        UserInfoManager.shared.userInfo
    }

    static var userId: Int? {
        UserInfoManager.shared.userInfo?.userId
    }

    static var name: String? {
        UserInfoManager.shared.userInfo?.name
    }

    static var displayName: String? {
        UserInfoManager.shared.userInfo?.displayName
    }

    static var email: String? {
        UserInfoManager.shared.userInfo?.email
    }
    
    static var phone: String? {
        UserInfoManager.shared.userInfo?.phone
    }
    
    static var timeZoneId: Int? {
        UserInfoManager.shared.userInfo?.userId
    }
}

final class UserInfoManager: ObservableObject {
    static let shared = UserInfoManager()
    @Published private(set) var userInfo: UserInfo?

    private init() {}

    func updateUserInfo(_ info: UserInfo) {
        self.userInfo = info
    }
}
