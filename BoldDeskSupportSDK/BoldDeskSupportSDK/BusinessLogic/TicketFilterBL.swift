import Foundation

class TicketFilterBL {
    let apiService = APIService()
    
    func getStatuses(
        requiresCounts: Bool = true,
        cancellationToken: NetworkCancellationToken? = nil
    ) async throws -> APIResponse {
        let queryItems = [
            "requiresCounts": String(requiresCounts)
        ]
        
        let endpointURL = "/ticket_collections/statuses/?" + queryItems.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
        
        let task = Task { () -> APIResponse in
            let response = try await apiService.sendAsync(
                endpointURL: endpointURL,
                httpMethod: "get",
                baseURL: AppConstant.baseUrl
            )
            return response
        }
        
        cancellationToken?.setTask(task)
        return try await task.value
    }
}
