import Foundation
import SwiftUI

@MainActor
class KnowledgeBaseSearchViewModel : ObservableObject{
    var kbListBL = KnowledgeBaseBL()
    @Published var searchArticleList: [SearchArticleModel] = []
    @Published var searchText = ""
    @Published var isLoading: Bool = false
    @Published var noItemsFound: Bool = false
    @Published var selectedItem: DropdownItemModel?
    private var cancellationToken: NetworkCancellationToken?
    private var searchTask: Task<Void, Never>?
    private var dropdownItems: [DropdownItemModel] = []
    var selectedCategoryId: Int? {
        if let id = selectedItem?.id {
            return id == 0 ? nil : id
        }
        return nil
    }
    func searchArticles() async {
        isLoading = true
        searchTask?.cancel()
        cancellationToken?.cancel()
        cancellationToken = NetworkCancellationToken()
        searchTask = Task {
            guard !Task.isCancelled else { return }
            if searchText.isEmpty {
                searchArticleList = []
                isLoading = false
                return
            }
            do {
                let response = try await kbListBL.searchArticles(categoryId: selectedCategoryId, searchText: searchText)
                
                if response.isSuccess,
                   let rawData = response.data as? [String: Any],
                   let rawJSONString = rawData["raw"] as? String,
                   let jsonData = rawJSONString.data(using: .utf8) {
                    let searchResults = try JSONDecoder().decode([SearchArticleModel].self, from: jsonData)
                    if !searchResults.isEmpty {
                        searchArticleList = searchResults
                        noItemsFound  = false
                    }
                    else{
                        noItemsFound  = true
                    }
                    isLoading = false
                }
                else {
                    ErrorLogs.logErrors(data: response.data, isCatchError: false)
                }
            } catch {
                isLoading = false
                ErrorLogs.logErrors(data: error,
                                    exceptionPage: "searchArticles in KnowledgeBaseSearchViewModel",
                                    isCatchError: true,
                                    statusCode: 500,
                                    stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
                
            }
        }
    }
    
    func clearSearch(){
        searchText = ""
    }
    
    func updateSelectedItem(index: Int, selectedItem: DropdownItemModel?) {
        self.selectedItem = selectedItem
    }
    
    func getCategoryItems(index: Int, searchText: String) async -> [DropdownItemModel] {
        dropdownItems = []
        do {
            let response = try await kbListBL.getCategoryItems(searchText: searchText)
            
            if response.isSuccess {
                if let rawData = response.data as? [String: Any],
                   let resultArray = rawData["result"] as? [[String: Any]] {
                    let jsonData = try JSONSerialization.data(withJSONObject: resultArray)
                    let decodedItems = try JSONDecoder().decode([DynamicDropdownModel].self, from: jsonData)
                    decodedItems.forEach { item in
                        dropdownItems.append(DropdownItemModel(
                            id: item.id ?? 0,
                            itemName: item.name ?? "",
                            displayName: item.name ?? ""
                        ))
                    }
                }
            }
            else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        }
        catch {
            ErrorLogs.logErrors(data: error,
                                exceptionPage: "getCategoryItems in KnowledgeBaseSearchViewModel",
                                isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
            
        }
        
        if searchText.isEmpty {
            dropdownItems.insert(DropdownItemModel(id: 0, itemName: "All Categories", displayName: "All Categories"), at: 0)
        }
        return dropdownItems
    }
}
