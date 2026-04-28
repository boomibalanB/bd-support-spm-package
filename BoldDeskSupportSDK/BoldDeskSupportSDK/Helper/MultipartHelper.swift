import Foundation

final class MultipartHelper {
    
    // MARK: - Build Multipart Body
    static func createMultipartBody(
        parameters: [String: Any],
        files: [(name: String, data: Data, filename: String, mimeType: String)],
        boundary: String
    ) -> Data {
        var body = Data()
        let lineBreak = "\r\n"
        
        func stringValue(_ value: Any) -> String {
            if let dict = value as? [String: Any],
               let data = try? JSONSerialization.data(withJSONObject: dict),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
            if let array = value as? [Any],
               let data = try? JSONSerialization.data(withJSONObject: array),
               let json = String(data: data, encoding: .utf8) {
                return json
            }
            if value is NSNull { return "" }
            return "\(value)"
        }
        
        // Add text parameters
        for (key, value) in parameters {
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(key)\"\(lineBreak)\(lineBreak)")
            body.append(stringValue(value))
            body.append(lineBreak)
        }
        
        // Add files
        for file in files {
            let encFilename = file.filename
                .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                ?? file.filename
            
            body.append("--\(boundary)\(lineBreak)")
            body.append("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(encFilename)\"\(lineBreak)")
            body.append("Content-Type: \(file.mimeType)\(lineBreak)\(lineBreak)")
            body.append(file.data)
            body.append(lineBreak)
        }
        
        body.append("--\(boundary)--\(lineBreak)")
        return body
    }
    
    // MARK: - Mime Type Helper
    static func mimeType(from url: URL) -> String {
        let ext = url.pathExtension.lowercased()
        switch ext {
        case "png": return "image/png"
        case "jpg", "jpeg": return "image/jpeg"
        case "pdf": return "application/pdf"
        case "doc", "docx": return "application/msword"
        case "mp4": return "video/mp4"
        case "mov": return "video/quicktime"
        default: return "application/octet-stream"
        }
    }
}
