import Foundation
import SwiftUI

@MainActor
class TicketEditDetailsViewModel: ObservableObject {

    var ticketId: String = ""
    var ticketFormBl = TicketFormBL()
    var ticketDetailsBl = TicketEditDetailBL()
    @Published var formFieldModel: [FormFieldModel] = []
    @Published var ticketDetailsModel: TicketDetailModel?
    @Published var isLoading: Bool = false
    @Published var shouldDismiss: Bool = false
    @Published var isShowProgress: Bool = false
    @Published var ccFieldvalues: [String] = []
    var existingFormModel: [FormFieldModel] = []
    var brandFormModel: BrandFormModel?
    var radioOption: [String] = ["Yes", "No"]
    var dropdownItems: [DropdownItemModel] = []
    var validation = Validation()
    var fieldDependencies: [FieldDependencies] = []
    var selectedForm: DropdownItemModel?
    var isEnableMultiForm: Bool = true
    var isRefresh: Bool = false
    var isShowFormField: Bool = false

    init(ticketId: String) {
        isEnableMultiForm = GeneralSettings.isMultipleTicketFormEnabled
        self.ticketId = ticketId
        Task {
            await getFieldsAndApplyCondition()
        }
    }
    var hasFormChanged: Bool {
        guard formFieldModel.count == existingFormModel.count else {
            return true
        }

        for (current, original) in zip(formFieldModel, existingFormModel) {
            if current.text != original.text
                || current.isChecked != original.isChecked
                || current.selectedDate != original.selectedDate
                || current.selectedDateTime != original.selectedDateTime
                || current.selectedItem?.id != original.selectedItem?.id
                || current.selectedItems?.map({ $0.id })
                    != original.selectedItems?.map({ $0.id })
            {
                return true
            }
        }

        return false
    }

    func updatedEnteredText(index: Int, text: String) {
        formFieldModel[index].text = text
        print(formFieldModel[index].text ?? "")
    }

    func updateSelectedDate(index: Int, date: String?) {
        formFieldModel[index].selectedDate = date
        print(formFieldModel[index].selectedDate ?? "")
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
        applyDisplayConditionsBasedOnSelectedField(
            selectedFormField: formFieldModel[index]
        )
    }

