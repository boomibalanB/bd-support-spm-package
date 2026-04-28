enum AssigneeOption: String {
    case autoAssign = "Auto Assign"
    case selectAgent = "Select Agent"
    
    var value: String {
        rawValue
    }
}

enum CustomField: Hashable {
    case name, email, number, decimal, decription
}
