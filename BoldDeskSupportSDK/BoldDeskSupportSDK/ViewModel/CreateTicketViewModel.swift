import Foundation
import SwiftUI

@MainActor
class CreateTicketViewModel: ObservableObject {
    var ticketFormBl = TicketFormBL()
    @Published var formFieldModel: [FormFieldModel] = []
    @Published var ticketFormModel: TicketFormModel?
    @Published var isLoading: Bool = false
    @Published var isShowProgress: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isShowTicketLink: Bool = false
    @Published var ccFieldvalues: [String] = []
    var pickedItem: [PickedMediaInfo] = []
    var fieldDependencies: [FieldDependencies] = []
    var dropdownItems: [DropdownItemModel] = []
    var radioOption: [String] = ["Yes", "No"]
    var validation = Validation()
    var defaultTicketFormId: String? = nil
    var isMultiformEnabled: Bool = false
    var isShowFormField: Bool = false
    var ticketId: String = ""
    var ticketLink: String = ""
    private var appInfoVM = AppInfoViewModel()
    
    private let isDisabled: Bool
    
    init(isDisabled: Bool = false) {
        self.isDisabled = isDisabled
        loadBasedOnSettingsAndCreateForm()
    }
    
    func loadBasedOnSettingsAndCreateForm() {
        isLoading = true
        guard !isDisabled else { return }
        
        Task {
            isMultiformEnabled = GeneralSettings.isMultipleTicketFormEnabled
            isLoading = true
            if BDSupportSDK.isFromChatSDK {
                let formId = BDSupportSDK.chatData?.offlineSettings?.formIds?[0]
                defaultTicketFormId = formId != nil ? String(formId!) : nil
                if BDSupportSDK.chatData?.offlineSettings?.offlineSupportMode == 3 {
                    await getFieldsAndApplyCondition(ticketId: defaultTicketFormId)
                }
                else{
                    formFieldModel = anonymousSimpleFormList()
                }
            }
            else if !ContactUs.isSimpleContactForm {
                if isMultiformEnabled {
                    _ = await getBrandFormDependency(searchText: "")
                }
                await getFieldsAndApplyCondition(ticketId: defaultTicketFormId)
            } else {
                if AppConstant.authToken.isEmpty {
                    formFieldModel = anonymousSimpleFormList()
                } else {
                    formFieldModel = defaultFieldForms()
                }
            }
            isLoading = false
        }
    }
    
    //update methods
    func updatedEnteredText(index: Int, text: String) {
        formFieldModel[index].text = text
        print(formFieldModel[index].text ?? "")
        adjustEmailPhoneRequirement()
    }
    
    func updateSelectedDate(index: Int, date: String?) {
        formFieldModel[index].selectedDate = date
        print(formFieldModel[index].selectedDate ?? "")
    }
    
    // Toggle email/phone isRequired flags based on current inputs
    func adjustEmailPhoneRequirement() {
        guard !formFieldModel.isEmpty else { return }
        
        let emailIndex = formFieldModel.firstIndex(where: { $0.apiName == (BDSupportSDK.isFromChatSDK ? "emailId" : "EmailAddress") })
        let phoneIndex = formFieldModel.firstIndex(where: { $0.apiName == "PhoneNumber" })
        
        guard let eIdx = emailIndex, let pIdx = phoneIndex else { return }
        
        let emailText = formFieldModel[eIdx].text ?? ""
        let phoneText = formFieldModel[pIdx].text ?? ""
        
        let emailValid = !emailText.isEmpty && validation.isValidEmail(emailText)
        let phoneValid = !phoneText.isEmpty && PhoneNumberValidator.shared.isValid(phoneText)
        let requiredMsg = ResourceManager.localized("requiredErrorMessage", comment: "")
        
        // If email is valid -> phone becomes optional
        if emailValid {
            formFieldModel[eIdx].isRequiredInCustomerPortal = true
            formFieldModel[pIdx].isRequiredInCustomerPortal = false
            // clear phone's required error only if it was the required error
            if formFieldModel[pIdx].errorMessage == requiredMsg {
                formFieldModel[pIdx].isValid = true
                formFieldModel[pIdx].errorMessage = ""
            }
            return
        }
        
        // If phone is valid AND email is empty OR invalid -> email becomes optional
        if phoneValid && (emailText.isEmpty || !emailValid) {
            formFieldModel[pIdx].isRequiredInCustomerPortal = true
            formFieldModel[eIdx].isRequiredInCustomerPortal = false
            // clear email's required error only if it was the required error
            if formFieldModel[eIdx].errorMessage == requiredMsg {
                formFieldModel[eIdx].isValid = true
                formFieldModel[eIdx].errorMessage = ""
            }
            return
        }
        
        // Neither valid (or other cases): keep both required
        formFieldModel[eIdx].isRequiredInCustomerPortal = true
        formFieldModel[pIdx].isRequiredInCustomerPortal = true
    }
    func updateSelectedDateTime(index: Int, dateTime: String?) {
        formFieldModel[index].selectedDateTime = dateTime
        print(formFieldModel[index].selectedDateTime ?? "")
    }
    func updateRadioCheckBox(index: Int, isChecked: Bool) {
        formFieldModel[index].isChecked = !isChecked
        applyDisplayConditionsBasedOnSelectedField(
            selectedFormField: formFieldModel[index]
        )
    }
    
