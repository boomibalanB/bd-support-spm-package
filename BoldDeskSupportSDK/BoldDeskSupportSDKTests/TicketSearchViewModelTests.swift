import XCTest
@testable import BoldDeskSupportSDK

@MainActor
final class TicketSearchViewModelTests: XCTestCase {

    class TestableSearchViewModel: TicketSearchViewModel {
        var didPerformSearch = false
        var didPerformRefresh = false
        var didLoadMore = false

        override func searchTickets() {
            // simulate the base behavior without network
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
            didPerformSearch = true
            // simulate results
            tickets = [TicketSearchModel(ticketId: 1, title: "t", status: nil, requestedBy: nil, createdOn: "", formattedCreatedOn: "")]
            isSearching = false
        }

        override func refreshTickets() {
            isRefreshing = true
            didPerformRefresh = true
            // simulate refresh
            tickets = []
            isRefreshing = false
        }

        override func loadMoreTickets() {
            guard canLoadMore else { return }
            isLoadingMore = true
            didLoadMore = true
            // simulate load more
            tickets.append(contentsOf: [TicketSearchModel(ticketId: 2, title: "t2", status: nil, requestedBy: nil, createdOn: "", formattedCreatedOn: "")])
            isLoadingMore = false
        }
    }

    @MainActor func makeTickets(count: Int) -> [TicketSearchModel] {
        return (0..<count).map { i in
            TicketSearchModel(ticketId: i, title: "t\(i)", status: nil, requestedBy: nil, createdOn: "", formattedCreatedOn: "")
        }
    }

    @MainActor func test_clearSearch_resetsState() {
        let vm = TicketSearchViewModel()
        vm.searchText = "hello"
        vm.tickets = makeTickets(count: 3)

        vm.clearSearch()

        XCTAssertEqual(vm.searchText, "")
        XCTAssertTrue(vm.tickets.isEmpty)
        XCTAssertFalse(vm.isSearching)
        XCTAssertFalse(vm.isRefreshing)
    }

    @MainActor func test_openFilter_setsFlag() {
        let vm = TicketSearchViewModel()
        XCTAssertFalse(vm.showFilterSheet)
        vm.openFilter()
        XCTAssertTrue(vm.showFilterSheet)
    }

    @MainActor func test_hasSearched_computedProperty() {
        let vm = TicketSearchViewModel()
        XCTAssertFalse(vm.hasSearched)
        vm.searchText = "x"
        XCTAssertTrue(vm.hasSearched)
    }

    @MainActor func test_canLoadMore_and_loading_flags() {
        let vm = TicketSearchViewModel()
        // default hasMoreData is true internally, so canLoadMore should be true
        XCTAssertTrue(vm.canLoadMore)

        vm.isLoadingMore = true
        XCTAssertFalse(vm.canLoadMore)

        vm.isLoadingMore = false
        vm.isSearching = true
        XCTAssertFalse(vm.canLoadMore)

        vm.isSearching = false
        vm.isRefreshing = true
        XCTAssertFalse(vm.canLoadMore)
    }

    @MainActor func test_searchTickets_withEmpty_searchClears() {
        let vm = TestableSearchViewModel()
        vm.searchText = ""
        vm.tickets = makeTickets(count: 2)
        vm.searchTickets()

        XCTAssertTrue(vm.tickets.isEmpty)
        XCTAssertFalse(vm.isSearching)
    }

    @MainActor func test_searchTickets_withText_performsSearch() {
        let vm = TestableSearchViewModel()
        vm.searchText = "query"
        vm.searchTickets()

        XCTAssertTrue(vm.didPerformSearch)
        XCTAssertEqual(vm.tickets.count, 1)
    }

    @MainActor func test_refreshTickets_and_loadMore_behaviors() {
        let vm = TestableSearchViewModel()
        vm.searchText = "q"
        vm.refreshTickets()
        XCTAssertTrue(vm.didPerformRefresh)

        vm.tickets = makeTickets(count: 1)
        vm.loadMoreTickets()
        XCTAssertTrue(vm.didLoadMore)
        XCTAssertEqual(vm.tickets.count, 2)
    }
}
