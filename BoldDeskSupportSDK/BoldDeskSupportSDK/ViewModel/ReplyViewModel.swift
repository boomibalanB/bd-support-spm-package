import Foundation
import Combine
import SwiftUI

@MainActor
class ReplyViewModel: ObservableObject {
    @Published var replyText: String = ""
    @Published var isInProgress: Bool = false
    @Published var errorMessage: String?
    @Published var attachmentCount: Int = 0
    @Published var pickedAttachments: [PickedMediaInfo] = []
    
    let dismissPublisher = PassthroughSubject<Bool, Never>()
    
    private let ticketId: Int
    private let statusId: Int
    private let replyBL = ReplyBL()
    
    init(ticketId: Int, statusId: Int) {
        self.ticketId = ticketId
        self.statusId = statusId
    }
    
    func validateAndUpdateReply(
        shouldCloseTicket: Bool,
        shouldRefreshDetails: Bool? = nil
    ) async {
        guard validateReplyText() else { return }
        await updateReply(shouldCloseTicket: shouldCloseTicket, shouldRefreshDetails: shouldRefreshDetails)
    }
    
    func validateReplyText(showToast: Bool = true) -> Bool {
        let trimmed = replyText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            if showToast {
                ToastManager.shared.show(
                    ResourceManager.localized("replyRequiredText", comment: ""),
                    type: .error
                )
            }
            return false
        }
        return true
    }
    
    private func updateReply(
        shouldCloseTicket: Bool,
        shouldRefreshDetails: Bool? = nil
    ) async {
        isInProgress = true
        errorMessage = nil
        
        do {
            
            var files: [(name: String, data: Data, filename: String, mimeType: String)] = []
            for item in pickedAttachments {
                if let fileURL = item.file {
                    do {
                        let data = try Data(contentsOf: fileURL)
                        let mimeType = MultipartHelper.mimeType(from: fileURL)
                        files.append((
                            name: "File",
                            data: data,
                            filename: fileURL.lastPathComponent,
                            mimeType: mimeType
                        ))
                    } catch {
                        print("Failed to read file data: \(error)")
                    }
                }
            }
            
            let response = try await replyBL.updateReply(
                ticketId: ticketId,
                replyText: processHTMLText(replyText),
                isClosed: shouldCloseTicket,
                statusId: statusId,
                attachments: files
            )
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let message = rawData["result"] as? String {
                ToastManager.shared.show(message, type: .success)
                dismissPublisher.send(shouldCloseTicket || (shouldRefreshDetails ?? false))
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "updateReply in ReplyViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }

        isInProgress = false
    }
    
    private func processHTMLText(_ input: String) -> String {
        do {
            var htmlText = input.replacingOccurrences(of: "\n", with: "<br>")

            let pattern = #"https?://[^\s<>"'`]+"#
            let regex = try NSRegularExpression(pattern: pattern, options: [])

            let range = NSRange(htmlText.startIndex..<htmlText.endIndex, in: htmlText)
            htmlText = regex.stringByReplacingMatches(
                in: htmlText,
                options: [],
                range: range,
                withTemplate: "<a href=\"$0\">$0</a>"
            )
            return htmlText
        } catch {
            return input
        }
    }
}
