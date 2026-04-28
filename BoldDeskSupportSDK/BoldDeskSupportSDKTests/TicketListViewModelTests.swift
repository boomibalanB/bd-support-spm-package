import XCTest
@testable import BoldDeskSupportSDK

final class TicketListViewModelTests: XCTestCase {

    func makeSampleTicket(id: Int = 1) -> Ticket {
        return Ticket(
            ticketId: id,
            title: "Sample",
            createdOn: "2020-01-01T00:00:00Z",
            status: nil,
            requestedBy: nil,
            lastRepliedOn: "2020-01-01T00:00:00Z"
        )
    }

    func test_canLoadMore_whenTicketsLessThanTotal_returnsTrue() {
        let vm = TicketListViewModel()
        vm.tickets = []
        vm.totalTicketsCount = 10

        XCTAssertTrue(vm.canLoadMore)
    }

    func test_canLoadMore_whenTicketsEqualTotal_returnsFalse() {
        let vm = TicketListViewModel()
        vm.tickets = [makeSampleTicket()]
        vm.totalTicketsCount = 1

        XCTAssertFalse(vm.canLoadMore)
    }

    func test_shouldShowNoMoreItems_whenEmptyTickets_returnsFalse() {
        let vm = TicketListViewModel()
        vm.tickets = []
        vm.totalTicketsCount = 0

        XCTAssertFalse(vm.shouldShowNoMoreItems)
    }

    func test_getViewItems_containsAtLeastMyTicket() {
        let vm = TicketListViewModel()
        let items = vm.getViewItems()

        XCTAssertFalse(items.isEmpty)
        XCTAssertTrue(items.contains { $0.id == 1 })
    }
}
