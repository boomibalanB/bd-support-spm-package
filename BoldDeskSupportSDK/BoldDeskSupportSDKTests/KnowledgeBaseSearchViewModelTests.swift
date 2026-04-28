import XCTest
@testable import BoldDeskSupportSDK

@MainActor
final class KnowledgeBaseSearchViewModelTests: XCTestCase {
    var sut: KnowledgeBaseSearchViewModel!

    override func setUp() {
        super.setUp()
        sut = KnowledgeBaseSearchViewModel()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func testClearSearch_resetsSearchText() {
        sut.searchText = "some query"
        sut.clearSearch()
        XCTAssertEqual(sut.searchText, "")
    }

    func testUpdateSelectedItem_setsSelectedItem() {
        let item = DropdownItemModel(id: 3, itemName: "name", displayName: "name")
        sut.updateSelectedItem(index: 0, selectedItem: item)
        XCTAssertEqual(sut.selectedItem?.id, 3)
        XCTAssertEqual(sut.selectedItem?.itemName, "name")
    }

    func testSelectedCategoryId_returnsNilWhenItemIsNil() {
        sut.selectedItem = nil
        XCTAssertNil(sut.selectedCategoryId)
    }

    func testSelectedCategoryId_returnsNilForZeroId() {
        sut.selectedItem = DropdownItemModel(id: 0, itemName: "All Categories", displayName: "All Categories")
        XCTAssertNil(sut.selectedCategoryId)
    }

    func testSelectedCategoryId_returnsIdWhenNonZero() {
        sut.selectedItem = DropdownItemModel(id: 7, itemName: "Cat", displayName: "Cat")
        XCTAssertEqual(sut.selectedCategoryId, 7)
    }
}
