import SwiftUI

struct FormFieldModel: Identifiable, Decodable, Equatable {
    let id: Int?
    let labelForCustomerPortal: String?
    let canEditInCustomerPortal: Bool?
    var isRequiredInCustomerPortal: Bool?
    let isVisibleInCustomerPortal: Bool?
    var isEnabled: Bool?
    let apiName: String?
    let isDefaultField: Bool?
    let noteMessage: String?
    let noteMessageDisplayBelowField: Bool?
    let fieldTypeId: Int?
    let fieldControlName: String?
    let fieldDataType: String?
    let isDeactivated: Bool?
    let fieldType: String?
    let urlPrefix: String?
    let sortOrder: Int?
    let regex: String?
    let defaultValue: String?
    let parentFieldId: Int?
    let displayCondition: DisplayCondition?
    var userCanEdit: Bool?
    let value: String?
    let cannotEditAfterCreateCustomerPortal: Bool?
    let hideInCreateFormCustomerPortal: Bool?
    let targetModuleId: Int?
    let lookUpFieldConfiguration: String?
    let additionalFieldValidation: AdditionalFieldValidation?
    let placeholderForAgentPortal: String?
    let placeholderForCustomerPortal: String?
    let customErrorMessage: String?
    var multiLineText: String?
    var isChecked: Bool?
    var selectedDate: String?
    var selectedDateTime : String?
    var text : String?
    var selectedItem: DropdownItemModel?
    var selectedItems: [DropdownItemModel]?
    var isValid: Bool? = true
    var isVisible: Bool? = true
    var dropdownItems: [DropdownItemModel]?
    var isItemsDisplayedBasedOnFieldDependency: Bool = false
    var errorMessage: String? = nil
        

    enum CodingKeys: String, CodingKey {
            case id = "fieldId"
            case labelForCustomerPortal, canEditInCustomerPortal, isRequiredInCustomerPortal, isEnabled,
                 isVisibleInCustomerPortal, apiName, isDefaultField, noteMessage,
                 noteMessageDisplayBelowField, fieldTypeId, fieldControlName, fieldDataType,
                 isDeactivated, fieldType, urlPrefix, sortOrder, regex, defaultValue,
                 parentFieldId, userCanEdit, value, cannotEditAfterCreateCustomerPortal,
                 hideInCreateFormCustomerPortal, targetModuleId, lookUpFieldConfiguration,
                 placeholderForAgentPortal, placeholderForCustomerPortal, customErrorMessage,
                 additionalFieldValidation, displayCondition
        }

        // Custom decoder to handle JSON string for displayCondition and dictionary string for additionalFieldValidation
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id = try container.decodeIfPresent(Int.self, forKey: .id)
        labelForCustomerPortal = try container.decodeIfPresent(String.self, forKey: .labelForCustomerPortal)
        canEditInCustomerPortal = try container.decodeIfPresent(Bool.self, forKey: .canEditInCustomerPortal)
        isRequiredInCustomerPortal = try container.decodeIfPresent(Bool.self, forKey: .isRequiredInCustomerPortal)
        isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled)
        isVisibleInCustomerPortal = try container.decodeIfPresent(Bool.self, forKey: .isVisibleInCustomerPortal)
        apiName = try container.decodeIfPresent(String.self, forKey: .apiName)
        isDefaultField = try container.decodeIfPresent(Bool.self, forKey: .isDefaultField)
        noteMessage = try container.decodeIfPresent(String.self, forKey: .noteMessage)
        noteMessageDisplayBelowField = try container.decodeIfPresent(Bool.self, forKey: .noteMessageDisplayBelowField)
        fieldTypeId = try container.decodeIfPresent(Int.self, forKey: .fieldTypeId)
        fieldControlName = try container.decodeIfPresent(String.self, forKey: .fieldControlName)
        fieldDataType = try container.decodeIfPresent(String.self, forKey: .fieldDataType)
        isDeactivated = try container.decodeIfPresent(Bool.self, forKey: .isDeactivated)
        fieldType = try container.decodeIfPresent(String.self, forKey: .fieldType)
        urlPrefix = try container.decodeIfPresent(String.self, forKey: .urlPrefix)
        sortOrder = try container.decodeIfPresent(Int.self, forKey: .sortOrder)
        regex = try container.decodeIfPresent(String.self, forKey: .regex)
        defaultValue = try container.decodeIfPresent(String.self, forKey: .defaultValue)
        parentFieldId = try container.decodeIfPresent(Int.self, forKey: .parentFieldId)
        
        // 👇 Parse `displayCondition` string into DisplayCondition object
        if let jsonString = try container.decodeIfPresent(String.self, forKey: .displayCondition),
           let jsonData = jsonString.data(using: .utf8) {
            let decodedCondition: DisplayCondition? = try? JSONDecoder().decode(DisplayCondition.self, from: jsonData)
            displayCondition = decodedCondition
        } else {
            displayCondition = nil
        }
        userCanEdit = try container.decodeIfPresent(Bool.self, forKey: .userCanEdit)
        value = try container.decodeIfPresent(String.self, forKey: .value)
        cannotEditAfterCreateCustomerPortal = try container.decodeIfPresent(Bool.self, forKey: .cannotEditAfterCreateCustomerPortal)
        hideInCreateFormCustomerPortal = try container.decodeIfPresent(Bool.self, forKey: .hideInCreateFormCustomerPortal)
        targetModuleId = try container.decodeIfPresent(Int.self, forKey: .targetModuleId)
        lookUpFieldConfiguration = try container.decodeIfPresent(String.self, forKey: .lookUpFieldConfiguration)
        if let jsonString = try container.decodeIfPresent(String.self, forKey: .additionalFieldValidation),
                                     let jsonData = jsonString.data(using: .utf8) {
                                      let decodedCondition: AdditionalFieldValidation? = try? JSONDecoder().decode(AdditionalFieldValidation.self, from: jsonData)
                                        additionalFieldValidation = decodedCondition
                                  } else {
                                      additionalFieldValidation = nil
                                  }
        placeholderForAgentPortal = try container.decodeIfPresent(String.self, forKey: .placeholderForAgentPortal)
        placeholderForCustomerPortal = try container.decodeIfPresent(String.self, forKey: .placeholderForCustomerPortal)
        customErrorMessage = try container.decodeIfPresent(String.self, forKey: .customErrorMessage)

        // Optional local state fields
        multiLineText = nil
        isChecked = false
        selectedDate = nil
        selectedDateTime = nil
        text = nil
        selectedItem = nil
        selectedItems = nil
        isValid = true
        isVisible = true
        dropdownItems = []
        isItemsDisplayedBasedOnFieldDependency = false
        errorMessage = nil
    }
}

