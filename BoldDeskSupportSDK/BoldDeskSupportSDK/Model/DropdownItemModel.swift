import SwiftUI

struct DropdownItemModel: Identifiable, Hashable, Decodable, Equatable {
    var id: Int
    var name: String?
    var itemName: String
    var fieldOptionId: Int?
    var itemColorCode: String
    var itemShortCode: String
    var displayName: String
    var subtitle: String
    var userId: Int?
    var description: String
    var iconData: String?
    var statusColorCode: String
    var isNewItem: Bool
    var isAgent: Bool
    var skipEmailNotification: Bool?
    var isPrimary: Bool
    var accessScopeId: Int
    var isBlocked: Bool
    var isDeleted: Bool
    var isVerified: Bool
    var localizationName: String
    var subtitleLocalizationName: String
    var profileImageUrl: String?
    var isDefault: Bool
    var statusCategoryId: Int?
    var isFavorite: Bool
    var stringId: String?
    var isSelected: Bool = false
    
    // Custom initializer remains unchanged
    init(
        id: Int,
        itemName: String,
        fieldOptionId: Int? = nil,
        itemColorCode: String = "",
        itemShortCode: String = "",
        displayName: String = "",
        subtitle: String = "",
        userId: Int? = nil,
        description: String = "",
        iconData: String? = nil,
        statusColorCode: String = "",
        isNewItem: Bool = false,
        isAgent: Bool = false,
        skipEmailNotification: Bool? = nil,
        isPrimary: Bool = false,
        accessScopeId: Int = 1,
        isBlocked: Bool = false,
        isDeleted: Bool = false,
        isVerified: Bool = false,
        localizationName: String = "",
        subtitleLocalizationName: String = "",
        profileImageUrl: String? = nil,
        isDefault: Bool = false,
        statusCategoryId: Int? = nil,
        isFavorite: Bool = false,
        stringId: String? = nil,
        isSelected: Bool = false
    ) {
        self.id = id
        self.itemName = itemName
        self.fieldOptionId = fieldOptionId
        self.itemColorCode = itemColorCode
        self.itemShortCode = itemShortCode
        self.displayName = displayName
        self.subtitle = subtitle
        self.userId = userId
        self.description = description
        self.iconData = iconData
        self.statusColorCode = statusColorCode
        self.isNewItem = isNewItem
        self.isAgent = isAgent
        self.skipEmailNotification = skipEmailNotification
        self.isPrimary = isPrimary
        self.accessScopeId = accessScopeId
        self.isBlocked = isBlocked
        self.isDeleted = isDeleted
        self.isVerified = isVerified
        self.localizationName = localizationName
        self.subtitleLocalizationName = subtitleLocalizationName
        self.profileImageUrl = profileImageUrl
        self.isDefault = isDefault
        self.statusCategoryId = statusCategoryId
        self.isFavorite = isFavorite
        self.stringId = stringId
        self.isSelected = isSelected
    }
}
