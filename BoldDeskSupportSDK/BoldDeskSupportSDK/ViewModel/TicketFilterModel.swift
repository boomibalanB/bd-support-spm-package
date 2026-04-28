import SwiftUI

// MARK: - Filter Model
class TicketFilterModel: ObservableObject {
    @Published var selectedStatuses: [DropdownItemModel] = []
    @Published var availableStatuses: [DropdownItemModel] = []
    @Published var isLoadingStatuses = false
    @Published var statusesError: String?
    
    private let filterBL = TicketFilterBL()
    
    var hasActiveFilters: Bool {
        return !selectedStatuses.isEmpty
    }
    
    var statusIdList: String? {
        guard !selectedStatuses.isEmpty else { return nil }
        return selectedStatuses.compactMap { $0.stringId }.joined(separator: ",")
    }
    
    func clearAllFilters() {
        selectedStatuses.removeAll()
    }
    
    func updateSelectedStatuses(_ index: Int, _ items: [DropdownItemModel]) {
        let oldSet = Set(selectedStatuses)
        let newSet = Set(items)

        guard oldSet != newSet else { return }
        selectedStatuses = items
    }
    
    @MainActor
    func fetchStatuses(_ index: Int, _ searchText: String) async -> [DropdownItemModel] {
        // If we already have statuses and no search, return filtered results
        if !availableStatuses.isEmpty {
            return filterStatuses(searchText: searchText)
        }
        
        // Load statuses if we don't have them
        await loadStatusesIfNeeded()
        
        // Return filtered results
        return filterStatuses(searchText: searchText)
    }
    
    private func filterStatuses(searchText: String) -> [DropdownItemModel] {
        if searchText.isEmpty {
            return availableStatuses
        } else {
            return availableStatuses.filter { status in
                status.itemName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    @MainActor
    private func loadStatusesIfNeeded() async {
        guard availableStatuses.isEmpty && !isLoadingStatuses else { return }
        
        isLoadingStatuses = true
        statusesError = nil
        
        defer {
            isLoadingStatuses = false
        }
        
        do {
            let response = try await filterBL.getStatuses()
            
            if response.isSuccess {
                if let rawData = response.data as? [String: Any] {
                    let jsonData = try JSONSerialization.data(withJSONObject: rawData)
                    let statusResponse = try JSONDecoder().decode(StatusResponse.self, from: jsonData)
                    // Convert TicketStatus array to DropdownItemModel array
                    let dropdownItems = statusResponse.result.map { ticketStatus in
                        ticketStatus.toDropdownItem()
                    }
                    availableStatuses = dropdownItems
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(data: error, exceptionPage: "loadStatusesIfNeeded in TicketFilterModel", isCatchError: true,
                                statusCode: 500,
                                stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
        }
    }
    
    @MainActor
    func retryLoadingStatuses() async {
        availableStatuses = []
        await loadStatusesIfNeeded()
    }
}

func areSameItems(_ lhs: [DropdownItemModel], _ rhs: [DropdownItemModel]) -> Bool {
    let lhsSet = Set(lhs)
    let rhsSet = Set(rhs)
    return lhsSet == rhsSet
}
