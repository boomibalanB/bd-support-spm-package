import Foundation
import SwiftUI

class ImageFetcher {
    static let shared = ImageFetcher()
    let cache = NSCache<NSString, NSData>()
    
    
    func fetchImage(from url: String, token: String?) async -> String {
        let cacheKey = url as NSString
        
        if let cachedData = cache.object(forKey: cacheKey) as Data? {
            return cachedData.base64EncodedString()
        }
        
        guard let imageURL = URL(string: url) else {
            return ""
        }
        
        var request = URLRequest(url: imageURL)
        if let token = token {
            request.setValue(token, forHTTPHeaderField: "bd-datatoken")
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 200,
               UIImage(data: data) != nil {
                cache.setObject(data as NSData, forKey: cacheKey)
                return data.base64EncodedString()
            } else {
                return ""
            }
        } catch {
            return ""
        }
    }

}
