struct CategoryKB: Codable, Identifiable, Hashable {
    let id: Int
    let name: String?
    let description: String?
    let position: Int?
    let icon: String?
    let articleCount: Int?
    let createdOn: String?
    let groupId: Int?
    let groupName: String?
    let groupSlugTitle: String?
    let groupPosition: Int?
}
