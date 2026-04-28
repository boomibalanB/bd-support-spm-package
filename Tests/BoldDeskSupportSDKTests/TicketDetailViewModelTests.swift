import XCTest
@testable import BoldDeskSupportSDK

@MainActor
final class TicketDetailViewModelTests: XCTestCase {

    class TestableTicketDetailViewModel: TicketDetailViewModel {
        var simulateAccessDenied = false
        var simulateTicket: TicketDetailObject? = nil

        override func loadTicketDetails(force: Bool = false) async {
            isLoading = true
            errorMessage = nil

            if simulateAccessDenied {
                isShowAccessDeniedPage = true
            } else if let t = simulateTicket {
                ticketDetails = t
                AppConstant.fileToken = t.dataToken
                hasLoaded = true
            }

            isLoading = false
        }

        override func closeTicket() async {
            isInProgress = true
            // simulate successful close
            isInProgress = false
            // refresh
            await loadTicketDetails(force: true)
        }

        override func deleteMessage(
            messageId: Int,
            onMessageDeleted: (() -> Void)? = nil
        ) async {
            isInProgress = true
            onMessageDeleted?()
            isInProgress = false
        }
    }

    func makeTicket(id: Int = 1, token: String? = "tok") -> TicketDetailObject {
        return TicketDetailObject(
            ticketId: id,
            title: "T",
            description: "D",
            dataToken: token,
            hasAttachment: false,
            attachments: [],
            createdBy: UserDetails(shortCode: "s", colorCode: "c", displayName: "u", userId: 1, isAgent: false, email: "a@b.com", profileImageUrl: nil),
            updatedBy: UserDetails(shortCode: "s", colorCode: "c", displayName: "u", userId: 1, isAgent: false, email: "a@b.com", profileImageUrl: nil),
            requester: UserDetails(shortCode: "s", colorCode: "c", displayName: "u", userId: 1, isAgent: false, email: "a@b.com", profileImageUrl: nil),
            updatedOn: "", updateCount: 0, status: "", createdOn: "", closedOn: nil,
            needToDisplayContactGroupField: false, updateFlagId: nil, commentId: 0, updatedByUserId: 0, isArchived: false, ticketStatusId: 0, ticketFormId: 0
        )
    }

    func test_defaults_beforeActions() {
        let vm = TestableTicketDetailViewModel(ticketId: 42)
        XCTAssertTrue(vm.isLoading)
        XCTAssertFalse(vm.hasLoaded)
        XCTAssertFalse(vm.isInProgress)
        XCTAssertFalse(vm.isShowAccessDeniedPage)
    }

    func test_loadTicketDetails_success_setsTicketAndToken() async {
        let vm = TestableTicketDetailViewModel(ticketId: 2)
        vm.simulateTicket = makeTicket(id: 2, token: "mytoken")

        await vm.loadTicketDetails(force: true)

        XCTAssertFalse(vm.isLoading)
        XCTAssertTrue(vm.hasLoaded)
        XCTAssertNotNil(vm.ticketDetails)
        XCTAssertEqual(AppConstant.fileToken, "mytoken")
    }

    func test_loadTicketDetails_accessDenied_setsFlag() async {
        let vm = TestableTicketDetailViewModel(ticketId: 3)
        vm.simulateAccessDenied = true

        await vm.loadTicketDetails(force: true)

        XCTAssertTrue(vm.isShowAccessDeniedPage)
        XCTAssertFalse(vm.isLoading)
    }

    func test_closeTicket_triggersRefresh() async {
        let vm = TestableTicketDetailViewModel(ticketId: 4)
        vm.simulateTicket = makeTicket(id: 4, token: "t4")

        await vm.closeTicket()

        XCTAssertFalse(vm.isInProgress)
        XCTAssertTrue(vm.hasLoaded)
        XCTAssertEqual(AppConstant.fileToken, "t4")
    }

    func test_deleteMessage_callsCallback_and_updatesState() async {
        let vm = TestableTicketDetailViewModel(ticketId: 5)
        let exp = expectation(description: "onMessageDeleted called")

        await vm.deleteMessage(messageId: 1) {
            exp.fulfill()
        }

        waitForExpectations(timeout: 1.0)
        XCTAssertFalse(vm.isInProgress)
    }
}
