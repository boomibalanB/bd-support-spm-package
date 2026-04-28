import XCTest
@testable import BoldDeskSupportSDK

@MainActor
final class KBListViewModelTests: XCTestCase {

    class MockKnowledgeBaseBL: KnowledgeBaseBL {
        override func getCategoryList() async throws -> APIResponse {
            let data: [String: Any] = [
                "categorylist": [
                    [
                        "id": 1,
                        "name": "Test Category",
                        "description": "desc",
                        "position": 1,
                        "icon": "",
                        "articleCount": 5,
                        "createdOn": "",
                        "groupId": 0,
                        "groupName": "",
                        "groupSlugTitle": "",
                        "groupPosition": 0
                    ]
                ],
                "count": 1
            ]
            return APIResponse(isSuccess: true, data: data, statusCode: 200)
        }

        override func getPopularArticlesList() async throws -> APIResponse {
            let data: [String: Any] = [
                "articleList": [
                    [
                        "id": 101,
                        "title": "Popular Article",
                        "slugTitle": "popular-article"
                    ]
                ]
            ]
            return APIResponse(isSuccess: true, data: data, statusCode: 200)
        }
    }

    func testGetCategoriesPopulatesModel() async throws {
        let vm = KBListViewModel()
        vm.kbListBL = MockKnowledgeBaseBL()
        await vm.getCategories()

        XCTAssertEqual(vm.categoryCount, 1)
        XCTAssertEqual(vm.category.count, 1)
        XCTAssertEqual(vm.category.first?.id, 1)
        XCTAssertEqual(vm.category.first?.name, "Test Category")
    }

    func testGetPopularArticlesPopulatesModel() async throws {
        let vm = KBListViewModel()
        vm.kbListBL = MockKnowledgeBaseBL()
        await vm.getPopularArticles()

        XCTAssertEqual(vm.popularArticle.count, 1)
        XCTAssertEqual(vm.popularArticle.first?.id, 101)
        XCTAssertEqual(vm.popularArticle.first?.title, "Popular Article")
    }
}
