import XCTest
@testable import BoldDeskSupportSDK

final class AppInfoViewModelTests: XCTestCase {
    func testExtractUTCOffset_withClosingParen_returnsOffset() {
        let vm = AppInfoViewModel()
        let input = "(UTC+05:30) India Standard Time"
        XCTAssertEqual(vm.extractUTCOffset(from: input), "(UTC+05:30)")
    }

    func testExtractUTCOffset_withoutClosingParen_appendsParen() {
        let vm = AppInfoViewModel()
        let input = "UTC+05:30 India"
        XCTAssertEqual(vm.extractUTCOffset(from: input), "UTC+05:30 India)")
    }

    func testExtractUTCOffset_emptyString_returnsFallback() {
        let vm = AppInfoViewModel()
        let input = ""
        XCTAssertEqual(vm.extractUTCOffset(from: input), "(UTC-11:00")
    }
}
