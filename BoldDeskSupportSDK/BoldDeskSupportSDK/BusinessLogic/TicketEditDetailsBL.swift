import Foundation
class TicketEditDetailBL{
    let apiService = APIService()    
    
    func getTicketProperties(ticketId: String)async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: "/support/tickets/\(ticketId)/ticketproperties/?requiresCounts=true",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }

    
    func updateTicket(ticketId: String, formField: [String: Any])async throws -> APIResponse {
        let jsonData = try JSONSerialization.data(withJSONObject: formField, options: [])
        let res = try await apiService.sendAsync(
            endpointURL: "/support/tickets/\(ticketId)/updatefield",
            httpMethod: "post",
            baseURL: AppConstant.baseUrl,
            body: jsonData
        )
        return res
    }
}
