import Foundation
import SwiftUI

@MainActor
class SingleSelectViewModel: ObservableObject {
    @Published var items: [DropdownItemModel] = []
    @Published var isLoading: Bool = false
    @Published var selectedItem: DropdownItemModel?
    private var currentSearchTask: Task<Void, Never>?
    
    var fetchItemsAPI: ((Int, String) async -> [DropdownItemModel])
    
    init(fetchItemsAPI: @escaping (Int, String) async -> [DropdownItemModel], selectedItem: DropdownItemModel?) {
        self.fetchItemsAPI = fetchItemsAPI
        self.selectedItem = selectedItem
    }
    
    func loadItems(index: Int, search: String = "") async {
        currentSearchTask?.cancel()
        
        currentSearchTask = Task {
            isLoading = true
            
            // Use Task cancellation to handle aborted fetches
            guard !Task.isCancelled else {
//                isLoading = false
                return
            }
            
            let result = await fetchItemsAPI(index, search)
            
            guard !Task.isCancelled else {
//                isLoading = false
                return
            }
            
            self.items = result
            
            if search.isEmpty, let selected = selectedItem, result.contains(selected) {
                let others = result.filter { $0 != selected }
                self.items = [selected] + others
            } else {
                self.items = result
            }
            isLoading = false
        }
    }
}
