import Foundation

class TicketListBL {
    let apiService = APIService()

    func getTickets(
        page: Int,
        perPage: Int,
        requiresCounts: Bool = true,
        selectedView: String = "",
        statusIdList: String? = nil,
        fields: [String] = ["subject", "createdOn", "statusId", "requesterId"],
        cancellationToken: NetworkCancellationToken? = nil
    ) async throws -> APIResponse {
        // Construct query parameters
        var queryItems: [String: String] = [
            "page": String(page),
            "perPage": String(perPage),
            "requiresCounts": String(requiresCounts),
            "view": String(selectedView),
            "Fields": fields.joined(separator: ",")
        ]
        
        if let statusIdList = statusIdList {
            queryItems["statusIdList"] = statusIdList
        }
        
        // Build the endpoint URL
        let endpointURL = "/support/tickets/list/?" + queryItems.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        // Create a cancellable task
        let task = Task { () -> APIResponse in
            let response = try await apiService.sendAsync(
                endpointURL: endpointURL,
                httpMethod: "get",
                baseURL: AppConstant.baseUrl
            )
            return response
        }
        
        // Set the task in the cancellation token
        cancellationToken?.setTask(task)
        
        // Await the task result
        return try await task.value
    }
    
    func getContactGroups() async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL:"/users/\(UserInfo.userId ?? 0)/contact_groups",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func contactGroupsCanViewTickets() async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL:"/users/contact_groups/can_view_tickets",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
}
