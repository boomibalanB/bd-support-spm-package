import Foundation

class KnowledgeBaseBL {
    let apiService = APIService()
    
    func getCategoryList()async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: "/kb/categories?Page=1&PerPage=100&RequiresCounts=true",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func getPopularArticlesList()async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: "/kb/popular_articles?Page=1&PerPage=10",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    func getArticlesList(categoryId: Int, page: Int)async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: "/kb/section_article/list?categoryId=\(categoryId)&Page=\(page)&PerPage=20&RequiresCounts=true",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func getSectionItems(sectionId: Int, page: Int)async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: "/kb/section_article/list?sectionId=\(sectionId)&Page=\(page)&PerPage=20&RequiresCounts=true",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func getKbHTMLContent(articleId: Int, articleName: String) async throws
        -> APIResponse
    {
        let res = try await apiService.sendAsync(
            endpointURL: BDSupportSDK.isFromChatSDK
            ? "/widget/\(BDSupportSDK.chatData?.appKey ?? "")/article/\(articleId)?&isChatWidgetRequest=true"
                : "/kb/article/\(articleId)/\(articleName)?isInternalRefresh=false&canRedirectUrl=true",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func searchArticles(categoryId: Int?, searchText: String)async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL: categoryId != nil ?
            "/kb/search/\(searchText)/?requiresCounts=true&categoryids=\(categoryId!)&page=1&perPage=100"
            : "/kb/search/\(searchText)/?requiresCounts=true&page=1&perPage=100",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
    
    func getCategoryItems(searchText: String)async throws -> APIResponse {
        let res = try await apiService.sendAsync(
            endpointURL:  searchText.isEmpty ?
            "/kb/categories/collection/?requiresCounts=true" : "/kb/categories/collection/?requiresCounts=true&filter=\(searchText)",
            httpMethod: "get",
            baseURL: AppConstant.baseUrl
        )
        return res
    }
   
    func likeArticle(articleId: Int)async throws -> APIResponse {
        var payload: [String: Any] = [
            "VoteTypeId": 1
        ]
        if BDSupportSDK.isFromChatSDK {
            payload["isChatWidgetRequest"] = true
        }
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        let res = try await apiService.sendAsync(
            endpointURL: BDSupportSDK.isFromChatSDK
            ? "/widget/\(BDSupportSDK.chatData?.appKey ?? "")/article/\(articleId)/satisfaction_feedback"
            : "/kb/article/\(articleId)/satisfaction_feedback",
            httpMethod: "post",
            baseURL: AppConstant.baseUrl,
            body: jsonData
        )
        return res
    }
    
    func dislikeArticle(articleId: Int, payload: [String: Any])async throws -> APIResponse {
        let jsonData = try JSONSerialization.data(withJSONObject: payload, options: [])
        let res = try await apiService.sendAsync(
            endpointURL: BDSupportSDK.isFromChatSDK
            ? "/widget/\(BDSupportSDK.chatData?.appKey ?? "")/article/\(articleId)/satisfaction_feedback"
            : "/kb/article/\(articleId)/satisfaction_feedback",
            httpMethod: "post",
            baseURL: AppConstant.baseUrl,
            body: jsonData
        )
        return res
    }
}
