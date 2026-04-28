
import SwiftUI
@MainActor
class TicketSearchViewModel: ObservableObject {
    @Published var tickets: [TicketSearchModel] = []
    @Published var searchText = ""
    @Published var isSearching = false
    @Published var isLoadingMore = false
    @Published var errorMessage: String?
    @Published var hasError = false
    @Published var showFilterSheet = false
    @Published var isRefreshing = false

    private let ticketSearchBL = TicketSearchBL()
    private var currentPage = 1
    private let itemsPerPage = 20
    private var searchTask: Task<Void, Never>?    // current search task
    private var previousTicketCount = 0
    private var hasMoreData = true

    var canLoadMore: Bool {
        hasMoreData && !isLoadingMore && !isSearching && !isRefreshing
    }

    var shouldShowNoMoreItems: Bool {
        !tickets.isEmpty && !hasMoreData && !isLoadingMore && !isSearching && !isRefreshing && tickets.count > itemsPerPage
    }

    var hasSearched: Bool {
        !searchText.isEmpty
    }

    /// Main search
    func searchTickets() {
        // cancel previous search
        searchTask?.cancel()
        guard !searchText.isEmpty else {
            tickets = []
            isSearching = false
            isLoadingMore = false
            isRefreshing = false
            hasError = false
            errorMessage = nil
            return
        }
        isSearching = true
        hasError = false
        errorMessage = nil
        currentPage = 1
        tickets = []
        previousTicketCount = 0
        hasMoreData = true
        searchTask = Task {
            await performSearch()
        }
    }

    /// Async search logic
    private func performSearch() async {
        do {
            let response = try await ticketSearchBL.searchTickets(
                searchQuery: searchText,
                page: currentPage,
                perPage: itemsPerPage
            )

            guard !Task.isCancelled else { return }

            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let ticketItems = rawData["searchResult"] as? [[String: Any]] {

                if !ticketItems.isEmpty {
                    let jsonData = try JSONSerialization.data(withJSONObject: rawData)
                    let ticketResponse = try JSONDecoder().decode(TicketSearchResponse.self, from: jsonData)
                    tickets = ticketResponse.result
                    hasMoreData = ticketResponse.result.count >= itemsPerPage
                    previousTicketCount = tickets.count
                    currentPage = 1
                } else {
                    tickets = []
                    hasMoreData = false
                    currentPage = 1
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            if error is CancellationError {
                print("Search cancelled")
            } else {
                handleError(error)
                ErrorLogs.logErrors(data: error,
                                    exceptionPage: "searchTickets",
                                    isCatchError: true,
                                    statusCode: 500,
                                    stackTrace: Thread.callStackSymbols.joined(separator: "\n"))
            }
        }

        // only mark as finished if it's still the active task
        if !Task.isCancelled {
            isSearching = false
        }
    }

    /// Refresh
    func refreshTickets() {
        searchTask?.cancel()

        isRefreshing = true
        hasError = false
        errorMessage = nil
        currentPage = 1
        previousTicketCount = 0
        hasMoreData = true

        searchTask = Task {
            await performRefresh()
        }
    }

    private func performRefresh() async {
        defer { isRefreshing = false }

        do {
            let response = try await ticketSearchBL.searchTickets(
                searchQuery: searchText,
                page: currentPage,
                perPage: itemsPerPage
            )

            guard !Task.isCancelled else { return }

            if response.isSuccess,
               let rawData = response.data as? [String: Any],
               let ticketItems = rawData["searchResult"] as? [[String: Any]] {

                if !ticketItems.isEmpty {
                    let jsonData = try JSONSerialization.data(withJSONObject: rawData)
                    let ticketResponse = try JSONDecoder().decode(TicketSearchResponse.self, from: jsonData)
                    tickets = ticketResponse.result
                    hasMoreData = ticketResponse.result.count >= itemsPerPage
                    previousTicketCount = tickets.count
                    currentPage = 1
                } else {
                    tickets = []
                    hasMoreData = false
                    currentPage = 1
                }
            } else {
                ErrorLogs.logErrors(data: response.data, isCatchError: false)
            }
        } catch {
            if !(error is CancellationError) {
                handleError(error)
            }
        }
    }

    func loadMoreTickets() {
        guard canLoadMore else { return }

        isLoadingMore = true

        Task {
            defer { isLoadingMore = false }

            do {
                let response = try await ticketSearchBL.searchTickets(
                    searchQuery: searchText,
                    page: currentPage + 1,
                    perPage: itemsPerPage
                )

                if response.isSuccess,
                   let rawData = response.data as? [String: Any],
                   let ticketItems = rawData["searchResult"] as? [[String: Any]],
                   !ticketItems.isEmpty {

                    let jsonData = try JSONSerialization.data(withJSONObject: rawData)
                    let ticketResponse = try JSONDecoder().decode(TicketSearchResponse.self, from: jsonData)

                    let newTickets = ticketResponse.result
                    tickets.append(contentsOf: newTickets)

                    if tickets.count == previousTicketCount {
                        hasMoreData = false
                    } else {
                        previousTicketCount = tickets.count
                        currentPage += 1
                        hasMoreData = newTickets.count >= itemsPerPage
                    }
                } else {
                    hasMoreData = false
                }
            } catch {
                if !(error is CancellationError) {
                    handleError(error)
                }
            }
        }
    }

    func clearSearch() {
        searchText = ""
        tickets = []
        currentPage = 1
        previousTicketCount = 0
        hasMoreData = true
        isSearching = false
        isRefreshing = false
        searchTask?.cancel()
    }

    func openFilter() {
        showFilterSheet = true
    }

    private func handleError(_ error: Error) {
        errorMessage = error.localizedDescription
        hasError = true
    }

    deinit {
        searchTask?.cancel()
    }
}
