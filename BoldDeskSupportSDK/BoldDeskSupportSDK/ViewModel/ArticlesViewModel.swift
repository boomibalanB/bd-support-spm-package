import Foundation
import SwiftUI

@MainActor
class ArticlesViewModel : ObservableObject{
    var kbListBL = KnowledgeBaseBL()
    
    // Input params
    private let categoryId: Int
    private let isFormSection: Bool
    
    @Published var isLoading = false
    var articlesCount: Int = 0
    @Published var articlesList: [ArticlesModel] = []
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var isLoadingMore = false
    @Published var shouldShowNoMoreItems = false
    @Published var canLoadMore = false
    var page : Int = 1
    
    private var isInitialLoading = false
    
    
    init(categoryId: Int, isFormSection: Bool) {
        self.categoryId = categoryId
        self.isFormSection = isFormSection
    }
    
    func initiate() {
        Task {
            guard !isInitialLoading else {
                return
            }
            
            isLoading = true
            isInitialLoading = true
            
            if isFormSection {
                async let articles: () = getSectionItems(sectionId: categoryId, page: page)
                _ = await (articles)
            } else {
                async let articles: () = getArticles(categoryId: categoryId, page: page)
                _ = await (articles)
            }

            isLoading = false
        }
    }
    
    func loadMoreTickets(id: Int, isSection: Bool) async{
        isLoadingMore = true
        page += 1
        if isSection{
            await getSectionItems(sectionId: id, page: page)
        }
        else{
            await getArticles(categoryId: id, page: page)
        }
        isLoadingMore = false
    }

    func getArticles(categoryId: Int, page: Int) async {
        do {
            let response = try await kbListBL.getArticlesList(categoryId: categoryId, page: page)
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let articles = rawData["result"] as? [[String: Any]] {
                title = rawData["title"] as? String ?? ""
                description = rawData["description"] as? String ?? ""
                let jsonData = try JSONSerialization.data(withJSONObject: articles)
                let listItems = try JSONDecoder().decode([ArticlesModel].self, from: jsonData)
                shouldShowNoMoreItems = listItems.isEmpty
                canLoadMore = !listItems.isEmpty
                if isLoadingMore {
                    articlesList.append(contentsOf: listItems)
                }
                else{
                    articlesList = listItems
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(data: error,
                                exceptionPage: "getArticles in ArticleViewModel",
                                isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
    
    func getSectionItems(sectionId: Int, page: Int) async {
        do {
            let response = try await kbListBL.getSectionItems(sectionId: sectionId, page: page)
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let articles = rawData["result"] as? [[String: Any]] {
                title = rawData["title"] as? String ?? ""
                description = rawData["description"] as? String ?? ""
                let jsonData = try JSONSerialization.data(withJSONObject: articles)
                let listItems = try JSONDecoder().decode([ArticlesModel].self, from: jsonData)
                shouldShowNoMoreItems = listItems.isEmpty
                canLoadMore = !listItems.isEmpty
                if isLoadingMore {
                    articlesList.append(contentsOf: listItems)
                }
                else{
                    articlesList = listItems
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(data: error, exceptionPage: "getSectionItems in ArticleViewModel", isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
}
