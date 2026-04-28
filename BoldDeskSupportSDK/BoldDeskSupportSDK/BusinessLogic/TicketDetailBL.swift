import Foundation

class TicketDetailBL{
    let apiService = APIService()
    
    func closeTicket(ticketId: Int)async throws -> APIResponse {
        let body = try JSONSerialization.data(withJSONObject: [:])
        let res = try await apiService.sendAsync(
            endpointURL: "/support/tickets/\(ticketId)/close_ticket",
            httpMethod: "POST",
            baseURL: AppConstant.baseUrl,
            body: body
        )
        return res
    }
    
    func deleteTicketDescription(ticketId: Int, descriptionId: Int) async throws -> APIResponse {
        let endpoint = "/support/tickets/\(ticketId)/updates/\(descriptionId)"
        
        let res = try await apiService.sendAsync(
            endpointURL: endpoint,
            httpMethod: "DELETE",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func deleteTicketAttachment(ticketId: Int, attachmentId: Int) async throws -> APIResponse {
        let endpoint = "/support/tickets/\(ticketId)/attachments/\(attachmentId)"
        
        let res = try await apiService.sendAsync(
            endpointURL: endpoint,
            httpMethod: "DELETE",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func updateSubject(ticketId: Int, newSubject: String) async throws -> APIResponse {
        let payload: [String: Any] = [
            "fields": [
                "subject": newSubject
            ]
        ]
        
        let body = try JSONSerialization.data(withJSONObject: payload, options: [])
        
        let res = try await apiService.sendAsync(
            endpointURL: "/support/tickets/\(ticketId)/updatesubject",
            httpMethod: "POST",
            baseURL: AppConstant.baseUrl,
            body: body
        )
        
        return res
    }

    func getTicketDetails(
        ticketId: Int,
        cancellationToken: NetworkCancellationToken? = nil
    ) async throws -> APIResponse {
        let endpointURL = "/support/tickets/\(ticketId)"
        
        let res = try await apiService.sendAsync(
            endpointURL: endpointURL,
            httpMethod: "GET",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func deleteMessage(ticketId: Int, messageId: Int) async throws -> APIResponse {
        let endpoint = "/support/tickets/\(ticketId)/updates/\(messageId)"
        
        let res = try await apiService.sendAsync(
            endpointURL: endpoint,
            httpMethod: "DELETE",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
}

