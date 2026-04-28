import Foundation
import SwiftUI
import Combine

class MessageListViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var totalMessagesCount: Int = 0
    
    private let messageBL = MessageListBL()
    private let ticketDetailBL = TicketDetailBL()
    private var currentPage = 1
    private let itemsPerPage = 5
    private var cancellationToken: NetworkCancellationToken?
    
    private let ticketId: Int
    
    init(ticketId: Int) {
        self.ticketId = ticketId
    }
    
    
    var canLoadMore: Bool {
        return messages.count < totalMessagesCount
    }
    
    var shouldShowNoMoreItems: Bool {
        return !messages.isEmpty &&
               messages.count >= totalMessagesCount &&
               totalMessagesCount > 0 &&
               !isLoadingMore &&
               !isLoading &&
               totalMessagesCount > itemsPerPage
    }
    
    @MainActor
    func loadMessages(isRefresh: Bool = false) async {
        guard !isLoading && !isLoadingMore else { return }
        
        if isRefresh {
            cancellationToken?.cancel()
            cancellationToken = NetworkCancellationToken()
        }
        
        isLoading = true
        hasError = false
        errorMessage = nil
        
        if isRefresh {
            messages = []
            totalMessagesCount = 0
        }
        
        defer {
            print("Loaded messages: \(messages.count) of \(totalMessagesCount)")
            isLoading = false
        }
        
        do {
            let response = try await messageBL.getMessages(
                ticketId: ticketId,
                page: 1,
                perPage: itemsPerPage,
                cancellationToken: isRefresh ? cancellationToken : nil
            )
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any] {
                
                let jsonData = try JSONSerialization.data(withJSONObject: rawData)
                let decodedResponse = try JSONDecoder().decode(MessageResponse.self, from: jsonData)
                
                messages = decodedResponse.ticketUpdates
                totalMessagesCount = decodedResponse.totalListCount
                if !messages.isEmpty {
                    messages[messages.count - 1].isLastMessage = true
                }
                currentPage = 1
                
            } else {
                if !(response.statusCode == 417) {
                    ErrorLogs.logErrors(data: response.data, isCatchError: false)
                }
            }
        } catch {
            ErrorLogs.logErrors(data: error,
                                exceptionPage: "loadMessages in MessageListViewModel",
                                isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
    
    @MainActor
    func loadMoreMessages() async {
        guard !isLoadingMore && !isLoading && canLoadMore else { return }
        
        isLoadingMore = true
        
        defer {
            print("Total messages after load more: \(messages.count) of \(totalMessagesCount)")
            isLoadingMore = false
        }
        
        do {
            let response = try await messageBL.getMessages(
                ticketId: ticketId,
                page: currentPage + 1,
                perPage: itemsPerPage
            )
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any] {
                
                let jsonData = try JSONSerialization.data(withJSONObject: rawData)
                let decodedResponse = try JSONDecoder().decode(MessageResponse.self, from: jsonData)
                
                guard !decodedResponse.ticketUpdates.isEmpty else { return }
                
                messages.append(contentsOf: decodedResponse.ticketUpdates)
                totalMessagesCount = decodedResponse.totalListCount
                if !messages.isEmpty {
                    messages[messages.count - 1].isLastMessage = true
                }
                currentPage += 1
                
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(data: error,
                                exceptionPage: "loadMoreMessages in MessageListViewModel",
                                isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
    
    func retryLastOperation() {
        Task {
            if messages.isEmpty {
                await loadMessages()
            } else {
                await loadMessages(isRefresh: true)
            }
        }
    }
    
    deinit {
        cancellationToken?.cancel()
    }
}
