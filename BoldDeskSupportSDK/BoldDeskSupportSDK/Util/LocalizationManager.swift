import SwiftUI
import UIKit

/// A helper class to locate the framework bundle
private class BundleLocator {}

enum ResourceManager {
    
    /// Returns the bundle where your framework's resources live
    static var frameworkBundle: Bundle {
        return Bundle.module
    }
    
    // MARK: - Font Loading
    
    /// Register custom fonts from the framework bundle using SwiftUI Font.register
    static func registerFonts(_ fontFileNames: [String]) {
        for fileName in fontFileNames {
            let parts = fileName.split(separator: ".")
            guard parts.count == 2,
                  let url = frameworkBundle.url(forResource: String(parts[0]), withExtension: String(parts[1])) else {
                continue
            }
            
            guard let fontData = try? Data(contentsOf: url),
                  let provider = CGDataProvider(data: fontData as CFData),
                  let font = CGFont(provider) else {
                continue
            }
            
            var error: Unmanaged<CFError>?
            if let registeredFont = CTFontManagerRegisterGraphicsFont(font, &error) {
                // Register with SwiftUI Font using the actual font name from the file
                let fontName = String(parts[0])
                Font.register(fontData, withName: fontName)
            }
        }
    }
    
    /// Localized string from the framework's Localizable.strings
    static func localized(_ key: String, value: String = "", comment: String = "") -> String {
        return NSLocalizedString(key, tableName: nil, bundle: frameworkBundle, value: "", comment: comment)
    }
}
