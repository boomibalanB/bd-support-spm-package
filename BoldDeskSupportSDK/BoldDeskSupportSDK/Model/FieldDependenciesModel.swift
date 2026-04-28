import SwiftUI

struct FieldDependencies: Codable {
    let fieldDependencyId: Int
    let parentField: FieldInfo
    let childField: FieldInfo
    let dependencyMapping: [DependencyMapping]
    let parentOptions: [DynamicDropdownModel]
    let childOptions: [DynamicDropdownModel]
}

// MARK: - Field Info (parentField / childField)
struct FieldInfo: Codable {
    let fieldId: Int
    let apiName: String
    let labelForAgentPortal: String
    let labelForCustomerPortal: String
}

// MARK: - Dependency Mapping
struct DependencyMapping: Codable {
    let parentFieldOptionId: Int
    let childFieldOptionId: [Int]
}
