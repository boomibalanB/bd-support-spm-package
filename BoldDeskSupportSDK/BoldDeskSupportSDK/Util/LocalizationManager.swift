import SwiftUI
import UIKit
import CoreText

/// A helper class to locate the framework bundle
private class BundleLocator {}

enum ResourceManager {
    
    /// Returns the bundle where your framework's resources live
    static var frameworkBundle: Bundle {
        return Bundle(for: BundleLocator.self)
    }
    
    // MARK: - Font Loading
    
    /// Register custom fonts from the framework bundle
    static func registerFonts(_ fontFileNames: [String]) {
        for fileName in fontFileNames {
            let parts = fileName.split(separator: ".")
            guard parts.count == 2,
                  let url = frameworkBundle.url(forResource: String(parts[0]), withExtension: String(parts[1])),
                  let dataProvider = CGDataProvider(url: url as CFURL),
                  let font = CGFont(dataProvider) else {
                continue
            }
            
            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterGraphicsFont(font, &error) {
            }
        }
    }
    
    /// Localized string from the framework's Localizable.strings
    static func localized(_ key: String, value: String = "", comment: String = "") -> String {
        return NSLocalizedString(key, tableName: nil, bundle: frameworkBundle, value: "", comment: comment)
    }
}
