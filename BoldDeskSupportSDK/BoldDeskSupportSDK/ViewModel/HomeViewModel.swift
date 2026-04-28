import Foundation
import SwiftUI

class HomeViewModel: ObservableObject {
    @Published var recentTickets: [Ticket] = []
    @Published var isLoading: Bool = false
    @Published var hasError: Bool = false

    private let ticketBL = TicketListBL()
    private let itemsPerPage = 3

    @MainActor
    func loadInitialTickets() async {
        
        isLoading = true
        hasError = false
        defer { isLoading = false }

        do {
            let response = try await ticketBL.getTickets(
                page: 1,
                perPage: itemsPerPage,
                selectedView: "my-tickets"
            )

            if response.isSuccess,
               let rawData = response.data as? [String: Any]
            {
                if let ticketItems = rawData["result"] as? [[String: Any]],
                   !ticketItems.isEmpty
                {
                    let jsonData = try JSONSerialization.data(
                        withJSONObject: rawData
                    )
                    let ticketResponse = try JSONDecoder().decode(
                        TicketResponse.self,
                        from: jsonData
                    )
                    recentTickets = ticketResponse.result
                } else {
                    recentTickets = []
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            hasError = true
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "loadInitialTickets in HomeViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
}
