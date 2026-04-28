import Foundation
import SwiftUI

@MainActor
class DislikeFeedbackViewModel: ObservableObject {
    var kbListBL = KnowledgeBaseBL()
    var htmlWebviewModel: HTMLWebViewModel
    @Published var isLoading = false
    @Published var outdatedContentChecked = false
    @Published var improveChecked = false
    @Published var brokenLinksChecked = false
    @Published var moreInformationChecked = false
    @Published var outdatedCodeChecked = false
    @Published var descriptionText: String = ""
    @Published var emailAddress: String = ""
    @Published var errorMessage: String = ""
    @Published var isEmailValid = true
    @Published var canWeContant = false
    @Published var isSuccess: Bool = false
    var isSubmitDisabled: Bool {
        return !outdatedContentChecked && !improveChecked && !brokenLinksChecked
            && !moreInformationChecked && !outdatedCodeChecked
            && descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
    }
    var validation = Validation()

    init(htmlWebviewModel: HTMLWebViewModel) {
        self.htmlWebviewModel = htmlWebviewModel
    }

    func emailVaidation(index: Int, text: String) -> Bool {
        if text.isEmpty {
            isEmailValid = false
            errorMessage = ResourceManager.localized(
                "requiredErrorMessage",
                comment: ""
            )
            return false
        } else if !validation.isValidEmail(text) {
            isEmailValid = false
            errorMessage = ResourceManager.localized(
                "emailNotValidText",
                comment: ""
            )
            return false
        } else {
            isEmailValid = true
            errorMessage = ""
        }
        return true
    }

    func updateCheckBoxValue(index: Int, isChecked: Bool) {
        if index == 0 {
            outdatedContentChecked = !isChecked
        } else if index == 1 {
            improveChecked = !isChecked
        } else if index == 2 {
            brokenLinksChecked = !isChecked
        } else if index == 3 {
            moreInformationChecked = !isChecked
        } else if index == 4 {
            outdatedCodeChecked = !isChecked
        } else if index == 5 {
            canWeContant = !isChecked
        }
    }

    func validateAndSave() -> Bool {
        return emailVaidation(index: 0, text: emailAddress)
    }

    func submitFeedback(articleId: Int) async {
        if validateAndSave() || !AppConstant.authToken.isEmpty {
            isLoading = true
            var payload: [String: Any] = [:]
            if BDSupportSDK.isFromChatSDK {
                payload["isChatWidgetRequest"] = true
            }
            else{
                payload["CanContact"] = canWeContant
            }
            payload["Comment"] = descriptionText
            payload["EmailAddress"] = AppConstant.authToken.isEmpty ? emailAddress : UserInfo.email
            var feedbackMessages: [String] = []
            if outdatedContentChecked {
                feedbackMessages.append(
                    FeedbackContentEnum.outdatedContent.value
                )
            }
            if improveChecked {
                feedbackMessages.append(FeedbackContentEnum.improve.value)
            }
            if brokenLinksChecked {
                feedbackMessages.append(FeedbackContentEnum.brokenLinks.value)
            }
            if moreInformationChecked {
                feedbackMessages.append(
                    FeedbackContentEnum.moreInformation.value
                )
            }
            if outdatedCodeChecked {
                feedbackMessages.append(FeedbackContentEnum.outdatedCode.value)
            }
            payload["FeedbackMessage"] = feedbackMessages
            payload["VoteTypeId"] = 2

            do {
                let response = try await kbListBL.dislikeArticle(
                    articleId: articleId,
                    payload: payload
                )

                if response.isSuccess {
                    htmlWebviewModel.isLikedOrDisliked = true
                    if let data = response.data as? [String: Any],
                        let html = data["message"] as? String
                    {
                        ToastManager.shared.show(html, type: .success)
                        isSuccess = true
                    }
                } else {
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                }
            } catch {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "submitFeedback in DislikeFeedbackViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
            isLoading = false
        }
    }
}