    func updateForm(index: Int, selectedItem: DropdownItemModel?) {
        formFieldModel[index].selectedItem = selectedItem
        selectedForm = selectedItem
        Task {
            await getFormListBasedOnFormId(
                formId: String(selectedItem?.id ?? 0)
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
        ccFieldvalues = selectedItems
        let combinedString = selectedItems.joined(separator: "; ")
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
            || formFieldModel[index].fieldType == "ePHI"
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
            } else if !validation.isValidEmail(text) {
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

    func getFormListBasedOnFormId(formId: String) async {
        isLoading = true
        ccFieldvalues = []
        async let formFields: () = getFormFields(formId: formId)
        async let dependencies: () = getFieldDependencies()
        // Wait for both to finish
        _ = await (formFields, dependencies)
        applyDefaultValuesInFields()
        await setFormFieldValuesFromCurrentTicket()
        applyDisplayConditionIntially(formFields: formFieldModel)
        applyfieldDependencyBasedOnBrand()
        isLoading = false
    }

    func getFieldsAndApplyCondition() async {
        isLoading = true
        await getTicketProperties(ticketId: ticketId)
        if isEnableMultiForm {
            await getBrandFormDependency()
        }
        // Conditional async call for brandForm
        async let formFields: () = getFormFields(
            formId: ticketDetailsModel?.ticketFormDetails?.id != nil
                ? String(ticketDetailsModel!.ticketFormDetails!.id!) : nil
        )
        async let dependencies: () = getFieldDependencies()
        _ = await (formFields, dependencies)

        applyDefaultValuesInFields()
        await setFormFieldValuesFromCurrentTicket()
        applyDisplayConditionIntially(formFields: formFieldModel)
        applyfieldDependencyBasedOnBrand()
        existingFormModel = formFieldModel
        isLoading = false
    }

    func getTicketProperties(ticketId: String) async {

        do {
            let response = try await ticketDetailsBl.getTicketProperties(
                ticketId: ticketId
            )

            if response.isSuccess {
                if let rawData = response.data as? [String: Any],
                    let ticketJson = rawData["result"] as? [String: Any]
                {

                    let jsonData = try JSONSerialization.data(
                        withJSONObject: ticketJson,
                        options: []
                    )

                    let decoded = try await Task.detached {
                        try JSONDecoder().decode(
                            TicketDetailModel.self,
                            from: jsonData
                        )
                    }.value

                    ticketDetailsModel = decoded
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage:
                    "getTicketProperties in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    func getBrandFormDependency() async {

        do {
            let response = try await ticketFormBl.getBrandFormDependency()

            if response.isSuccess {
                if let rawData = response.data as? [String: Any],
                    let brandFormjson = rawData["result"] as? [String: Any]
                {

                    let jsonData = try JSONSerialization.data(
                        withJSONObject: brandFormjson,
                        options: []
                    )

                    let decoded = try await Task.detached {
                        try JSONDecoder().decode(
                            BrandFormModel.self,
                            from: jsonData
                        )
                    }.value

                    brandFormModel = decoded
                    _ = await getFormDropdownItems(index: 0, searchText: "")
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage:
                    "getBrandFormDependency in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    func getFormFields(formId: String?) async {
        defer {
            print("Fetched form fields: \(formFieldModel.count)")
        }

        do {
            let response = try await ticketFormBl.getTicketFormList(
                formId: formId,
                isForCreateForm: false
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
                exceptionPage: "getFormFields in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
        formFieldModel = defaultFormFields() + formFieldModel
    }

    func getFieldDependencies() async {
        defer {
            print("Fetched fieldDependencies: \(fieldDependencies.count)")
        }

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
                exceptionPage: "getFormFields in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    func getFormDropdownItems(index: Int, searchText: String) async
        -> [DropdownItemModel]
    {
        let items = brandFormModel?.formMappingDetails ?? []

        let filteredItems = items.filter { item in
            let isEnabled = item.isEnabled ?? false
            let isVisible = item.isVisibleInCustomerPortal ?? false
            let label = item.labelForCustomerPortal?.lowercased() ?? ""

            if isEnabled && isVisible {
                if searchText.isEmpty {
                    return true
                } else {
                    return label.contains(searchText.lowercased())
                }
            }
            return false
        }

        let dropdownItems = filteredItems.map { item in
            DropdownItemModel(
                id: item.formId,
                itemName: item.labelForCustomerPortal ?? "",
                displayName: item.labelForCustomerPortal ?? ""
            )
        }
        isShowFormField = dropdownItems.count <= 1 ? false : true

        if searchText.isEmpty {
            return dropdownItems
        }

        return dropdownItems.filter {
            $0.itemName.localizedCaseInsensitiveContains(searchText)
        }
    }

    func applyDefaultValuesInFields() {
        for index in formFieldModel.indices {
            if formFieldModel[index].apiName == DefaultFieldAPIName.status.value
            {
                formFieldModel[index].selectedItem = DropdownItemModel(
                    id: ticketDetailsModel?.statusOptionId ?? 0,
                    itemName: ticketDetailsModel?.status ?? "",
                    displayName: ticketDetailsModel?.status ?? ""
                )
            } else if formFieldModel[index].apiName
                == DefaultFieldAPIName.form.value
            {
                if selectedForm != nil {
                    formFieldModel[index].selectedItem = selectedForm
                } else {
                    formFieldModel[index].selectedItem = DropdownItemModel(
                        id: ticketDetailsModel?.ticketFormDetails?.id ?? 0,
                        itemName: ticketDetailsModel?.ticketFormDetails?.name
                            ?? "",
                        displayName: ticketDetailsModel?.ticketFormDetails?.name
                            ?? ""
                    )
                }
            }
        }
    }

    func getDropdownItems(index: Int, searchText: String) async
        -> [DropdownItemModel]
    {
        switch formFieldModel[index].apiName {
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
                        "fetchDropdownItems in TicketEditDetailsViewModel",
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
                    exceptionPage: "getpriority in TicketEditDetailsViewModel",
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
    func applyfieldDependencyBasedOnBrand() {
        let brandField = FormFieldModel(
            id: brandFormModel?.brandId,
            labelForCustomerPortal: "Brand",
            isRequiredInCustomerPortal: false,
            apiName: DefaultFieldAPIName.brand.value,
            fieldControlName: FormFieldType.dropdown.value,
            selectedItem: DropdownItemModel(
                id: ticketDetailsModel?.brandOptionId ?? 0,
                itemName: ""
            )
        )

        for (index, item) in formFieldModel.enumerated() {
            if !(item.apiName == DefaultFieldAPIName.status.value)
                && !(item.apiName == DefaultFieldName.agent.value)
            {
                applyFieldDependencyCondition(
                    index: index,
                    selectedFormField: brandField,
                    field: item
                )
            }
        }

    }
    //Display condition
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
            if (selectedFormField.fieldControlName
                == FormFieldType.dropdown.value
                || selectedFormField.fieldControlName
                    == FormFieldType.lookup.value)
                && (field.fieldControlName == FormFieldType.dropdown.value
                    || field.fieldControlName == FormFieldType.lookup.value
                    || field.fieldControlName == FormFieldType.multiselect.value)
            {
                applyFieldDependencyCondition(
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
                    applyFieldDependencyCondition(
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
                                && linkedField.userCanEdit ?? false
                        )
                    } else {
                        results.append(
                            (values[0] as? Bool) == linkedField.isChecked
                                && linkedField.isVisible == true
                                && linkedField.userCanEdit ?? false
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

    func applyFieldDependencyCondition(
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
                                if let selectedId = field.selectedItem?.id {
                                    formFieldModel[index].selectedItem =
                                        field.selectedItem
                                    if !matchingChildIds.contains(selectedId) {
                                        formFieldModel[index].isValid = false
                                        formFieldModel[index].errorMessage =
                                            "The field value doesn't corresponds to selected \(selectedFormField.labelForCustomerPortal ?? "")"
                                    }
                                } else {
                                    formFieldModel[index].selectedItem = nil
                                }
                            } else if field.fieldControlName
                                == FormFieldType.multiselect.value
                            {
                                if let selectedItems = field.selectedItems {
                                    formFieldModel[index].selectedItems =
                                        selectedItems
                                    let hasInvalidItem = selectedItems.contains
                                    { !matchingChildIds.contains($0.id) }
                                    if hasInvalidItem {
                                        formFieldModel[index].isValid = false
                                        formFieldModel[index].errorMessage =
                                            "The field value doesn't corresponds to selected \(selectedFormField.labelForCustomerPortal ?? "")"
                                    }
                                }
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

    func setFormFieldValuesFromCurrentTicket() async {

        for (index, field) in formFieldModel.enumerated() {
            var updatedField = field
            guard let currentTicketDetails = ticketDetailsModel else { return }

            if field.apiName == DefaultFieldAPIName.category.value
                && currentTicketDetails.categoryId != nil
            {
                updatedField.selectedItem = DropdownItemModel(
                    id: currentTicketDetails.categoryId?.id ?? 0,
                    itemName: currentTicketDetails.categoryId?.name ?? "",
                    displayName: currentTicketDetails.categoryId?.name ?? ""
                )
            } else if field.apiName == DefaultFieldAPIName.cc.value,
                let cc = currentTicketDetails.cc, !cc.isEmpty
            {
                updatedField.text = cc
                ccFieldvalues = cc.split(separator: ";").map {
                    $0.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            } else if field.apiName == DefaultFieldAPIName.type.value
                && currentTicketDetails.typeId != nil
            {
                updatedField.selectedItem = DropdownItemModel(
                    id: currentTicketDetails.typeId?.id ?? 0,
                    itemName: currentTicketDetails.typeId?.name ?? "",
                    displayName: currentTicketDetails.typeId?.name ?? ""
                )
            } else if field.apiName == DefaultFieldAPIName.priority.value
                && currentTicketDetails.priorityId != nil
            {
                updatedField.selectedItem = DropdownItemModel(
                    id: currentTicketDetails.priorityId?.id ?? 0,
                    itemName: currentTicketDetails.priorityId?.name ?? "",
                    displayName: currentTicketDetails.priorityId?.name ?? ""
                )
            } else if field.apiName == DefaultFieldAPIName.cc.value {
                updatedField.text = currentTicketDetails.cc ?? ""
            } else if field.apiName == DefaultFieldName.resolutionDue.value {
                updatedField.selectedDateTime = convertUTCToLocalDateTime(
                    dateString: currentTicketDetails.resolutionDue ?? ""
                )
            }
            if let customFields = currentTicketDetails.customFields {
                if let customField = customFields.first(where: {
                    $0.apiName == field.apiName
                }) {
                    let value = customField.formFieldsContents.value
                    if field.fieldControlName
                        == FormFieldType.singleLineTextBox.value
                        || field.fieldControlName == FormFieldType.email.value
                    {
                        updatedField.text = value as? String
                    } else if field.fieldControlName
                        == FormFieldType.description.value
                        || field.fieldControlName
                            == FormFieldType.multiLineTextBox.value
                    {
                        updatedField.text = value as? String
                    } else if field.fieldControlName == FormFieldType.date.value
                    {
                        let date = value as? String
                        if date != nil {
                            updatedField.selectedDate =
                                date!.isEmpty
                                ? nil
                                : convertUTCToLocalDateTime(
                                    dateString: date ?? ""
                                )
                        }
                    } else if field.fieldControlName
                        == FormFieldType.datetime.value
                    {
                        let dateTime = value as? String
                        if dateTime != nil {
                            updatedField.selectedDateTime =
                                dateTime!.isEmpty
                                ? nil
                                : convertUTCToLocalDateTime(
                                    dateString: dateTime ?? ""
                                )
                        }
                    } else if field.fieldControlName
                        == FormFieldType.numeric.value
                    {
                        if let intValue = value as? Int {
                            updatedField.text = String(intValue)
                        }
                    } else if field.fieldControlName
                        == FormFieldType.decimal.value
                    {
                        if let intValue = value as? Int {
                            updatedField.text = String(intValue)
                        }
                    } else if field.fieldControlName
                        == FormFieldType.dropdown.value
                        || field.fieldControlName == FormFieldType.lookup.value
                    {
                        if let dict = value as? [String: AnyCodable] {
                            // handle dropdown
                            let id = dict["id"]?.value as? Int
                            let name = dict["name"]?.value as? String
                            let subtitle = dict["email"]?.value as? String
                            if let id = id, let name = name {
                                updatedField.selectedItem = DropdownItemModel(
                                    id: id,
                                    itemName: name,
                                    displayName: name,
                                    subtitle: subtitle ?? ""
                                )
                            }
                        }
                    } else if field.fieldControlName
                        == FormFieldType.multiselect.value
                    {
                        updatedField.selectedItems = []
                        if let array = value as? [AnyCodable] {
                            // handle multi-select
                            for entry in array {
                                if let dict = entry.value
                                    as? [String: AnyCodable],
                                    let id = dict["id"]?.value as? Int,
                                    let name = dict["name"]?.value as? String
                                {
                                    updatedField.selectedItems?.append(
                                        DropdownItemModel(
                                            id: id,
                                            itemName: name,
                                            displayName: name
                                        )
                                    )
                                }
                            }
                        }
                    } else if field.fieldControlName
                        == FormFieldType.regex.value
                    {
                        updatedField.text = value as? String
                    } else if field.fieldControlName == FormFieldType.url.value
                    {
                        updatedField.text = value as? String
                    } else if field.fieldControlName
                        == FormFieldType.checkBox.value
                        || field.fieldControlName
                            == FormFieldType.radioButton.value
                    {
                        if let boolValue = value as? Bool {
                            updatedField.isChecked = boolValue
                        } else {
                            updatedField.isChecked = false
                        }
                    }
                }
            }
            formFieldModel[index] = updatedField
        }
    }

    private func defaultFormFields() -> [FormFieldModel] {
        return [
            FormFieldModel(
                id: -1,
                labelForCustomerPortal: DefaultFieldName.status.value,
                isRequiredInCustomerPortal: true,
                apiName: DefaultFieldAPIName.status.value,
                isDefaultField: true,
                fieldControlName: FormFieldType.dropdown.value,
                placeholderForCustomerPortal: "Select value",
                selectedItem: DropdownItemModel(
                    id: ticketDetailsModel?.statusOptionId ?? 0,
                    itemName: ticketDetailsModel?.status ?? "",
                    displayName: ticketDetailsModel?.status ?? ""
                )
            ),
            FormFieldModel(
                id: -2,
                labelForCustomerPortal: ticketDetailsModel?.labelForAgent,
                isRequiredInCustomerPortal: false,
                apiName: DefaultFieldAPIName.agent.value,
                isDefaultField: true,
                fieldControlName: FormFieldType.singleLineTextBox.value,
                userCanEdit: false,
                placeholderForCustomerPortal: ResourceManager.localized(
                    "notYetAssignedText",
                    comment: ""
                ),
                text: ticketDetailsModel?.agent?.isEmpty == false
                    ? ticketDetailsModel?.agent
                    : ResourceManager.localized(
                        "notYetAssignedText",
                        comment: ""
                    ),
                isVisible: ticketDetailsModel?.labelForAgent?.isEmpty == false
                    ? true : false
            ),
            FormFieldModel(
                id: -4,
                labelForCustomerPortal: ticketDetailsModel?.labelForGroup,
                isRequiredInCustomerPortal: false,
                apiName: DefaultFieldAPIName.group.value,
                isDefaultField: true,
                fieldControlName: FormFieldType.singleLineTextBox.value,
                userCanEdit: false,
                placeholderForCustomerPortal: "",
                text: ticketDetailsModel?.group?.isEmpty == false
                    ? ticketDetailsModel?.group : "--",
                isVisible: ticketDetailsModel?.labelForGroup?.isEmpty == false
                    ? true : false
            ),
            FormFieldModel(
                id: -3,
                labelForCustomerPortal: DefaultFieldName.form.value,
                isRequiredInCustomerPortal: true,
                apiName: DefaultFieldAPIName.form.value,
                isDefaultField: true,
                fieldControlName: FormFieldType.dropdown.value,
                placeholderForCustomerPortal: "Select value",
                isVisible: isEnableMultiForm && isShowFormField
            ),
        ]
    }

    func validateAndSave() -> Bool {
        var isAllValid = true

        for (index, field) in formFieldModel.enumerated() {
            // Skip if hidden or not visible
            if (field.hideInCreateFormCustomerPortal ?? false)
                || !(field.isVisibleInCustomerPortal ?? false)
                || !(field.isVisible ?? true) || !(field.userCanEdit ?? false)
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

    func updateTicket() async {
        guard validateAndSave() else { return }

        do {
            isShowProgress = true
            var finalPayload: [String: Any] = [:]

            for currentField in formFieldModel {
                guard let key = currentField.apiName else { continue }

                if currentField.apiName == DefaultFieldAPIName.form.value
                    && isEnableMultiForm
                {
                    finalPayload["ticketFormId"] = currentField.selectedItem?.id
                    continue
                }

                // Check if original field exists
                if let originalField = existingFormModel.first(where: {
                    $0.id == currentField.id
                }) {
                    let hasChanged =
                        currentField.text != originalField.text
                        || currentField.isChecked != originalField.isChecked
                        || currentField.selectedDate
                            != originalField.selectedDate
                        || currentField.selectedDateTime
                            != originalField.selectedDateTime
                        || currentField.selectedItem?.id
                            != originalField.selectedItem?.id
                        || currentField.selectedItems?.map({ $0.id })
                            != originalField.selectedItems?.map({ $0.id })

                    if hasChanged {
                        let newValue = extractValue(from: currentField)
                        finalPayload[key] = newValue
                    }

                } else {
                    // New field
                    let newValue = extractValue(from: currentField)
                    finalPayload[key] = newValue
                }
            }

            let payload: [String: Any] = ["fields": finalPayload]
            let res = try await ticketDetailsBl.updateTicket(
                ticketId: ticketId,
                formField: payload
            )

            if res.isSuccess {
                if let dataDict = res.data as? [String: Any],
                    let message = dataDict["message"] as? String
                {
                    isRefresh = true
                    ToastManager.shared.show(message, type: .success)
                }
                shouldDismiss = true
            } else if res.statusCode == 400, let data = res.data {
                handleValidationError(data: data)
            } else {
                ErrorLogs.logErrors(data: res.data, isCatchError: false)
            }

        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "updateTicket in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
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
                exceptionPage:
                    "handleValidationError in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
}