    func updateSelectedItem(index: Int, selectedItem: DropdownItemModel?) {
        formFieldModel[index].selectedItem = selectedItem
        if formFieldModel[index].apiName == "brand_form_dependency" {
            defaultTicketFormId =
            selectedItem != nil ? String(selectedItem!.id) : nil
            Task {
                ccFieldvalues = []
                isLoading = true
                await getFieldsAndApplyCondition(ticketId: defaultTicketFormId)
                isLoading = false
                
            }
        } else {
            applyDisplayConditionsBasedOnSelectedField(
                selectedFormField: formFieldModel[index]
            )
        }
    }
    
    func updateSelectedItems(index: Int, selectedItems: [DropdownItemModel]) {
        formFieldModel[index].selectedItems = selectedItems
        applyDisplayConditionsBasedOnSelectedField(
            selectedFormField: formFieldModel[index]
        )
    }
    
    func updateCCFieldItems(index: Int, selectedItems: [String]) {
        // Normalize, trim and deduplicate (case-insensitive) while preserving order
        var seen: Set<String> = []
        let normalized: [String] = selectedItems.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .compactMap { item in
                let key = item.lowercased()
                guard !seen.contains(key) else { return nil }
                seen.insert(key)
                return item
            }
        ccFieldvalues = normalized
        let combinedString = normalized.joined(separator: "; ")
        formFieldModel[index].text = combinedString
    }
    
    //Validation Methods
    func dateTimeValidation(index: Int, date: String?) -> Bool {
        if formFieldModel[index].fieldControlName == FormFieldType.date.value
            || formFieldModel[index].fieldControlName
            == FormFieldType.datetime.value
        {
            if (date == nil || date!.isEmpty)
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        }
        return true
    }
    
    func checkBoxValidation(index: Int, isChecked: Bool) -> Bool {
        if (formFieldModel[index].fieldControlName
            == FormFieldType.checkBox.value
            || formFieldModel[index].fieldControlName
            == FormFieldType.radioButton.value)
            && formFieldModel[index].isRequiredInCustomerPortal ?? false
        {
            if !isChecked {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        }
        return true
    }
    
    func singleSelectValidation(index: Int, selectedItems: DropdownItemModel?)
    -> Bool
    {
        if formFieldModel[index].fieldControlName
            == FormFieldType.dropdown.value
            || formFieldModel[index].fieldControlName
            == FormFieldType.lookup.value
        {
            if selectedItems == nil
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        }
        return true
    }
    
    func multiSelectValidation(index: Int, selectedItems: [DropdownItemModel])
    -> Bool
    {
        if formFieldModel[index].fieldControlName
            == FormFieldType.multiselect.value
        {
            if selectedItems.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        }
        return true
    }
    
    func ccFieldvalidation(index: Int, selectedItems: [String])
    -> Bool
    {
        if formFieldModel[index].apiName == "cc" {
            if selectedItems.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else if selectedItems.allSatisfy({ validation.isValidEmail($0) })
            {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
                
            } else {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "emailNotValidText",
                    comment: ""
                )
                return false
            }
        }
        return true
    }
    
