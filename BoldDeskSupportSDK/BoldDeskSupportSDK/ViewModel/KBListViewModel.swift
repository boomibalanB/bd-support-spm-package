import Foundation
import SwiftUI

@MainActor
class KBListViewModel : ObservableObject{
    var kbListBL = KnowledgeBaseBL()
    @Published var category: [CategoryKB] = []
    @Published var popularArticle: [PopularArticleModel] = []
    @Published var isInitialLoading: Bool = false
    var categoryCount: Int = 0
    @Published var isLoading: Bool = true
    
    func initiate() {
        Task {
            guard !isInitialLoading else {
                return
            }
            
            isLoading = true
            isInitialLoading = true
            
            async let categories: () = getCategories()
            async let articles: () = getPopularArticles()
            // Wait for both to finish
            _ = await (categories, articles)
            isLoading = false
        }
    }

    func getCategories() async {
        defer {
            print("count of category: \(categoryCount)")
        }
        
        do {
            let response = try await kbListBL.getCategoryList()
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let categoryItems = rawData["categorylist"] as? [[String: Any]],
               !categoryItems.isEmpty {
                if let count = rawData["count"] as? Int {
                    categoryCount = count
                }
                let jsonData = try JSONSerialization.data(withJSONObject: categoryItems)
                category = try JSONDecoder().decode([CategoryKB].self, from: jsonData)
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(data: error, exceptionPage: "getCategories in KBListViewModel", isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
    
    func getPopularArticles() async {
        defer {
            print("count of category: \(categoryCount)")
        }
        
        do {
            let response = try await kbListBL.getPopularArticlesList()
            
            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let articleList = rawData["articleList"] as? [[String: Any]],
               !articleList.isEmpty {
                let jsonData = try JSONSerialization.data(withJSONObject: articleList)
                popularArticle = try JSONDecoder().decode([PopularArticleModel].self, from: jsonData)
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(data: error, exceptionPage: "getPopularArticles in KBListViewModel", isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
}
