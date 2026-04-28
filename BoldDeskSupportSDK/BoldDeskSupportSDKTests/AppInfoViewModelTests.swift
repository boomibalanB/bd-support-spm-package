import XCTest
@testable import BoldDeskSupportSDK

final class AppInfoViewModelTests: XCTestCase {
    @MainActor func testExtractUTCOffset_withClosingParen_returnsOffset() {
        let vm = AppInfoViewModel()
        let input = "(UTC+05:30) India Standard Time"
        XCTAssertEqual(vm.extractUTCOffset(from: input), "(UTC+05:30)")
    }

    @MainActor func testExtractUTCOffset_withoutClosingParen_appendsParen() {
        let vm = AppInfoViewModel()
        let input = "UTC+05:30 India"
        XCTAssertEqual(vm.extractUTCOffset(from: input), "UTC+05:30 India)")
    }

    @MainActor func testExtractUTCOffset_emptyString_returnsFallback() {
        let vm = AppInfoViewModel()
        let input = ""
        XCTAssertEqual(vm.extractUTCOffset(from: input), "(UTC-11:00")
    }
}
