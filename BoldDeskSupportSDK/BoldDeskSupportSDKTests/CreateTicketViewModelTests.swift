import XCTest
@testable import BoldDeskSupportSDK

final class CreateTicketViewModelTests: XCTestCase {

    private func makeField(
        id: Int = 1,
        apiName: String,
        controlName: String,
        required: Bool,
        text: String? = nil
    ) -> FormFieldModel {
        return FormFieldModel(
            id: id,
            labelForCustomerPortal: "",
            isRequiredInCustomerPortal: required,
            apiName: apiName,
            isDefaultField: false,
            fieldControlName: controlName,
            placeholderForCustomerPortal: "",
            text: text
        )
    }

    @MainActor func testAdjustEmailPhoneRequirement_emailValid_makesPhoneOptional() {
        let vm = CreateTicketViewModel(isDisabled: true)

        let emailField = makeField(apiName: "EmailAddress", controlName: FormFieldType.email.value, required: true, text: "test@example.com")
        let phoneField = makeField(apiName: "PhoneNumber", controlName: FormFieldType.singleLineTextBox.value, required: true, text: "")

        vm.formFieldModel = [emailField, phoneField]

        vm.adjustEmailPhoneRequirement()

        let emailIndex = vm.formFieldModel.firstIndex { $0.apiName == "EmailAddress" }!
        let phoneIndex = vm.formFieldModel.firstIndex { $0.apiName == "PhoneNumber" }!

        XCTAssertTrue(vm.formFieldModel[emailIndex].isRequiredInCustomerPortal ?? false, "Email should remain required when valid email present")
        XCTAssertFalse(vm.formFieldModel[phoneIndex].isRequiredInCustomerPortal ?? true, "Phone should become optional when email is valid")
    }

    @MainActor func testAdjustEmailPhoneRequirement_phoneValid_makesEmailOptional() {
        let vm = CreateTicketViewModel(isDisabled: true)

        let emailField = makeField(apiName: "EmailAddress", controlName: FormFieldType.email.value, required: true, text: "")
        let phoneField = makeField(apiName: "PhoneNumber", controlName: FormFieldType.singleLineTextBox.value, required: true, text: "+14155550100")

        vm.formFieldModel = [emailField, phoneField]

        vm.adjustEmailPhoneRequirement()

        let emailIndex = vm.formFieldModel.firstIndex { $0.apiName == "EmailAddress" }!
        let phoneIndex = vm.formFieldModel.firstIndex { $0.apiName == "PhoneNumber" }!

        XCTAssertFalse(vm.formFieldModel[emailIndex].isRequiredInCustomerPortal ?? true, "Email should become optional when phone is valid")
        XCTAssertTrue(vm.formFieldModel[phoneIndex].isRequiredInCustomerPortal ?? false, "Phone should remain required when valid phone present")
    }

    @MainActor func testValidateForm_requiredTextEmpty_returnsFalse() {
        let vm = CreateTicketViewModel(isDisabled: true)

        // required subject field but empty
        let subject = FormFieldModel(
            id: -4,
            labelForCustomerPortal: "subject",
            isRequiredInCustomerPortal: true,
            apiName: "subject",
            isDefaultField: true,
            fieldControlName: FormFieldType.singleLineTextBox.value,
            placeholderForCustomerPortal: "",
            text: ""
        )

        vm.formFieldModel = [subject]

        XCTAssertFalse(vm.validateForm(), "validateForm should fail when required text fields are empty")
    }

    @MainActor func testValidateForm_ccInvalidEmail_returnsFalse() {
        let vm = CreateTicketViewModel(isDisabled: true)

        let ccField = makeField(apiName: "cc", controlName: FormFieldType.singleLineTextBox.value, required: true, text: "")
        vm.formFieldModel = [ccField]
        vm.ccFieldvalues = ["not-an-email"]

        XCTAssertFalse(vm.validateForm(), "validateForm should fail for invalid cc email addresses")
    }
}
