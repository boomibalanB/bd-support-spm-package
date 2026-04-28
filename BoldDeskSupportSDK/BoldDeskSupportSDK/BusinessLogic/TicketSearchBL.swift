import Foundation

class TicketSearchBL {
    let apiService = APIService()
    
    func searchTickets(
            searchQuery: String,
            page: Int,
            perPage: Int,
            cancellationToken: NetworkCancellationToken? = nil
        ) async throws -> APIResponse {
            
            let queryItems: [String: String] = [
                "search": searchQuery,
                "page": String(page),
                "perPage": String(perPage)
            ]
            
            let endpointURL = "/support/tickets/fetchList/?" + queryItems.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
            
            let task = Task { () -> APIResponse in
                if Task.isCancelled {
                    throw CancellationError()
                }

                let response = try await apiService.sendAsync(
                    endpointURL: endpointURL,
                    httpMethod: "get",
                    baseURL: AppConstant.baseUrl
                )

                if Task.isCancelled {
                    throw CancellationError()
                }

                return response
            }
            
            cancellationToken?.setTask(task)
            
            return try await task.value
        }
    
}