    func textFieldValidation(index: Int, text: String) -> Bool {
        if formFieldModel[index].fieldControlName == FormFieldType.url.value {
            if text.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else if !validation.isValidURL(text) && !text.isEmpty {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage =
                formFieldModel[index].customErrorMessage != ""
                && formFieldModel[index].customErrorMessage != nil
                ? formFieldModel[index].customErrorMessage!
                : ResourceManager.localized(
                    "formatErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        } else if formFieldModel[index].fieldControlName
                    == FormFieldType.regex.value
        {
            if text.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else if !validation.regexValidate(
                text: text,
                pattern: formFieldModel[index].regex ?? ""
            ) && !text.isEmpty {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage =
                formFieldModel[index].customErrorMessage != ""
                && formFieldModel[index].customErrorMessage != nil
                ? formFieldModel[index].customErrorMessage!
                : ResourceManager.localized(
                    "formatErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        } else if formFieldModel[index].apiName == "PhoneNumber" {
            if text.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
                
            } else if text.isEmpty && !(formFieldModel[index].isRequiredInCustomerPortal ?? false) {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            } else if !PhoneNumberValidator.shared.isValid(text) && !text.isEmpty {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "phoneNotValidText",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        } else if formFieldModel[index].fieldControlName
                    == FormFieldType.singleLineTextBox.value
                    || formFieldModel[index].fieldControlName
                    == FormFieldType.multiLineTextBox.value
        {
            
            if text.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        } else if formFieldModel[index].fieldControlName
                    == FormFieldType.numeric.value
                    || formFieldModel[index].fieldControlName
                    == FormFieldType.decimal.value
        {
            if text.isEmpty
                && (formFieldModel[index].isRequiredInCustomerPortal ?? false)
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else if let validation = formFieldModel[index]
                .additionalFieldValidation,
                      let inputValue = Double(text)
            {
                
                // Separate checks only if min/max exist
                if let min = validation.minValue, inputValue < min {
                    formFieldModel[index].isValid = false
                    formFieldModel[index].errorMessage =
                    formFieldModel[index].customErrorMessage != nil
                    ? formFieldModel[index].customErrorMessage
                    : String(
                        format: ResourceManager.localized(
                            "outOfRangeError",
                            comment: ""
                        )
                    )
                    return false
                } else if let max = validation.maxValue, inputValue > max {
                    formFieldModel[index].isValid = false
                    formFieldModel[index].errorMessage =
                    formFieldModel[index].customErrorMessage != nil
                    ? formFieldModel[index].customErrorMessage
                    : String(
                        format: ResourceManager.localized(
                            "outOfRangeError",
                            comment: ""
                        )
                    )
                    return false
                } else {
                    formFieldModel[index].isValid = true
                    formFieldModel[index].errorMessage = ""
                }
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        } else if formFieldModel[index].fieldControlName
                    == FormFieldType.email.value
                    || formFieldModel[index].apiName == "cc"
        {
            if text.isEmpty
                && formFieldModel[index].isRequiredInCustomerPortal ?? false
            {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "requiredErrorMessage",
                    comment: ""
                )
                return false
            } else if !text.isEmpty && !validation.isValidEmail(text) {
                formFieldModel[index].isValid = false
                formFieldModel[index].errorMessage = ResourceManager.localized(
                    "emailNotValidText",
                    comment: ""
                )
                return false
            } else {
                formFieldModel[index].isValid = true
                formFieldModel[index].errorMessage = ""
            }
        }
        return true
    }
    
    //Dynamic dropdown API
    func getFieldsAndApplyCondition(ticketId: String?) async {
        async let formFields: () = getFormFields(ticketId: ticketId)
        async let dependencies: () = getFieldDependencies()
        // Wait for both to finish
        _ = await (formFields, dependencies)
        await applyDefaultValuesInFields()
        applyDisplayConditionIntially(formFields: formFieldModel)
        let brand = FormFieldModel(
            id: -7,
            labelForCustomerPortal: "brand",
            isRequiredInCustomerPortal: true,
            apiName: "brandId",
            isDefaultField: true,
            fieldControlName: FormFieldType.singleLineTextBox.value,
            selectedItem: DropdownItemModel(
                id: ticketFormModel?.fieldOptionId ?? 0,
                itemName: ticketFormModel?.brandName ?? "",
                fieldOptionId: BDSupportSDK.isFromChatSDK ? BDSupportSDK.chatData?.offlineSettings?.brandOptionId ?? 0 : ticketFormModel?.fieldOptionId ?? 0
            )
        )
        
        for (index, field) in formFieldModel.enumerated() {
            let isDropdown =
            field.fieldControlName == FormFieldType.dropdown.value
            || field.fieldControlName
            == FormFieldType.lookup.value
            || field.fieldControlName
            == FormFieldType.multiselect.value
            
            if isDropdown {
                applyConditionBasedOnDependency(
                    index: index,
                    selectedFormField: brand,
                    field: field
                )
            }
        }
    }
    
    func getBrandFormDependency(searchText: String) async -> [DropdownItemModel]
    {
        do {
            // your async code
            
            dropdownItems = []
            let response = try await ticketFormBl.getBrandFormDependency()
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let brandFormItem = rawData["result"] as? [String: Any],
               !brandFormItem.isEmpty
            {
                let jsonData = try JSONSerialization.data(
                    withJSONObject: brandFormItem
                )
                ticketFormModel = try JSONDecoder().decode(
                    TicketFormModel.self,
                    from: jsonData
                )
                defaultTicketFormId =
                defaultTicketFormId != nil
                ? defaultTicketFormId
                : String(
                    ticketFormModel?.defaultTicketFormId ?? 0
                )
                
                ticketFormModel?.formMappingDetails.forEach { item in
                    dropdownItems.append(
                        DropdownItemModel(
                            id: item.formId,
                            itemName: item.labelForCustomerPortal ?? "",
                            displayName: item.labelForCustomerPortal ?? ""
                        )
                    )
                }
                isShowFormField = dropdownItems.count <= 1 ? false : true
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "getFormFields in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
        if searchText.isEmpty {
            return dropdownItems
        }
        
        return dropdownItems.filter {
            $0.itemName.localizedCaseInsensitiveContains(searchText)
        }
        
    }
    
    func getFormFields(ticketId: String?) async {
        do {
            let response = try await ticketFormBl.getTicketFormList(
                formId: ticketId
            )
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let formfieldItem = rawData["result"] as? [[String: Any]],
               !formfieldItem.isEmpty
            {
                let jsonData = try JSONSerialization.data(
                    withJSONObject: formfieldItem
                )
                formFieldModel = try JSONDecoder().decode(
                    [FormFieldModel].self,
                    from: jsonData
                )
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "getFormFields in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
        
        formFieldModel = defaultFormFieldsWithLogin() + formFieldModel
    }
    
    func getFieldDependencies() async {
        let start = Date()
        do {
            let response = try await ticketFormBl.getFieldDependencies()
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let dependenciesItems = rawData["result"] as? [[String: Any]],
               !dependenciesItems.isEmpty
            {
                let jsonData = try JSONSerialization.data(
                    withJSONObject: dependenciesItems
                )
                let decoded = try await Task.detached {
                    try JSONDecoder().decode(
                        [FieldDependencies].self,
                        from: jsonData
                    )
                }.value
                fieldDependencies = decoded
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "getFieldDependency in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
        let duration = Date().timeIntervalSince(start)
        print(" brand API Loading took \(duration) seconds")
    }
    
    func getDropdownItems(index: Int, searchText: String) async
    -> [DropdownItemModel]
    {
        switch formFieldModel[index].apiName {
        case "brand_form_dependency":
            return await getBrandFormDependency(searchText: searchText)
        case "priorityId":
            return await getPriority(index: index, searchText: searchText)
        case let apiName
            where apiName == formFieldModel[index].apiName
            && formFieldModel[index].fieldControlName
            == FormFieldType.lookup.value:
            return await fetchLookUpFieldItems(
                index: index,
                apiName: formFieldModel[index].apiName ?? "",
                searchText: searchText
            )
        default:
            return await fetchDropdownItems(
                index: index,
                apiName: formFieldModel[index].apiName ?? "",
                searchText: searchText
            )
        }
    }
    
    func fetchDropdownItems(index: Int, apiName: String, searchText: String)
    async -> [DropdownItemModel]
    {
        if isItemDisplaybasedOnParentField(selectedField: formFieldModel[index])
        {
            dropdownItems = []
            do {
                let response = try await ticketFormBl.getDynamicDropdownItems(
                    apiName: apiName,
                    searchText: searchText
                )
                
                if response.isSuccess {
                    if let rawData = response.data as? [String: Any],
                       let resultArray = rawData["result"] as? [[String: Any]]
                    {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: resultArray
                        )
                        let decodedItems = try JSONDecoder().decode(
                            [DynamicDropdownModel].self,
                            from: jsonData
                        )
                        decodedItems.forEach { item in
                            dropdownItems.append(
                                DropdownItemModel(
                                    id: item.id ?? 0,
                                    itemName: item.name ?? "",
                                    displayName: item.name ?? ""
                                )
                            )
                        }
                    }
                } else {
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                }
            } catch {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage:
                        "fetchDropdownItems in CreateTicketViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
            return dropdownItems
        } else {
            if searchText.isEmpty {
                return dropdownItems
            }
            
            return dropdownItems.filter {
                $0.itemName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    func fetchLookUpFieldItems(index: Int, apiName: String, searchText: String)
    async -> [DropdownItemModel]
    {
        if isItemDisplaybasedOnParentField(selectedField: formFieldModel[index])
        {
            dropdownItems = []
            do {
                let lookUpPayload = LookUpFieldConfiguration(
                    conditions: nil,
                    filter: searchText
                )
                let response = try await ticketFormBl.getLookUpFieldItems(
                    apiName: apiName,
                    lookUpPayload: lookUpPayload
                )
                
                if response.isSuccess {
                    if let rawData = response.data as? [String: Any],
                       let resultArray = rawData["result"] as? [[String: Any]]
                    {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: resultArray
                        )
                        let decodedItems = try JSONDecoder().decode(
                            [DynamicDropdownModel].self,
                            from: jsonData
                        )
                        decodedItems.forEach { item in
                            dropdownItems.append(
                                DropdownItemModel(
                                    id: item.id ?? 0,
                                    itemName: item.name ?? "",
                                    displayName: item.name ?? "",
                                    subtitle: item.email ?? ""
                                )
                            )
                        }
                    }
                } else {
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                }
            } catch {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage:
                        "fetchDropdownItems in CreateTicketViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
            return dropdownItems
        } else {
            if searchText.isEmpty {
                return dropdownItems
            }
            return dropdownItems.filter {
                $0.itemName.localizedCaseInsensitiveContains(searchText)
            }
        }
        
    }
    
    func getPriority(index: Int, searchText: String) async
    -> [DropdownItemModel]
    {
        
        if isItemDisplaybasedOnParentField(selectedField: formFieldModel[index])
        {
            dropdownItems = []
            
            do {
                let response = try await ticketFormBl.getPriorityItems(
                    searchText: searchText
                )
                
                if response.isSuccess {
                    if let rawData = response.data as? [String: Any],
                       let resultArray = rawData["result"] as? [[String: Any]]
                    {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: resultArray
                        )
                        let decodedItems = try JSONDecoder().decode(
                            [PriorityModel].self,
                            from: jsonData
                        )
                        decodedItems.forEach { item in
                            dropdownItems.append(
                                DropdownItemModel(
                                    id: item.id ?? 0,
                                    itemName: item.name ?? "",
                                    displayName: item.name ?? ""
                                )
                            )
                        }
                    }
                } else {
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                }
            } catch {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "getpriority in CreateTicketViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
                
            }
            return dropdownItems
        } else {
            if searchText.isEmpty {
                return dropdownItems
            }
            return dropdownItems.filter {
                $0.itemName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    private func defaultFieldForms() -> [FormFieldModel] {
        var fields: [FormFieldModel] = []
        fields.append(
            FormFieldModel(
                id: -4,
                labelForCustomerPortal: ResourceManager.localized(
                    "subjectLabelText"
                ),
                isRequiredInCustomerPortal: true,
                apiName: "subject",
                isDefaultField: true,
                fieldControlName: FormFieldType.singleLineTextBox.value,
                placeholderForCustomerPortal: ResourceManager.localized(
                    "enterTextHere"
                )
            )
        )
        
        fields.append(
            FormFieldModel(
                id: -5,
                labelForCustomerPortal: ResourceManager.localized(
                    "descriptionText"
                ),
                isRequiredInCustomerPortal: true,
                apiName: "description",
                isDefaultField: true,
                fieldControlName: FormFieldType.multiLineTextBox.value,
                placeholderForCustomerPortal: ResourceManager.localized(
                    "enterTextHere"
                )
            )
        )
        fields.append(
            FormFieldModel(
                id: -7,
                labelForCustomerPortal: "",
                isRequiredInCustomerPortal: false,
                apiName: "attachment",
                isDefaultField: true,
                fieldControlName: FormFieldType.fileUpload.value,
                defaultValue: "",
                isVisible: BDSupportSDK.isFromChatSDK ? (BDSupportSDK.chatData?.offlineSettings?.fileUploadOption ?? 0) != 1 : true
                
            )
        )
        
        return fields
    }
    
    private func anonymousSimpleFormList() -> [FormFieldModel] {
        var fields: [FormFieldModel] = []
        
        fields.append(
            FormFieldModel(
                id: -1,
                labelForCustomerPortal: ResourceManager.localized(
                    "namelabelText"
                ),
                isRequiredInCustomerPortal: true,
                apiName: "Name",
                isDefaultField: true,
                fieldControlName: FormFieldType.singleLineTextBox.value,
                placeholderForCustomerPortal: ResourceManager.localized(
                    "enterTextHere"
                ),
                text: BDSupportSDK.chatData?.name
            )
        )
        fields.append(
            FormFieldModel(
                id: -2,
                labelForCustomerPortal: ResourceManager.localized("emailText"),
                isRequiredInCustomerPortal: true,
                apiName: BDSupportSDK.isFromChatSDK ? "emailId" : "EmailAddress",
                isDefaultField: true,
                fieldControlName: FormFieldType.email.value,
                placeholderForCustomerPortal: ResourceManager.localized(
                    "enterTextHere"
                ),
                text: BDSupportSDK.chatData?.email
            )
        )
        fields.append(
            FormFieldModel(
                id: -3,
                labelForCustomerPortal: ResourceManager.localized(
                    "phoneNumberText"
                ),
                isRequiredInCustomerPortal: true,
                apiName: "PhoneNumber",
                isDefaultField: true,
                fieldControlName: FormFieldType.singleLineTextBox.value,
                placeholderForCustomerPortal: ResourceManager.localized(
                    "enterTextHere"
                ),
                text: BDSupportSDK.chatData?.phoneNo
            )
        )
        return fields + defaultFieldForms()
    }
    
    private func defaultFormFieldsWithLogin() -> [FormFieldModel] {
        var fields: [FormFieldModel] = []
        fields.append(
            FormFieldModel(
                id: -6,
                labelForCustomerPortal: ResourceManager.localized("formText"),
                isRequiredInCustomerPortal: false,
                apiName: "brand_form_dependency",
                isDefaultField: true,
                fieldControlName: FormFieldType.dropdown.value,
                defaultValue: defaultTicketFormId,
                isVisible: isMultiformEnabled && isShowFormField
            )
        )
        // If coming from Chat SDK, include anonymous fields (name/email/phone)
        // even when the app has a logged-in token so chat metadata is preserved.
        if BDSupportSDK.isFromChatSDK {
            return fields + anonymousSimpleFormList()
        }

        if AppConstant.authToken.isEmpty {
            return fields + anonymousSimpleFormList()
        } else {
            return fields + defaultFieldForms()
        }
    }
    
    //Display condition
    func applyDefaultValuesInFields() async {
        for index in formFieldModel.indices {
            if formFieldModel[index].fieldControlName
                == FormFieldType.checkBox.value
                || formFieldModel[index].fieldControlName
                == FormFieldType.radioButton.value
            {
                formFieldModel[index].isChecked =
                formFieldModel[index].defaultValue == "true"
            } else if formFieldModel[index].fieldControlName
                        == FormFieldType.dropdown.value
                        || formFieldModel[index].fieldControlName
                        == FormFieldType.lookup.value
            {
                
                if let defaultId = Int(
                    formFieldModel[index].defaultValue ?? ""
                ) {
                    let dropdownItems: [DropdownItemModel] =
                    await getDropdownItems(
                        index: index,
                        searchText: ""
                    )
                    if let matchedItem = dropdownItems.first(where: {
                        $0.id == defaultId
                    }) {
                        formFieldModel[index].selectedItem = matchedItem
                    }
                }
                
            }
        }
    }
    
    func applyDisplayConditionsBasedOnSelectedField(
        selectedFormField: FormFieldModel
    ) {
        for (index, field) in formFieldModel.enumerated() {
            if let displayCondition = field.displayCondition,
               !displayCondition.rules.isEmpty,
               displayCondition.rules.contains(where: {
                   $0.field == selectedFormField.apiName
               })
            {
                
                let displayConditionLinkedFields = formFieldModel.filter { x in
                    displayCondition.rules.contains(where: {
                        $0.field == x.apiName
                    })
                }
                showAndHideFieldBasedOnCondition(
                    field: field,
                    displayConditionLinkedFields: displayConditionLinkedFields
                )
            }
            if selectedFormField.fieldControlName
                == FormFieldType.dropdown.value
                && (field.fieldControlName == FormFieldType.dropdown.value
                    || field.fieldControlName == FormFieldType.lookup.value
                    || field.fieldControlName
                    == FormFieldType.multiselect.value)
            {
                applyConditionBasedOnDependency(
                    index: index,
                    selectedFormField: selectedFormField,
                    field: field
                )
            }
        }
    }
    
    func applyDisplayConditionIntially(formFields: [FormFieldModel]) {
        for field in formFields {
            // 1. Display condition visibility check
            if let rules = field.displayCondition?.rules {
                let linkedFields = formFields.filter { x in
                    rules.contains { $0.field == x.apiName }
                }
                showAndHideFieldBasedOnCondition(
                    field: field,
                    displayConditionLinkedFields: linkedFields
                )
            }
            
            // 2. Dependency-based dropdown/multiselect updates
            let isDropdownOrMultiSelect =
            field.fieldControlName == FormFieldType.dropdown.value
            || field.fieldControlName == FormFieldType.lookup.value
            || field.fieldControlName == FormFieldType.multiselect.value
            
            let hasSelection =
            (field.selectedItem != nil)
            || (field.selectedItems != nil
                && !(field.selectedItems?.isEmpty ?? true))
            
            guard isDropdownOrMultiSelect, hasSelection else { continue }
            
            for (targetIndex, targetField) in formFields.enumerated() {
                let isTargetDropdownOrMultiSelect =
                targetField.fieldControlName == FormFieldType.dropdown.value
                || targetField.fieldControlName
                == FormFieldType.lookup.value
                || targetField.fieldControlName
                == FormFieldType.multiselect.value
                
                if isTargetDropdownOrMultiSelect {
                    applyConditionBasedOnDependency(
                        index: targetIndex,
                        selectedFormField: field,
                        field: targetField
                    )
                }
            }
        }
    }
    
    func showAndHideFieldBasedOnCondition(
        field: FormFieldModel,
        displayConditionLinkedFields: [FormFieldModel]
    ) {
        var results: [Bool] = []
        for linkedField in displayConditionLinkedFields {
            let rule = field.displayCondition?.rules.first(where: {
                $0.field == linkedField.apiName
            })
            if rule?.type == RuleTypeEnum.long.value {
                if rule?.operator == RuleOperatorEnum.operatorIn.value {
                    if linkedField.selectedItem == nil {
                        results.append(false)
                    } else if rule?.value.map({ String(describing: $0) })
                        .contains(String(linkedField.selectedItem?.id ?? 0))
                                == true,
                              linkedField.isVisible == true
                    {
                        results.append(true)
                    } else {
                        results.append(false)
                    }
                } else {
                    if linkedField.isVisible == false {
                        results.append(false)
                    } else if rule?.operator
                                == RuleOperatorEnum.operatorNotIn.value
                                && linkedField.selectedItem == nil
                    {
                        results.append(true)
                    } else if linkedField.selectedItem == nil {
                        results.append(false)
                    } else if rule?.value.map({ String(describing: $0) })
                        .contains(String(linkedField.selectedItem?.id ?? 0))
                                == true,
                              linkedField.isVisible == true
                    {
                        results.append(false)
                    } else {
                        results.append(true)
                    }
                }
            } else if rule?.type == RuleTypeEnum.listOfLong.value {
                if rule?.operator == RuleOperatorEnum.operatorIn.value {
                    if linkedField.selectedItems == nil
                        || linkedField.selectedItems!.isEmpty
                    {
                        results.append(false)
                    } else if !linkedField.selectedItems!.isEmpty {
                        let selectedFieldItemIds: [String] =
                        (linkedField.selectedItems)?.map { String($0.id) }
                        ?? []
                        if (rule?.value.contains(
                            where: selectedFieldItemIds.contains
                        ) ?? false) && linkedField.isVisible == true {
                            results.append(true)
                        } else {
                            results.append(false)
                        }
                    }
                } else {
                    if linkedField.isVisible == false {
                        results.append(false)
                    }
                    if linkedField.selectedItems == nil
                        || linkedField.selectedItems!.isEmpty
                    {
                        results.append(false)
                    } else if !linkedField.selectedItems!.isEmpty {
                        let selectedFieldItemIds: [String] =
                        (linkedField.selectedItems)?.map { String($0.id) }
                        ?? []
                        if (rule?.value.contains(
                            where: selectedFieldItemIds.contains
                        ) ?? false) && linkedField.isVisible == true {
                            results.append(true)
                        } else {
                            results.append(false)
                        }
                    }
                }
            } else {
                if let values = rule?.value as? [Any], !values.isEmpty {
                    if let stringValue = values[0] as? String,
                       let boolValue = Bool(stringValue.lowercased())
                    {
                        results.append(
                            boolValue == linkedField.isChecked
                            && linkedField.isVisible == true
                        )
                    } else {
                        results.append(
                            (values[0] as? Bool) == linkedField.isChecked
                            && linkedField.isVisible == true
                        )
                    }
                } else {
                    results.append(false)
                }
            }
            formFieldModel = formFieldModel.map { item in
                var updatedItem = item
                if item.id == field.id {
                    updatedItem.isVisible =
                    results.contains(false) ? false : true
                }
                return updatedItem
            }
        }
    }
    
    func isItemDisplaybasedOnParentField(selectedField: FormFieldModel) -> Bool
    {
        if selectedField.isItemsDisplayedBasedOnFieldDependency {
            dropdownItems = []
            dropdownItems = selectedField.dropdownItems ?? []
            return false
        }
        return true
        
    }
    
    func applyConditionBasedOnDependency(
        index: Int,
        selectedFormField: FormFieldModel,
        field: FormFieldModel
    ) {
        for dependency in fieldDependencies {
            if (selectedFormField.apiName != nil
                && selectedFormField.apiName == dependency.parentField.apiName)
                || (selectedFormField.id != nil
                    && selectedFormField.id == dependency.parentField.fieldId)
            {
                if field.apiName == dependency.childField.apiName
                    || field.id == dependency.childField.fieldId
                {
                    var filteredChildOptions: [DynamicDropdownModel] = []
                    let matchingChildIds = dependency.dependencyMapping
                        .filter {
                            $0.parentFieldOptionId
                            == selectedFormField.selectedItem?.id
                        }
                        .flatMap { $0.childFieldOptionId }
                    
                    let hasMatchingDependency = dependency.dependencyMapping
                        .contains {
                            $0.parentFieldOptionId
                            == selectedFormField.selectedItem?.id
                        }
                    
                    if !hasMatchingDependency {
                        formFieldModel[index]
                            .isItemsDisplayedBasedOnFieldDependency = true
                        formFieldModel[index].dropdownItems = dependency
                            .childOptions.map { item in
                                DropdownItemModel(
                                    id: item.id ?? 0,
                                    itemName: item.name ?? "",
                                    displayName: item.name ?? ""
                                )
                            }
                    } else {
                        if !matchingChildIds.isEmpty {
                            filteredChildOptions = dependency.childOptions
                                .filter { option in
                                    if let optionId = option.id {
                                        return matchingChildIds.contains(
                                            optionId
                                        )
                                    }
                                    return false
                                }
                            
                            if field.fieldControlName
                                == FormFieldType.dropdown.value
                            {
                                if let selectedId = field.selectedItem?.id,
                                   matchingChildIds.contains(selectedId)
                                {
                                    formFieldModel[index].selectedItem =
                                    field.selectedItem
                                } else {
                                    formFieldModel[index].selectedItem = nil
                                }
                            } else if field.fieldControlName
                                        == FormFieldType.multiselect.value
                            {
                                let filteredItems =
                                field.selectedItems?.filter {
                                    matchingChildIds.contains($0.id)
                                } ?? []
                                formFieldModel[index].selectedItems =
                                filteredItems.isEmpty ? [] : filteredItems
                            }
                            
                            if !filteredChildOptions.isEmpty {
                                formFieldModel[index].dropdownItems =
                                filteredChildOptions.map { item in
                                    DropdownItemModel(
                                        id: item.id ?? 0,
                                        itemName: item.name ?? "",
                                        displayName: item.name ?? ""
                                    )
                                }
                                formFieldModel[index]
                                    .isItemsDisplayedBasedOnFieldDependency =
                                true
                            } else {
                                formFieldModel[index].dropdownItems = []
                            }
                        }
                    }
                }
            }
        }
    }
    
    func validateForm() -> Bool {
        var isAllValid = true
        
        for (index, field) in formFieldModel.enumerated() {
            // Skip if hidden or not visible
            if (field.hideInCreateFormCustomerPortal ?? false)
                || !(field.isVisibleInCustomerPortal ?? false)
                || !(field.isVisible ?? true)
            {
                continue
            }
            
            switch field.fieldControlName {
            case FormFieldType.singleLineTextBox.value,
                FormFieldType.multiLineTextBox.value,
                FormFieldType.description.value,
                FormFieldType.numeric.value,
                FormFieldType.decimal.value,
                FormFieldType.regex.value,
                FormFieldType.url.value,
                FormFieldType.email.value:
                if field.apiName == "cc" {
                    isAllValid = ccFieldvalidation(
                        index: index,
                        selectedItems: ccFieldvalues
                    )
                } else if !textFieldValidation(
                    index: index,
                    text: field.text ?? ""
                ) {
                    isAllValid = false
                }
                
            case FormFieldType.checkBox.value,
                FormFieldType.radioButton.value:
                if !checkBoxValidation(
                    index: index,
                    isChecked: field.isChecked ?? false
                ) {
                    isAllValid = false
                }
                
            case FormFieldType.date.value:
                if !dateTimeValidation(index: index, date: field.selectedDate) {
                    isAllValid = false
                }
                
            case FormFieldType.datetime.value:
                if !dateTimeValidation(
                    index: index,
                    date: field.selectedDateTime
                ) {
                    isAllValid = false
                }
                
            case FormFieldType.dropdown.value:
                if !singleSelectValidation(
                    index: index,
                    selectedItems: field.selectedItem
                ) {
                    isAllValid = false
                }
                
            case FormFieldType.lookup.value:
                if !singleSelectValidation(
                    index: index,
                    selectedItems: field.selectedItem
                ) {
                    isAllValid = false
                }
                
            case FormFieldType.multiselect.value:
                if !multiSelectValidation(
                    index: index,
                    selectedItems: field.selectedItems ?? []
                ) {
                    isAllValid = false
                }
                
            default:
                continue
            }
        }
        
        return isAllValid
    }
    
    func submiTicket() async {
        guard validateForm() else { return }
        do {
            isShowProgress = true
            var finalPayload: [String: Any] = [:]
            if (isMultiformEnabled || BDSupportSDK.isFromChatSDK) && defaultTicketFormId != nil {
                finalPayload = ["ticketFormId": defaultTicketFormId!]
            }
            if (!AppConstant.authToken.isEmpty && ContactUs.isSimpleContactForm) || BDSupportSDK.isFromChatSDK {
                finalPayload["Name"] = UserInfo.name
                finalPayload["PhoneNumber"] = UserInfo.phone
                if BDSupportSDK.isFromChatSDK{
                    finalPayload["emailId"] = UserInfo.email
                }
                else {
                    finalPayload["EmailAddress"] = UserInfo.email
                }
            }
            
            var customFields: [String: Any] = [:]
            
            for field in formFieldModel {
                guard let key = field.apiName,
                      field.apiName != "brand_form_dependency"
                else { continue }
                let value: Any = extractValue(from: field)
                
                if isValid(value: value) {
                    if field.isDefaultField == true {
                        finalPayload[key] = value
                    } else {
                        customFields[key] = value
                    }
                }
            }
            var fileEntries: [[String: Any]] = []
            
            for item in pickedItem {
                if let fileURL = item.file {
                    do {
                        let fileData = try Data(contentsOf: fileURL)
                        let fileName = fileURL.lastPathComponent
                        let mimeType = MultipartHelper.mimeType(from: fileURL)
                        
                        fileEntries.append([
                            "data": fileData,
                            "filename": fileName,
                            "mimeType": mimeType,
                        ])
                    } catch {
                        print("Failed to load file: \(error)")
                    }
                }
            }
            
            // Only set if files exist
            if !fileEntries.isEmpty {
                finalPayload["File"] = fileEntries
            }
            
            finalPayload["CustomFields"] = customFields
            
            let res = try await ticketFormBl.submitTicket(
                formFields: finalPayload,
                isSimpleForm: ContactUs.isSimpleContactForm
            )
            
            if res.isSuccess {
                if let data = res.data as? [String: Any],
                   let id = data["id"] as? Int, BDSupportSDK.isFromChatSDK {
                    ticketId = String(id)
                    BDSupportSDK.onTicketCreatedEventCallBack?(ticketId, nil)
                    ticketLink = "\(BDSupportSDK.chatData?.brandURL ?? "")/support/tickets/\(id)"
                    isShowTicketLink = true
                }
                isShowProgress = false
                shouldDismiss = true
            } else if res.statusCode == 400, let data = res.data {
                handleValidationError(data: data)
                isShowProgress = false
            } else {
                ErrorLogs.logErrors(data: res.data, isCatchError: false)
                isShowProgress = false
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "submitTicket in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
            isShowProgress = false
        }
        isShowProgress = false
    }
    
    private func extractValue(from field: FormFieldModel) -> Any {
        switch field.fieldControlName {
        case FormFieldType.singleLineTextBox.value,
            FormFieldType.multiLineTextBox.value,
            FormFieldType.description.value,
            FormFieldType.regex.value,
            FormFieldType.url.value,
            FormFieldType.email.value:
            if field.apiName == "cc" {
                // Construct structured CC array from ccFieldvalues
                let emails = ccFieldvalues.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                let ccObjects: [[String: Any]] = emails.map { email in
                    ["email": email, "displayName": email]
                }
                return ccObjects.isEmpty ? NSNull() : ccObjects
            }
            return field.text ?? NSNull()
            
        case FormFieldType.numeric.value,
            FormFieldType.decimal.value:
            guard let text = field.text, !text.isEmpty else { return NSNull() }
            if let intVal = Int(text) { return intVal }
            if let doubleVal = Double(text) { return doubleVal }
            return NSNull()
            
        case FormFieldType.checkBox.value,
            FormFieldType.radioButton.value:
            return field.isChecked ?? NSNull()
            
        case FormFieldType.date.value:
            return field.selectedDate ?? NSNull()
            
        case FormFieldType.datetime.value:
            return toUTCDateTime(
                from: field.selectedDateTime ?? "",
                inputFormat: "yyyy-MM-dd, h:mm a"
            ) ?? NSNull()
            
        case FormFieldType.dropdown.value:
            return field.selectedItem?.id ?? NSNull()
            
        case FormFieldType.lookup.value:
            return field.selectedItem?.id ?? NSNull()
            
        case FormFieldType.multiselect.value:
            let selectedIDs =
            field.selectedItems?
                .compactMap { $0.id } ?? []
            
            return selectedIDs.isEmpty ? NSNull() : selectedIDs
        default:
            return NSNull()
        }
    }
    
    private func handleValidationError(data: Any) {
        do {
            let jsonData = try JSONSerialization.data(
                withJSONObject: data,
                options: []
            )
            let decodedError = try JSONDecoder().decode(
                ExceptionMessage.self,
                from: jsonData
            )
            ToastManager.shared.show(
                decodedError.message
                ?? ResourceManager.localized("unknownError", comment: ""),
                type: .error
            )
            for (index, field) in formFieldModel.enumerated() {
                decodedError.errors?.forEach { error in
                    if field.apiName == error.field {
                        formFieldModel[index].isValid = false
                        formFieldModel[index].errorMessage =
                        error.errorMessage ?? ""
                    }
                }
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "handleValidationError in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
    
    private func isValid(value: Any) -> Bool {
        switch value {
        case let string as String:
            return !string.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        case let array as [Any]:
            return !array.isEmpty
        case _ as Int:
            return true  // Int is always valid if it reaches here
        case let doubleVal as Double:
            return !doubleVal.isNaN  // NaN is considered invalid
        case _ as Bool:
            return true  // Bool values are always valid
        case is NSNull:
            return false
        case let optional as Any?:
            return optional != nil
        default:
            return true  // Dates, custom objects, etc.
        }
    }
    
    func resetForm() async {
        formFieldModel = []
        dropdownItems = []
        ccFieldvalues = []
        isLoading = true
        if !BDSupportSDK.isFromChatSDK {
            await appInfoVM.loadGeneralSettings(force: true)
        }
        loadBasedOnSettingsAndCreateForm()
    }
}