// MARK: - DisplayCondition
struct DisplayCondition: Codable, Equatable {
    let condition: String?
    let rules: [Rule]
}

// MARK: - Rule
struct Rule: Codable, Equatable {
    let type: String?
    let field: String?
    let value: [String]
    let `operator`: String?
}

extension FormFieldModel {
    init(
        id: Int?,
        labelForCustomerPortal: String?,
        canEditInCustomerPortal: Bool? = true,
        isRequiredInCustomerPortal: Bool?,
        isEnabled: Bool? = false,
        isVisibleInCustomerPortal: Bool? = true,
        apiName: String? = nil,
        isDefaultField: Bool? = nil,
        noteMessage: String? = nil,
        noteMessageDisplayBelowField: Bool? = nil,
        fieldTypeId: Int? = nil,
        fieldControlName: String?,
        fieldDataType: String? = nil,
        isDeactivated: Bool? = false,
        fieldType: String? = nil,
        urlPrefix: String? = nil,
        sortOrder: Int? = nil,
        regex: String? = nil,
        defaultValue: String? = nil,
        parentFieldId: Int? = nil,
        displayCondition: DisplayCondition? = nil,
        userCanEdit: Bool? = true,
        value: String? = nil,
        cannotEditAfterCreateCustomerPortal: Bool? = nil,
        hideInCreateFormCustomerPortal: Bool? = nil,
        targetModuleId: Int? = nil,
        lookUpFieldConfiguration: String? = nil,
        additionalFieldValidation: AdditionalFieldValidation? = nil,
        placeholderForAgentPortal: String? = nil,
        placeholderForCustomerPortal: String? = nil,
        customErrorMessage: String? = nil,
        multiLineText: String? = nil,
        isChecked: Bool? = false,
        selectedDate: String? = nil,
        selectedDateTime: String? = nil,
        text: String? = nil,
        selectedItem: DropdownItemModel? = nil,
        selectedItems: [DropdownItemModel]? = nil,
        isValid: Bool? = true,
        isVisible: Bool? = true,
        dropdownItems : [DropdownItemModel]? = nil
    ) {
        self.id = id
        self.labelForCustomerPortal = labelForCustomerPortal
        self.canEditInCustomerPortal = canEditInCustomerPortal
        self.isRequiredInCustomerPortal = isRequiredInCustomerPortal
        self.isEnabled = isEnabled
        self.isVisibleInCustomerPortal = isVisibleInCustomerPortal
        self.apiName = apiName
        self.isDefaultField = isDefaultField
        self.noteMessage = noteMessage
        self.noteMessageDisplayBelowField = noteMessageDisplayBelowField
        self.fieldTypeId = fieldTypeId
        self.fieldControlName = fieldControlName
        self.fieldDataType = fieldDataType
        self.isDeactivated = isDeactivated
        self.fieldType = fieldType
        self.urlPrefix = urlPrefix
        self.sortOrder = sortOrder
        self.regex = regex
        self.defaultValue = defaultValue
        self.parentFieldId = parentFieldId
        self.displayCondition = displayCondition
        self.userCanEdit = userCanEdit
        self.value = value
        self.cannotEditAfterCreateCustomerPortal = cannotEditAfterCreateCustomerPortal
        self.hideInCreateFormCustomerPortal = hideInCreateFormCustomerPortal
        self.targetModuleId = targetModuleId
        self.lookUpFieldConfiguration = lookUpFieldConfiguration
        self.additionalFieldValidation = additionalFieldValidation
        self.placeholderForAgentPortal = placeholderForAgentPortal
        self.placeholderForCustomerPortal = placeholderForCustomerPortal
        self.customErrorMessage = customErrorMessage
        self.multiLineText = multiLineText
        self.isChecked = isChecked
        self.selectedDate = selectedDate
        self.selectedDateTime = selectedDateTime
        self.text = text
        self.selectedItem = selectedItem
        self.selectedItems = selectedItems
        self.isValid = isValid
        self.isVisible = isVisible
        self.dropdownItems = dropdownItems
    }
}

struct AdditionalFieldValidation: Codable, Equatable {
    let maxValue: Double?
    let minValue: Double?
    let hideActionIcon: Bool?
    let numberingFormatTypeId: Int?
}
