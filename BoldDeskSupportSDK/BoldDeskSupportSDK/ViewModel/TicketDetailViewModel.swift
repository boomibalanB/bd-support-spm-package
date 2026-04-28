import Foundation
import SwiftUI

@MainActor
class TicketDetailViewModel: ObservableObject {
    @Published var ticketDetails: TicketDetailObject?
    @Published var isLoading = true
    @Published var errorMessage: String?
    @Published var isInProgress: Bool = false
    @Published var isShowEditSubject: Bool = false
    @Published var isUpdatingSubject: Bool = false
    @Published var isShowAccessDeniedPage: Bool = false
    @Published private(set) var hasLoaded = false
    @Published var isMyOrgTicket: Bool = false
    
    var ticketDetailsModel: TicketDetailModel?
    private let ticketDetailBL = TicketDetailBL()
    private let ticketEditDetailBL = TicketEditDetailBL()
    private var cancellationToken: NetworkCancellationToken?
    private let ticketId: Int

    init(ticketId: Int) {
        self.ticketId = ticketId
    }

    func loadTicketDetails(force: Bool = false) async {

        guard force || !hasLoaded else { return }
        isLoading = true
        errorMessage = nil
        cancellationToken = NetworkCancellationToken()

        do {
            AppConstant.fileToken = nil
            let response = try await ticketDetailBL.getTicketDetails(
                ticketId: ticketId,
                cancellationToken: cancellationToken
            )
            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                rawData["ticketDetails"] as? [String: Any] != nil
            {

                let jsonData = try JSONSerialization.data(
                    withJSONObject: rawData
                )
                let decoded = try JSONDecoder().decode(
                    TicketDetailResponse.self,
                    from: jsonData
                )

                ticketDetails = decoded.ticketDetails
                AppConstant.fileToken = ticketDetails?.dataToken
                print("File Token: \(AppConstant.fileToken ?? "nil")")
                hasLoaded = true
            } else {
                if response.statusCode == 417 {
                    isShowAccessDeniedPage = true
                } else {
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                }
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "loadTicketDetails in TicketDetailViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }

        isLoading = false
    }

    func closeTicket() async {
        isInProgress = true
        errorMessage = nil
        do {
            let response = try await ticketDetailBL.closeTicket(
                ticketId: ticketId
            )

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let message = rawData["message"] as? String
            {
                ToastManager.shared.show(message, type: .success)
                isInProgress = false
                await loadTicketDetails(force: true)
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ToastManager.shared.show(error.localizedDescription, type: .error)
        }
        isInProgress = false
    }

    func deleteDescription() async {
        isInProgress = true
        errorMessage = nil
        do {
            let response = try await ticketDetailBL.deleteTicketDescription(
                ticketId: ticketId,
                descriptionId: ticketDetails?.commentId ?? 0
            )

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let message = rawData["message"] as? String
            {
                ToastManager.shared.show(message, type: .success)
                isInProgress = false
                await loadTicketDetails(force: true)
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ToastManager.shared.show(error.localizedDescription, type: .error)
        }
        isInProgress = false
    }

    @MainActor
    func deleteTicketAttachment(
        attachmentId: Int,
        isMessageAttachment: Bool = false,
        onAttachmentDeleted: (() -> Void)? = nil
    ) async {
        isInProgress = true
        errorMessage = nil

        do {
            let response = try await ticketDetailBL.deleteTicketAttachment(
                ticketId: ticketId,
                attachmentId: attachmentId
            )

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let message = rawData["message"] as? String
            {

                ToastManager.shared.show(message, type: .success)

                if isMessageAttachment {
                    onAttachmentDeleted?()
                } else {
                    await loadTicketDetails(force: true)
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ToastManager.shared.show(error.localizedDescription, type: .error)
        }
        isInProgress = false
    }

    @MainActor
    func deleteMessage(
        messageId: Int,
        onMessageDeleted: (() -> Void)? = nil
    ) async {
        isInProgress = true
        errorMessage = nil

        do {
            let response = try await ticketDetailBL.deleteMessage(
                ticketId: ticketId,
                messageId: messageId
            )

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let message = rawData["message"] as? String
            {
                ToastManager.shared.show(message, type: .success)
                onMessageDeleted?()
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ToastManager.shared.show(error.localizedDescription, type: .error)
        }
        isInProgress = false
    }

    func updateSubject(newSubject: String) async {
        isInProgress = true
        errorMessage = nil

        do {
            let response = try await ticketDetailBL.updateSubject(
                ticketId: ticketId,
                newSubject: newSubject
            )

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let message = rawData["message"] as? String
            {
                ToastManager.shared.show(message, type: .success)
                isInProgress = false
                await loadTicketDetails(force: true)
                isInProgress = false
            } else {
                isInProgress = false
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ToastManager.shared.show(error.localizedDescription, type: .error)
        }
        isInProgress = false
    }
    
    @MainActor
    func getTicketProperties(ticketId: String) async {

        do {
            let response = try await ticketEditDetailBL.getTicketProperties(
                ticketId: ticketId
            )

            if response.isSuccess {
                if let rawData = response.data as? [String: Any],
                    let ticketJson = rawData["result"] as? [String: Any]
                {

                    let jsonData = try JSONSerialization.data(
                        withJSONObject: ticketJson,
                        options: []
                    )

                    let decoded = try await Task.detached {
                        try JSONDecoder().decode(
                            TicketDetailModel.self,
                            from: jsonData
                        )
                    }.value
                    ticketDetailsModel = decoded
                    isMyOrgTicket = ticketDetailsModel?.contactGroup != nil
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage:
                    "getTicketProperties in TicketEditDetailsViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    func cancelRequest() {
        cancellationToken?.cancel()
    }

    deinit {
        cancellationToken?.cancel()
    }
}
