import Foundation
import SwiftUI
import Combine
import UIKit

@MainActor
final class OnlineImagePreviewViewModel: ObservableObject {
    @Published var loadedImage: UIImage? = nil
    @Published var isLoading: Bool = false
    @Published var loadError: Bool = false
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = true
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        return URLSession(configuration: config)
    }()
    
    func loadImage(attachment: Attachment, dataToken: String?) {
        guard let url = URL(string: attachment.fileUrl) else {
            self.loadError = true
            return
        }
        
        let urlString = url.absoluteString.lowercased()
        let hasTokenInURL = urlString.contains("token=")
        
        guard hasTokenInURL || dataToken != nil else {
            self.loadError = true
            return
        }
        
        var request = URLRequest(url: url)
        if let token = dataToken {
            request.setValue(token, forHTTPHeaderField: "bd-datatoken")
        }
        
        isLoading = true
        loadError = false
        loadedImage = nil
        
        let task = session.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor in
                guard let self = self else { return }
                
                defer { self.isLoading = false }
                
                if error != nil {
                    self.loadError = true
                    return
                }
                
                guard let data = data,
                      let uiImage = UIImage(data: data) else {
                    self.loadError = true
                    return
                }
                
                self.loadedImage = uiImage
            }
        }
        
        task.resume()
    }
}
