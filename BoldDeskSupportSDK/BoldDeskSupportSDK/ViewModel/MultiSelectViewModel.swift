import Foundation
import SwiftUI

@MainActor
class MultiSelectViewModel: ObservableObject {
    @Published var items: [DropdownItemModel] = []
    @Published var isLoading: Bool = false
    @Published var tempSelectedItems: [DropdownItemModel] = []
    @Published var displayedItems: [DropdownItemModel] = []
    private var currentSearchTask: Task<Void, Never>?

    var fetchItemsAPI: ((Int, String) async -> [DropdownItemModel])
    
    init(fetchItemsAPI: @escaping (Int, String) async -> [DropdownItemModel], tempSelectedItems: [DropdownItemModel]) {
        self.fetchItemsAPI = fetchItemsAPI
        self.tempSelectedItems = tempSelectedItems
    }
    
    func loadItems(index: Int, search: String = "") {
        // Cancel the ongoing task, if any
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
            
            if search.isEmpty {
                // Ensure only selected items that are present in result
                let selected = tempSelectedItems.filter { selectedItem in
                    result.contains(where: { $0.id == selectedItem.id })
                }
                
                let unselected = result.filter { item in
                    !selected.contains(where: { $0.id == item.id })
                }
                
                self.displayedItems = selected + unselected
            } else {
                self.displayedItems = result
            }


            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

}

