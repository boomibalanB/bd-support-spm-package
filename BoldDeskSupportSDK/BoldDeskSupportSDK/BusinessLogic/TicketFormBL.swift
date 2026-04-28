import Foundation

class TicketFormBL {
    let apiService = APIService()

    func getBrandFormDependency() async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL:
                "/brand_form_dependency/config?needToIncludeDeactivatedForms=false&needToIncludeInvisibleFormsInCustomerPortal=false",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }

    func getTicketFormList(formId: String?, isForCreateForm: Bool = true)
        async throws -> APIResponse
    {
        let res = try await apiService.sendAsync(
            endpointURL: formId != nil
                ? "/forms?isExcludeDefaultFields=true&includeInActiveFields=true&isForCreateForm=\(isForCreateForm)&ticketFormId=\(formId!)"
                : "/forms?isExcludeDefaultFields=true&includeInActiveFields=true&isForCreateForm=\(isForCreateForm)",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }

    func getFieldDependencies() async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: "/field_dependencies/config?isReadOnlyRequired=false",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }

    func getDynamicDropdownItems(apiName: String, searchText: String)
        async throws -> APIResponse
    {
        let res = try await apiService.sendAsync(
            endpointURL: searchText.isEmpty
                ? "/fields/collection/\(apiName)/options?Page=1&PerPage=10&RequiresCounts=true"
                : "/fields/collection/\(apiName)/options?Page=1&PerPage=10&RequiresCounts=true&Filter=\(searchText)",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }

    func getLookUpFieldItems(
        apiName: String,
        lookUpPayload: LookUpFieldConfiguration
    ) async throws -> APIResponse {
        let jsonData = try JSONEncoder().encode(lookUpPayload)
        let res = try await apiService.sendAsync(
            endpointURL:
                "/fields/\(apiName)/look_up_field/collections",
            httpMethod: "POST",
            baseURL: AppConstant.baseUrl,
            body: jsonData
        )
        return res
    }

    func getPriorityItems(searchText: String) async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: searchText.isEmpty
                ? "/ticket_collections/priority/?requiresCounts=true"
                : "/ticket_collections/priority/?requiresCounts=true&filter=\(searchText)",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }

    // MARK: - Main Function (Uses Your apiService)
    func submitTicket(
        formFields: [String: Any],
        isSimpleForm: Bool
    ) async throws -> APIResponse {

        // Step 1: Separate files from text fields
        var textFields: [String: Any] = [:]
        var fileParts: [(name: String, data: Data, filename: String, mimeType: String)] = []

        for (key, value) in formFields {
            // Handle array of files: [[String: Any]]
            if let fileArray = value as? [[String: Any]] {
                for fileDict in fileArray {
                    if let data = fileDict["data"] as? Data,
                       let filename = fileDict["filename"] as? String,
                       let mimeType = fileDict["mimeType"] as? String {
                        fileParts.append(
                            (name: key, data: data, filename: filename, mimeType: mimeType)
                        )
                    }
                }
            } else {
                // Handle empty or nil text field values as "null"
                if let stringValue = value as? String, stringValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    textFields[key] = "null"
                } else if value is NSNull {
                    textFields[key] = "null"
                } else {
                    textFields[key] = value
                }
            }
        }

        // Step 2: Create multipart body
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = MultipartHelper.createMultipartBody(
            parameters: textFields,
            files: fileParts,
            boundary: boundary
        )

        // Step 3: Choose endpoint
        let endpointURL: String
        var baseUrl: String?
        if BDSupportSDK.isFromChatSDK {
            baseUrl = "\(BDSupportSDK.chatData?.brandURL ?? "")/chat_widget"
            endpointURL = "/\(BDSupportSDK.chatData?.appKey ?? "")/create_ticket"
        } else if isSimpleForm {
            endpointURL = "/support/tickets/create_ticket_simple_form"
        } else if AppConstant.authToken.isEmpty {
            endpointURL = "/support/tickets/create_without_login"
        } else {
            endpointURL = "/support/tickets/create"
        }

        // Step 4: Send request
        return try await apiService.sendAsync(
            endpointURL: endpointURL,
            httpMethod: "POST",
            baseURL: baseUrl ?? AppConstant.baseUrl,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
}
extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
