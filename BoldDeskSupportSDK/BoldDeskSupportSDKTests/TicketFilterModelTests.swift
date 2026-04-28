import XCTest
@testable import BoldDeskSupportSDK

final class TicketFilterModelTests: XCTestCase {

    func makeItem(id: Int, name: String, stringId: String? = nil) -> DropdownItemModel {
        return DropdownItemModel(id: id, itemName: name, stringId: stringId)
    }

    func test_hasActiveFilters_whenSelectedEmpty_isFalse() {
        let model = TicketFilterModel()
        XCTAssertFalse(model.hasActiveFilters)
    }

    func test_hasActiveFilters_whenSelectedNotEmpty_isTrue() {
        let model = TicketFilterModel()
        model.selectedStatuses = [makeItem(id: 1, name: "Open")]
        XCTAssertTrue(model.hasActiveFilters)
    }

    func test_statusIdList_whenEmpty_returnsNil() {
        let model = TicketFilterModel()
        XCTAssertNil(model.statusIdList)
    }

    func test_statusIdList_joinsStringIds() {
        let model = TicketFilterModel()
        model.selectedStatuses = [
            makeItem(id: 1, name: "Open", stringId: "10"),
            makeItem(id: 2, name: "Closed", stringId: "20")
        ]
        XCTAssertEqual(model.statusIdList, "10,20")
    }

    func test_clearAllFilters_clearsSelected() {
        let model = TicketFilterModel()
        model.selectedStatuses = [makeItem(id: 1, name: "Open")]
        model.clearAllFilters()
        XCTAssertTrue(model.selectedStatuses.isEmpty)
    }

    func test_updateSelectedStatuses_noChange_whenSameItems() {
        let model = TicketFilterModel()
        let items = [makeItem(id: 1, name: "Open"), makeItem(id: 2, name: "Closed")]
        model.selectedStatuses = items
        model.updateSelectedStatuses(0, items)
        XCTAssertEqual(model.selectedStatuses, items)
    }

    func test_updateSelectedStatuses_updates_whenDifferentItems() {
        let model = TicketFilterModel()
        let old = [makeItem(id: 1, name: "Open")]
        let newItems = [makeItem(id: 2, name: "Closed")]
        model.selectedStatuses = old
        model.updateSelectedStatuses(0, newItems)
        XCTAssertEqual(model.selectedStatuses, newItems)
    }

    func test_fetchStatuses_returnsAvailable_whenAlreadyLoaded() async {
        let model = TicketFilterModel()
        model.availableStatuses = [
            makeItem(id: 1, name: "Open"),
            makeItem(id: 2, name: "Closed")
        ]

        let all = await model.fetchStatuses(0, "")
        XCTAssertEqual(all.count, 2)

        let filtered = await model.fetchStatuses(0, "open")
        XCTAssertEqual(filtered.count, 1)
        XCTAssertEqual(filtered.first?.itemName.lowercased(), "open")
    }

    func test_areSameItems_trueForSameSets() {
        let a = [makeItem(id: 1, name: "A"), makeItem(id: 2, name: "B")]
        let b = [makeItem(id: 2, name: "B"), makeItem(id: 1, name: "A")]
        XCTAssertTrue(areSameItems(a, b))
    }

    func test_areSameItems_falseForDifferentSets() {
        let a = [makeItem(id: 1, name: "A")]
        let b = [makeItem(id: 2, name: "B")]
        XCTAssertFalse(areSameItems(a, b))
    }
}
