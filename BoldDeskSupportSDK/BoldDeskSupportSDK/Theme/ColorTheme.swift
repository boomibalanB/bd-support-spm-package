
import SwiftUI
import UIKit

extension UIColor {
    static func dynamicColor(light: UIColor, dark: UIColor) -> UIColor {
        return UIColor { traitCollection in
            traitCollection.userInterfaceStyle == .dark ? dark : light
        }
    }
    
    func luminance() -> CGFloat {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }
    
    func isBlueish(threshold: CGFloat = 0.1) -> Bool {
        let resolvedColor = self.resolvedColor(with: UIScreen.main.traitCollection)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let isDominantBlue = (blue - red) > threshold && (blue - green) > threshold
        
        let isBlueAboveMin = blue > 0.3
        
        return isDominantBlue && isBlueAboveMin
    }
}

extension Color {
    
    static func isDarkColor(_ color: Color? = nil) -> Bool {
        let colorToCheck = color ?? accentColor
        let uiColor = UIColor(colorToCheck)
        
        // Resolve color in light mode to get consistent results
        var lightTraitCollection = UITraitCollection.current
        if #available(iOS 12.0, *) {
            lightTraitCollection = UITraitCollection(userInterfaceStyle: .light)
        }
        
        let resolvedColor = uiColor.resolvedColor(with: lightTraitCollection)
        return resolvedColor.luminance() < 0.5
    }
            
        static var accentColor: Color {
            let hex = AppConstant.accentColor
            return Color.fromHex(hex) ?? Color(UIColor.dynamicColor(
                light: UIColor(red: 127/255, green: 86/255, blue: 217/255, alpha: 1.0),
                dark: UIColor(red: 142/255, green: 112/255, blue: 248/255, alpha: 1.0)
            ))
        }
        
        static var primaryColor: Color {
            let hex = AppConstant.primaryColor
            return Color(UIColor.dynamicColor(
                light: UIColor.fromHex(hex) ?? UIColor(red: 127/255, green: 86/255, blue: 217/255, alpha: 1.0),
                dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1.0)
            ))
        }
    
    static let backgroundPrimary = Color(UIColor.dynamicColor(
        light: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1.0) // Deeper dark background
    ))
    static let shortCodeTextColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        dark: UIColor(red: 225/255, green: 225/255, blue: 225/255, alpha: 1.0)
    ))
    static let cardBackgroundPrimary = Color(UIColor.dynamicColor(
        light: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        dark: UIColor(red: 22/255, green: 27/255, blue: 38/255, alpha: 1.0) // Deeper dark background
    ))
    static let textPlaceHolderColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 102/255, green: 112/255, blue: 133/255, alpha: 1.0),
        dark: UIColor(red: 138/255, green: 146/255, blue: 166/255, alpha: 1.0) // Dark gray placeholder
    ))
    static let borderSecondaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 234/255, green: 236/255, blue: 240/255, alpha: 1.0),
        dark: UIColor(red: 50/255, green: 50/255, blue: 55/255, alpha: 1.0) // Dark gray border
    ))
    static let textPrimaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 16/255, green: 24/255, blue: 40/255, alpha: 1.0),
        dark: UIColor.white // White text
    ))
    static let textErrorPrimary = Color(UIColor.dynamicColor(
        light: UIColor(red: 217/255, green: 45/255, blue: 32/255, alpha: 1.0),
        dark: UIColor(red: 255/255, green: 105/255, blue: 100/255, alpha: 1.0) // Bright red error
    ))
    static let textPrimary = Color(UIColor.dynamicColor(
        light: UIColor(red: 16/255, green: 24/255, blue: 40/255, alpha: 1.0),
        dark: UIColor(red: 245/255, green: 245/255, blue: 246/255, alpha: 1.0)
    ))
    static let buttonSecondaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 52/255, green: 64/255, blue: 84/255, alpha: 1.0),
        dark: UIColor(red: 206/255, green: 207/255, blue: 210/255, alpha: 1.0) // Dark gray button
    ))
    static let textSecondaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 52/255, green: 64/255, blue: 84/255, alpha: 1.0),
        dark: UIColor(red: 206/255, green: 207/255, blue: 210/255, alpha: 1.0) // Light gray text
    ))
    static let buttonSecondaryBorderColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 208/255, green: 213/255, blue: 221/255, alpha: 1.0),
        dark: UIColor(red: 70/255, green: 75/255, blue: 85/255, alpha: 1.0) // Dark gray border
    ))
    static let textSecondaryPlaceHolderColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 208/255, green: 213/255, blue: 221/255, alpha: 1.0),
        dark: UIColor(red: 120/255, green: 124/255, blue: 138/255, alpha: 1.0) // Dark gray placeholder
    ))
    static let textQuarteraryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 102/255, green: 112/255, blue: 133/255, alpha: 1.0),
        dark: UIColor(red: 150/255, green: 155/255, blue: 170/255, alpha: 1.0) // Dark gray text
    ))
    static let iconBackgroundColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 71/255, green: 84/255, blue: 103/255, alpha: 1.0),
        dark: UIColor(red: 90/255, green: 100/255, blue: 120/255, alpha: 1.0) // Dark gray icon background
    ))
    static let backgroundTeritiaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 242/255, green: 244/255, blue: 247/255, alpha: 1.0),
        dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1.0) // Dark tertiary background
    ))
    static let attachmentIconBackgroundColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 242/255, green: 244/255, blue: 247/255, alpha: 1.0),
        dark: UIColor(red: 22/255, green: 27/255, blue: 38/255, alpha: 1.0) // Dark tertiary background
    ))
    static let tabBarViewBackgroundTeritiaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 242/255, green: 244/255, blue: 247/255, alpha: 1.0),
        dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1.0) // Dark tertiary background
    ))
    static let textTeritiaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 71/255, green: 84/255, blue: 103/255, alpha: 1.0),
        dark: UIColor(red: 148/255, green: 150/255, blue: 156/255, alpha: 1.0) // Dark gray tertiary text
    ))
    static var utilityPurple = Color(UIColor.dynamicColor(
        light: UIColor(red: 122/255, green: 90/255, blue: 248/255, alpha: 1.0),
        dark: UIColor(red: 155/255, green: 120/255, blue: 255/255, alpha: 1.0) // Dark mode purple
    ))
    static var utilitySuccess = Color(UIColor.dynamicColor(
        light: UIColor(red: 23/255, green: 178/255, blue: 106/255, alpha: 1.0),
        dark: UIColor(red: 60/255, green: 200/255, blue: 120/255, alpha: 1.0) // Dark green success
    ))
    static var errorToasterColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 181/255, green: 22/255, blue: 22/255, alpha: 1.0),
        dark: UIColor(red: 255/255, green: 80/255, blue: 80/255, alpha: 1.0) // Dark red error
    ))
    static var infoToasterColor = Color(UIColor.dynamicColor(
        light: UIColor.black,
        dark: UIColor.white // Dark mode info
    ))
    static var successToasterColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 19/255, green: 126/255, blue: 63/255, alpha: 1.0),
        dark: UIColor(red: 60/255, green: 180/255, blue: 90/255, alpha: 1.0) // Dark green success
    ))
    static var cardShadowColor1 = Color(UIColor.dynamicColor(
        light: UIColor(red: 16/255, green: 24/255, blue: 40/255, alpha: 0.06),
        dark: UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.3) // Dark shadow
    ))
    static var cardShadowColor2 = Color(UIColor.dynamicColor(
        light: UIColor(red: 16/255, green: 24/255, blue: 40/255, alpha: 0.1),
        dark: UIColor(red: 0/255, green: 0/255, blue: 0/255, alpha: 0.4) // Dark shadow
    ))
    static var disabledColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 249/255, green: 250/255, blue: 251/255, alpha: 1),
        dark: UIColor(red: 22/255, green: 27/255, blue: 38/255, alpha: 1) // Dark disabled
    ))
    static var popularArticleBackgroundColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 249/255, green: 250/255, blue: 251/255, alpha: 1),
        dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1) // Dark disabled
    ))
    static var secondaryBackgroundColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 245/255, green: 246/255, blue: 251/255, alpha: 1),
        dark: UIColor(red: 24/255, green: 24/255, blue: 24/255, alpha: 1) // Dark secondary background
    ))
    static var buttonPrimaryErrorColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 217/255, green: 45/255, blue: 32/255, alpha: 1.0),
        dark: UIColor(red: 255/255, green: 80/255, blue: 80/255, alpha: 1.0) // Dark button error
    ))
    static var foregroundQuinaryColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 152/255, green: 162/255, blue: 179/255, alpha: 1.0),
        dark: UIColor(red: 120/255, green: 130/255, blue: 150/255, alpha: 1.0) // Dark gray foreground
    ))
    static var backgroundOverlayColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 0.6),
        dark: UIColor(red: 31/255, green: 36/255, blue: 47/255, alpha: 0.8) // Dark overlay
    ))
    static let popoverBackground = Color(UIColor.dynamicColor(
        light: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1.0)      // Dark popover (system gray)
    ))
    static let poweredByFooterColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        dark: UIColor(red: 12/255, green: 17/255, blue: 29/255, alpha: 1.0) // black
    ))
    static let iconColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0),
        dark: UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 1.0) // black
    ))
    static let feedbackCardBackgroundColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 249/255, green: 250/255, blue: 251/255, alpha: 1.0),
        dark: UIColor(red: 23/255, green: 27/255, blue: 37/255, alpha: 1.0)
    ))
    static let feedbackCardForegroundColor = Color(UIColor.dynamicColor(
        light: UIColor(red: 55/255, green: 64/255, blue: 83/255, alpha: 1.0),
        dark: UIColor(red: 206/255, green: 207/255, blue: 210/255, alpha: 1.0)
    ))
    static let infoBannerBackgroundColor = Color(
        UIColor.dynamicColor(
            light: UIColor(
                red: 241/255, green: 248/255, blue: 254/255, alpha: 1.0
            ), // #F1F8FE
            dark: UIColor(
                red: 23/255, green: 42/255, blue: 83/255, alpha: 1.0
            ) // #172A53
        )
    )
    static let infoBannerIconColor = Color(
        UIColor.dynamicColor(
            light: UIColor(
                red: 41/255, green: 97/255, blue: 197/255, alpha: 1.0
            ), // #2961C5
            dark: UIColor(
                red: 61/255, green: 111/255, blue: 246/255, alpha: 1.0
            ) // #3D6FF6
        )
    )
    
    static var appBarForegroundColor: Color {
        Color(UIColor.dynamicColor(
            light: {
                isDarkColor(primaryColor) ? UIColor(backgroundPrimary) : UIColor(iconBackgroundColor)
            }(),
            dark: UIColor.white
        ))
    }
    static var appBarSeachBoxTextColor: Color {
        Color(UIColor.dynamicColor(
            light: {
                isDarkColor(primaryColor) ? UIColor(backgroundPrimary) : UIColor(iconBackgroundColor)
            }(),
            dark: UIColor(.textPrimaryColor)
        ))
    }
    static var appBarSeachBoxPlaceHolderColor: Color {
        Color(UIColor.dynamicColor(
            light: {
                Color.isDarkColor(.primaryColor) ? UIColor(.backgroundPrimary.opacity(0.4)) : UIColor(.textPlaceHolderColor)
            }(),
            dark: UIColor(.textPlaceHolderColor)
        ))
    }
    static var filledButtonForegroundColor: Color {
        Color(UIColor.dynamicColor(
            light: {
                isDarkColor(accentColor) ? UIColor(backgroundPrimary) : UIColor(textPrimaryColor)
            }(),
            dark: {
                isDarkColor(accentColor) ? UIColor(textPrimaryColor) : UIColor(backgroundPrimary)
            }()
        ))
    }
    
    static func customFilledButtonForegroundColor(_ color: Color) -> Color {
        Color(UIColor.dynamicColor(
            light: {
                isDarkColor(color) ? UIColor(backgroundPrimary) : UIColor(textPrimaryColor)
            }(),
            dark: {
                isDarkColor(color) ? UIColor(textPrimaryColor) : UIColor(backgroundPrimary)
            }()
        ))
    }
    static var outlineButtonForegroundColor: Color {
        Color(UIColor.dynamicColor(
            light: UIColor(textSecondaryColor),
            dark: UIColor(textPrimaryColor)
        ))
    }
    
    static func areEqualColors() -> Bool {
        guard let primaryHex = primaryColor.hex,
              let accentHex = accentColor.hex else {
            return false
        }
        return primaryHex.lowercased() == accentHex.lowercased()
    }
}

extension UIColor {
    var toHex: String? {
        var r: CGFloat = 0
        var g: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        
        guard self.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        
        let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0
        return String(format: "#%06X", rgb)
    }
}

extension Color {
    var uiColor: UIColor {
        UIColor(self)
    }
    
    var hex: String? {
        uiColor.toHex
    }
}
