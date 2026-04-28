import Combine
import Foundation
import SwiftUI

// MARK: - Updated Ticket List View Model
class TicketListViewModel: ObservableObject {
    @Published var tickets: [Ticket] = []
    @Published var isInitialLoading = false
    @Published var isRefreshing = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var totalTicketsCount: Int = 0
    @Published var filterModel = TicketFilterModel()
    @Published var selectedItem: DropdownItemModel?
    @Published var contactGroup: [ContactGroup] = []
    @Published var canViewMyOrgTickets: Bool = false

    private let ticketBL = TicketListBL()
    private var currentPage = 1
    private let itemsPerPage = 12
    private var cancellationToken: NetworkCancellationToken?
    private var cancellables = Set<AnyCancellable>()
    private var selectedView = "my-tickets"
    var dropdownItems: [DropdownItemModel] = []

    var canLoadMore: Bool {
        return tickets.count < totalTicketsCount
    }

    var shouldShowNoMoreItems: Bool {
        return !tickets.isEmpty && tickets.count >= totalTicketsCount
            && totalTicketsCount > 0 && !isLoadingMore && !isRefreshing
            && !isInitialLoading && totalTicketsCount > itemsPerPage
    }

    init() {
        _ = getViewItems()
        selectedItem = DropdownItemModel(
            id: 1,
            itemName: ResourceManager.localized("myTicketText", comment: "")
        )
        setupFilterObserver()
    }

    private func setupFilterObserver() {
        // Observe filter changes and reload tickets when filters change
        filterModel.$selectedStatuses
            .dropFirst()  // Skip initial empty value
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.applyFiltersAndReload()
                }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func applyFiltersAndReload() async {
        // Reset pagination and reload with new filters
        currentPage = 1
        tickets = []
        totalTicketsCount = 0
        await loadInitialTickets()
    }

