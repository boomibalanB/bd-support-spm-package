// MARK: - Attachment
struct Attachment: Codable, Equatable {
    let id: Int
    let name: String
    let `extension`: String
    let contentType: String
    let size: Int
    let createdOn: String
    let fileUrl: String
    let updatedByUserId: Int
    let isExternalFile: Bool
    let cloudStorageTypeId: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, `extension`, contentType, size, createdOn, fileUrl,
             updatedByUserId, isExternalFile, cloudStorageTypeId
    }
}
