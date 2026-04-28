import XCTest
import Combine
@testable import BoldDeskSupportSDK

final class ReplyViewModelTests: XCTestCase {
    var cancellables = Set<AnyCancellable>()

    func testValidateReplyText_emptyReturnsFalse() {
        let vm = ReplyViewModel(ticketId: 1, statusId: 1)
        vm.replyText = ""
        XCTAssertFalse(vm.validateReplyText(showToast: false))
    }

    func testValidateReplyText_whitespaceReturnsFalse() {
        let vm = ReplyViewModel(ticketId: 1, statusId: 1)
        vm.replyText = "   \n\t "
        XCTAssertFalse(vm.validateReplyText(showToast: false))
    }

    func testValidateReplyText_nonEmptyReturnsTrue() {
        let vm = ReplyViewModel(ticketId: 1, statusId: 1)
        vm.replyText = "Hello"
        XCTAssertTrue(vm.validateReplyText(showToast: false))
    }

    func testValidateAndUpdateReply_doesNotProceedWhenInvalid() async {
        let vm = ReplyViewModel(ticketId: 1, statusId: 1)
        vm.replyText = "" // invalid input

        let exp = expectation(description: "No dismiss should be sent")
        exp.isInverted = true

        var received = false
        vm.dismissPublisher
            .sink { _ in
                received = true
                exp.fulfill()
            }
            .store(in: &cancellables)

        await vm.validateAndUpdateReply(shouldCloseTicket: false)

        XCTAssertFalse(vm.isInProgress)
        XCTAssertFalse(received)
        wait(for: [exp], timeout: 0.2)
    }
}