    @MainActor
    func loadInitialTickets() async {
        guard !isInitialLoading && !isRefreshing else { return }

        isInitialLoading = true
        hasError = false
        errorMessage = nil

        defer {
            print("Fetched tickets: \(tickets.count) of \(totalTicketsCount)")
            isInitialLoading = false
        }

        do {
            let response = try await ticketBL.getTickets(
                page: 1,
                perPage: itemsPerPage,
                selectedView: selectedView,
                statusIdList: filterModel.statusIdList,
            )

            if response.isSuccess {
                if let rawData = response.data as? [String: Any] {
                    if let count = rawData["count"] as? Int {
                        totalTicketsCount = count
                    }
                    if let ticketItems = rawData["result"] as? [[String: Any]],
                        !ticketItems.isEmpty
                    {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: rawData
                        )
                        let ticketResponse = try JSONDecoder().decode(
                            TicketResponse.self,
                            from: jsonData
                        )
                        tickets = ticketResponse.result
                        currentPage = 1
                    } else {
                        tickets = []
                        currentPage = 1
                    }
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            if error is CancellationError {
                print("Initial load cancelled")
            } else {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "loadInitialTickets in TicketlistViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
        }
    }
    
    @MainActor
    internal func getContactGroups() async {
        do {
            let response = try await ticketBL.getContactGroups()

            if response.isSuccess,
                let rawData = response.data as? [String: Any],
                let formfieldItem = rawData["result"] as? [[String: Any]]
            {
                let jsonData = try JSONSerialization.data(
                    withJSONObject: formfieldItem
                )

                contactGroup = try JSONDecoder().decode(
                    [ContactGroup].self,
                    from: jsonData
                )
                
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "getFormFields in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
    
    @MainActor
    internal func contactGroupsCanViewTickets() async {
        do {
            let response = try await ticketBL.contactGroupsCanViewTickets()

            if response.isSuccess,
                let rawData = response.data as? [String: Any]
            {
                let rawValue = rawData["raw"]
                if let boolValue = rawValue as? Bool {
                    canViewMyOrgTickets = boolValue
                } else if let stringValue = rawValue as? String {
                    canViewMyOrgTickets = (stringValue.lowercased() == "true")
                }

            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "getFormFields in CreateTicketViewModel",
                isCatchError: true,
                statusCode: 500,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    @MainActor
    func refreshTickets() async {
        guard !isRefreshing && !isInitialLoading else { return }

        cancellationToken?.cancel()
        cancellationToken = NetworkCancellationToken()

        isRefreshing = true
        isLoadingMore = false
        hasError = false
        errorMessage = nil

        defer {
            print("Refreshed tickets: \(tickets.count) of \(totalTicketsCount)")
            isRefreshing = false
        }

        tickets = []
        totalTicketsCount = 0

        do {
            let response = try await ticketBL.getTickets(
                page: 1,
                perPage: itemsPerPage,
                selectedView: selectedView,
                statusIdList: filterModel.statusIdList,
                cancellationToken: cancellationToken
            )

            if response.isSuccess {
                if let rawData = response.data as? [String: Any] {
                    if let count = rawData["count"] as? Int {
                        totalTicketsCount = count
                    }

                    if let ticketItems = rawData["result"] as? [[String: Any]],
                        !ticketItems.isEmpty
                    {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: rawData
                        )
                        let ticketResponse = try JSONDecoder().decode(
                            TicketResponse.self,
                            from: jsonData
                        )
                        tickets = ticketResponse.result
                        currentPage = 1
                    } else {
                        tickets = []
                        currentPage = 1
                    }
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            if error is CancellationError {
                print("Refresh cancelled")
            } else {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "refreshTickets in TicketlistViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
        }
    }

    @MainActor
    func loadMoreTickets() async {
        guard
            !isLoadingMore && !isRefreshing && !isInitialLoading && canLoadMore
        else { return }

        isLoadingMore = true

        defer {
            print(
                "Total tickets after load more: \(tickets.count) of \(totalTicketsCount)"
            )
            isLoadingMore = false
        }

        do {
            let response = try await ticketBL.getTickets(
                page: currentPage + 1,
                perPage: itemsPerPage,
                selectedView: selectedView,
                statusIdList: filterModel.statusIdList
            )

            if response.isSuccess {
                if let rawData = response.data as? [String: Any] {
                    if let ticketItems = rawData["result"] as? [[String: Any]],
                        !ticketItems.isEmpty
                    {
                        let jsonData = try JSONSerialization.data(
                            withJSONObject: rawData
                        )
                        let ticketResponse = try JSONDecoder().decode(
                            TicketResponse.self,
                            from: jsonData
                        )
                        tickets.append(contentsOf: ticketResponse.result)
                        currentPage += 1
                    }
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            if error is CancellationError {
                print("Load more cancelled")
            } else {
                handleError(error)
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "loadMoreTickets in TicketlistViewModel",
                    isCatchError: true,
                    statusCode: 500,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
        }
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        hasError = true
    }

    func retryLastOperation() {
        Task {
            if tickets.isEmpty {
                await loadInitialTickets()
            } else {
                await refreshTickets()
            }
        }
    }

    deinit {
        cancellationToken?.cancel()
    }

    func getViewItems() -> [DropdownItemModel] {
        dropdownItems = []

        let myTicket = ResourceManager.localized("myTicketText", comment: "")
        let ccTicket = ResourceManager.localized("ccViewText", comment: "")
        let myOrganization = ResourceManager.localized(
            "myOrganizationText",
            comment: ""
        )
        dropdownItems.append(DropdownItemModel(id: 1, itemName: myTicket))
        if GeneralSettings.ccConfiguration?.isCcEnabled ?? false {
            dropdownItems.append(DropdownItemModel(id: 2, itemName: ccTicket))
        }
        if !GeneralSettings.isMyOrganizationViewDisabledInCustomerPortal && canViewMyOrgTickets {
            dropdownItems.append(
                DropdownItemModel(id: 3, itemName: myOrganization)
            )
        }

        return dropdownItems
    }

    func updateSelectedItem(id: Int, selectedItem: DropdownItemModel?) {
        self.selectedItem = selectedItem
        if id == 1 {
            selectedView = "my-tickets"

        } else if id == 2 {
            selectedView = "ticket-i%27m-cced-on"
        } else {
            selectedView = "my-organization-tickets"
        }
        Task {
            await loadInitialTickets()
        }
    }
}
