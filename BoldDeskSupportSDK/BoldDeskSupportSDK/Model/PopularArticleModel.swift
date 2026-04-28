import SwiftUI

struct PopularArticleModel: Decodable, Identifiable {
    let id: Int
    let title: String?
    let slugTitle: String?
}
