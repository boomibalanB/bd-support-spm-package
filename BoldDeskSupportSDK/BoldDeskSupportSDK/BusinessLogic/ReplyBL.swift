import Foundation

class ReplyBL {
    let apiService = APIService()
    
    // MARK: - Update Reply (Multipart with Attachments)
    func updateReply(
        ticketId: Int,
        replyText: String,
        isClosed: Bool,
        statusId: Int,
        attachments: [(name: String, data: Data, filename: String, mimeType: String)] = []
    ) async throws -> APIResponse {
        
        // Step 1: Create parameters (text fields)
        let parameters: [String: Any] = [
            "Description": replyText,
            "IsClosed": isClosed,
            "TicketStatusId": statusId,
            "FileSharingAttachment": "",
            "UpdatedBy": UserInfo.userId ?? 0
        ]
        
        let boundary = "Boundary-\(UUID().uuidString)"
        let body = MultipartHelper.createMultipartBody(
            parameters: parameters,
            files: attachments,
            boundary: boundary
        )
        
        // Step 3: Send multipart/form-data request
        return try await apiService.sendAsync(
            endpointURL: "/support/tickets/\(ticketId)/updates",
            httpMethod: "POST",
            baseURL: AppConstant.baseUrl,
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }
}
