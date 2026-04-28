import Foundation

class MessageListBL {
    let apiService = APIService()
    
    func getMessages(
        ticketId: Int,
        page: Int,
        perPage: Int,
        requiresCounts: Bool = true,
        cancellationToken: NetworkCancellationToken? = nil
    ) async throws -> APIResponse {
        
        let queryItems: [String: String] = [
            "page": String(page),
            "perPage": String(perPage),
            "orderby" : "createdOn desc",
            "requiresCounts": String(requiresCounts),
        ]
        
        let queryString = queryItems.map { key, value in
            let encodedValue = value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? value
            return "\(key)=\(encodedValue)"
        }.joined(separator: "&")

        let endpointURL = "/support/tickets/\(ticketId)/updates/?" + queryString
        
        let task = Task { () -> APIResponse in
            let response = try await apiService.sendAsync(
                endpointURL: endpointURL,
                httpMethod: "GET",
                baseURL: AppConstant.baseUrl
            )
            return response
        }
        
        cancellationToken?.setTask(task)
        
        return try await task.value
    }
    
}
