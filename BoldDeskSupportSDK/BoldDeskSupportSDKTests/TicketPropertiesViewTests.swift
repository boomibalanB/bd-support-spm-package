import XCTest
@testable import BoldDeskSupportSDK

final class TicketPropertiesViewTests: XCTestCase {

    @MainActor func testMultiselectPropertyRow_singleItem() {
        let item = DropdownItemModel(id: 1, itemName: "one", displayName: "One")
        let row = MultiselectPropertyRow(title: "Test", dropdownItems: [item])

        XCTAssertEqual(row.dropdownItems.count, 1)
        XCTAssertEqual(row.itemsToShow.count, 1)
        XCTAssertEqual(row.remainingCount, 0)
        XCTAssertEqual(row.itemsToShow.first?.displayName, "One")
    }

    @MainActor func testMultiselectPropertyRow_multipleItems() {
        let items = [
            DropdownItemModel(id: 1, itemName: "1", displayName: "1"),
            DropdownItemModel(id: 2, itemName: "2", displayName: "2"),
            DropdownItemModel(id: 3, itemName: "3", displayName: "3")
        ]

        let row = MultiselectPropertyRow(title: "Test", dropdownItems: items)

        XCTAssertEqual(row.dropdownItems.count, 3)
        XCTAssertEqual(row.itemsToShow.count, 1)
        XCTAssertEqual(row.remainingCount, 2)
        XCTAssertEqual(row.itemsToShow.first?.displayName, "1")
    }
}
