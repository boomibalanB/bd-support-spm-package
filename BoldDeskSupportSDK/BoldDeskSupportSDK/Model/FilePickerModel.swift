import SwiftUI

struct PickedMediaInfo : Identifiable, Equatable {
    var id = UUID()
    var image: UIImage?
    var file: URL?
    var name: String
    var fileExtension: String
    var fileSizeInBytes: Int64
}



class UploadManager: ObservableObject {
    @Published var pickedItems: [PickedMediaInfo] = []
    @Published var totalFileSizeInBytes: Int64 = 0
}
