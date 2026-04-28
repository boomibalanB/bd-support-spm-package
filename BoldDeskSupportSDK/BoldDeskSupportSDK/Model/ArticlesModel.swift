struct ArticlesModel: Decodable, Identifiable {
    let id: Int?
    let name: String?
    let slugTitle: String?
    let position: Int?
    let isSection: Bool?
    let category: CategoryInfo?
    let section: SectionInfo?
    let createdOn: String?
    let lastModifiedOn: String?
    let publishedOn: String?
    let articleStatusIndicator: ArticleStatusIndicator?
    let isReplicated: Bool?
    let replicatedCategory: CategoryInfo?
    let replicatedSection: SectionInfo?
}

struct CategoryInfo: Decodable {
    let id: Int?
    let name: String?
}

struct SectionInfo: Decodable {
    let id: Int?
    let name: String?
}

struct ArticleStatusIndicator: Decodable {
    let id: Int?
    let name: String?
    let expiryDate: String?
}

struct SearchArticleModel: Decodable, Identifiable, Hashable {
    let id: Int?
    let title: String?
    let description: String?
    let slugtitle: String?
    let titleRank: Double?
    let descriptionRank: Double?
}
