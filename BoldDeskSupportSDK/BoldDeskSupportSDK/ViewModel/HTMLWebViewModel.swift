import Foundation
import SwiftUI

@MainActor
class HTMLWebViewModel: ObservableObject {
    var kbListBL = KnowledgeBaseBL()
    @Published var isLoading = false
    @Published var kbHTMLContent: String = ""
    @Published var kbTitle: String = ""
    @Published var isLikedOrDisliked = false
    var validation = Validation()

    init(isDisabled: Bool = false, articleId: Int, articleName: String) {
        Task {
            isLoading = true
            guard !isDisabled else {
                isLoading = true
                return
            }
            await getKbHTMLContent(
                articleId: articleId,
                articleName: articleName
            )
            isLoading = false
        }
    }

    func getKbHTMLContent(articleId: Int, articleName: String) async {

        do {
            let response = try await kbListBL.getKbHTMLContent(
                articleId: articleId,
                articleName: articleName.toSlug()
            )

            if let data = response.data as? [String: Any],
               let articleDetails = BDSupportSDK.isFromChatSDK
                ? data["result"] as? [String: Any]
                : data["kbArticleDetailsResult"] as? [String: Any]
            {
                // title
                let title = articleDetails["title"] as? String ?? ""

                // description / HTML content
                let htmlContent = articleDetails["description"] as? String ?? ""

                // assign to your @Published property
                kbHTMLContent = htmlContent
                kbTitle = title
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "getkbHTMLContent in HTMLWebViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    func likeArticle(articleId: Int) async {

        do {
            guard !isLikedOrDisliked else {
                ToastManager.shared.show("Votted already", type: .error)
                return
            }
            let response = try await kbListBL.likeArticle(articleId: articleId)

            if response.isSuccess {
                if let data = response.data as? [String: Any],
                    let html = data["message"] as? String
                {
                    isLikedOrDisliked = true
                    ToastManager.shared.show(html, type: .success)
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "likeArticle in HTMLWebViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
}

extension String {
    func toSlug() -> String {
        return
            self
            .lowercased()  // Lowercase all letters
            .trimmingCharacters(in: .whitespacesAndNewlines)  // Trim whitespace
            .replacingOccurrences(
                of: "[^a-z0-9]+",
                with: "-",
                options: .regularExpression
            )  // Replace spaces/punctuation with "-"
            .trimmingCharacters(in: CharacterSet(charactersIn: "-"))  // Remove leading/trailing "-"
    }
}
