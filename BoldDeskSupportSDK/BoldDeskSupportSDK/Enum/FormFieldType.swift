enum FormFieldType: String, Codable, CaseIterable, Identifiable {
    case singleLineTextBox = "textbox"
    case multiLineTextBox = "textarea"
    case checkBox = "checkbox"
    case radioButton = "radiobutton"
    case date = "date"
    case datetime = "datetime"
    case numeric = "numeric"
    case decimal = "decimal"
    case dropdown = "dropdown"
    case singleSelectDropdown = "Dropdown (single-select)"
    case multiselect = "multiselect"
    case regex = "regex"
    case url = "url"
    case urlPrefix = "url_prefix"
    case multiselectUrlPrefix = "multiselect_url_prefix"
    case email = "email"
    case domain = "domain"
    case fileUpload = "file_upload"
    case fileSelect = "file_select"
    case tag = "tags"
    case activityTag = "tag"
    case description = "description"
    case autocomplete = "autocomplete"
    case status = "status"
    case userComboBox = "usercombobox"
    case approvalDetails = "approval"
    case subject = "subject"
    case slaOnHold = "sla_on_hold"
    case lookup = "lookup"

    // MARK: - Properties

    var value: String {
        rawValue
    }

    // Conform to Identifiable for SwiftUI
    var id: String {
        rawValue
    }
}
