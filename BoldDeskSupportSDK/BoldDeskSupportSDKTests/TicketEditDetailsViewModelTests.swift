import XCTest
@testable import BoldDeskSupportSDK

@MainActor
final class TicketEditDetailsViewModelTests: XCTestCase {

    // Subclass to prevent async network calls during init
    class TestableViewModel: TicketEditDetailsViewModel {
        override func getFieldsAndApplyCondition() async { }
        override func getFormListBasedOnFormId(formId: String?) async { }
        override func getTicketProperties(ticketId: String) async { }
        override func getBrandFormDependency() async { }
        override func getFormFields(formId: String?) async { }
        override func getFieldDependencies() async { }
    }

    func makeField(id: Int, control: String, apiName: String? = nil) -> FormFieldModel {
        return FormFieldModel(
            id: id,
            labelForCustomerPortal: "Label",
            isRequiredInCustomerPortal: false,
            fieldControlName: control,
            apiName: apiName
        )
    }

    func test_updatedEnteredText_and_dates_and_radio_updates() async {
        let vm = TestableViewModel(ticketId: "0")
        vm.formFieldModel = [makeField(id: 1, control: FormFieldType.singleLineTextBox.value)]

        vm.updatedEnteredText(index: 0, text: "hello")
        XCTAssertEqual(vm.formFieldModel[0].text, "hello")

        vm.updateSelectedDate(index: 0, date: "2020-01-01")
        XCTAssertEqual(vm.formFieldModel[0].selectedDate, "2020-01-01")

        vm.updateSelectedDateTime(index: 0, dateTime: "2020-01-01T10:00:00")
        XCTAssertEqual(vm.formFieldModel[0].selectedDateTime, "2020-01-01T10:00:00")

        vm.updateRadioCheckBox(index: 0, isChecked: true)
        XCTAssertEqual(vm.formFieldModel[0].isChecked, false)
    }

    func test_hasFormChanged_detection() async {
        let vm = TestableViewModel(ticketId: "0")
        let original = FormFieldModel(id: 1, labelForCustomerPortal: "L", isRequiredInCustomerPortal: false, fieldControlName: FormFieldType.singleLineTextBox.value)
        vm.existingFormModel = [original]
        vm.formFieldModel = [original]
        XCTAssertFalse(vm.hasFormChanged)

        vm.formFieldModel[0].text = "changed"
        XCTAssertTrue(vm.hasFormChanged)
    }

    func test_validations_date_checkbox_single_multi_and_cc_and_numeric() async {
        let vm = TestableViewModel(ticketId: "0")

        // Date required
        var dateField = makeField(id: 1, control: FormFieldType.date.value)
        dateField.isRequiredInCustomerPortal = true
        vm.formFieldModel = [dateField]
        XCTAssertFalse(vm.dateTimeValidation(index: 0, date: nil))
        XCTAssertFalse(vm.formFieldModel[0].isValid ?? true)

        // Checkbox required
        var cbField = makeField(id: 2, control: FormFieldType.checkBox.value)
        cbField.isRequiredInCustomerPortal = true
        vm.formFieldModel = [cbField]
        XCTAssertFalse(vm.checkBoxValidation(index: 0, isChecked: false))
        XCTAssertFalse(vm.formFieldModel[0].isValid ?? true)

        // Single select required
        var ddField = makeField(id: 3, control: FormFieldType.dropdown.value)
        ddField.isRequiredInCustomerPortal = true
        vm.formFieldModel = [ddField]
        XCTAssertFalse(vm.singleSelectValidation(index: 0, selectedItems: nil))

        // Multi select required
        var msField = makeField(id: 4, control: FormFieldType.multiselect.value)
        msField.isRequiredInCustomerPortal = true
        vm.formFieldModel = [msField]
        XCTAssertFalse(vm.multiSelectValidation(index: 0, selectedItems: []))

        // CC validation - invalid email
        var ccField = makeField(id: 5, control: FormFieldType.singleLineTextBox.value, apiName: "cc")
        ccField.isRequiredInCustomerPortal = false
        vm.formFieldModel = [ccField]
        XCTAssertFalse(vm.ccFieldvalidation(index: 0, selectedItems: ["not-an-email"]))

        // Numeric out of range
        var numField = makeField(id: 6, control: FormFieldType.numeric.value)
        numField.isRequiredInCustomerPortal = true
        numField.additionalFieldValidation = AdditionalFieldValidation(maxValue: 10, minValue: 1, hideActionIcon: nil, numberingFormatTypeId: nil)
        vm.formFieldModel = [numField]
        XCTAssertFalse(vm.textFieldValidation(index: 0, text: "20"))
    }

    func test_validateAndSave_combines_field_validations() async {
        let vm = TestableViewModel(ticketId: "0")

        var f1 = makeField(id: 1, control: FormFieldType.singleLineTextBox.value)
        f1.isRequiredInCustomerPortal = true
        f1.text = ""

        vm.formFieldModel = [f1]
        XCTAssertFalse(vm.validateAndSave())

        vm.formFieldModel[0].text = "filled"
        XCTAssertTrue(vm.validateAndSave())
    }
}
