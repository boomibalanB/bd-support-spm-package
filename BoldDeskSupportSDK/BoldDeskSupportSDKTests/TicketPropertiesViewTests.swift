import XCTest
@testable import BoldDeskSupportSDK

final class TicketPropertiesViewTests: XCTestCase {

    func testMultiselectPropertyRow_singleItem() {
        let item = DropdownItemModel(id: 1, itemName: "one", displayName: "One")
        let row = MultiselectPropertyRow(title: "Test", dropdownItems: [item])

        XCTAssertEqual(row.dropdownItems.count, 1)
        XCTAssertEqual(row.itemsToShow.count, 1)
        XCTAssertEqual(row.remainingCount, 0)
        XCTAssertEqual(row.itemsToShow.first?.displayName, "One")
    }

    func testMultiselectPropertyRow_multipleItems() {
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

    func testPropertiesCardViewModel_loadsThenStopsLoading() {
        let vm = PropertiesCardViewModel()
        XCTAssertTrue(vm.isLoading)

        let predicate = NSPredicate(format: "isLoading == false")
        expectation(for: predicate, evaluatedWith: vm, handler: nil)
        waitForExpectations(timeout: 3.0, handler: nil)

        XCTAssertFalse(vm.isLoading)
    }
}
