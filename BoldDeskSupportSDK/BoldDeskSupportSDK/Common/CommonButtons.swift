import SwiftUI

let mediumButtonHeight: CGFloat = 40
let smallButtonHeight: CGFloat = 32
let defaultIconFontSize: CGFloat = 18

struct FilledButton: View {
    let title: String
    let icon: AppIcons?
    let onClick: () -> Void
    let isEnabled: Bool
    let iconOnRight: Bool
    let isSmall: Bool
    let isFullWidth: Bool
    let iconFontSize: CGFloat
    let color: Color?

    // Constructor for button without icon
    init(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        color: Color? = nil
    ) {
        self.title = title
        self.icon = nil
        self.onClick = onClick
        self.isEnabled = isEnabled
        self.iconOnRight = true
        self.isSmall = isSmall
        self.isFullWidth = false
        self.iconFontSize = defaultIconFontSize
        self.color = color
    }

    // Full width button
    static func fullWidth(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        color: Color? = nil
    ) -> FilledButton {
        FilledButton(
            title: title,
            icon: nil,
            onClick: onClick,
            isEnabled: isEnabled,
            iconOnRight: true,
            isSmall: isSmall,
            isFullWidth: true,
            iconFontSize: defaultIconFontSize,
            color: color
        )
    }

    // With icon
    static func withIcon(
        title: String,
        icon: AppIcons,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        iconOnRight: Bool = true,
        isSmall: Bool = false,
        isFullWidth: Bool = false,
        iconFontSize: CGFloat = defaultIconFontSize,
        color: Color? = nil
    ) -> FilledButton {
        FilledButton(
            title: title,
            icon: icon,
            onClick: onClick,
            isEnabled: isEnabled,
            iconOnRight: iconOnRight,
            isSmall: isSmall,
            isFullWidth: isFullWidth,
            iconFontSize: iconFontSize,
            color: color
        )
    }

    private init(
        title: String,
        icon: AppIcons?,
        onClick: @escaping () -> Void,
        isEnabled: Bool,
        iconOnRight: Bool,
        isSmall: Bool,
        isFullWidth: Bool,
        iconFontSize: CGFloat,
        color: Color? = nil
    ) {
        self.title = title
        self.icon = icon
        self.onClick = onClick
        self.isEnabled = isEnabled
        self.iconOnRight = iconOnRight
        self.isSmall = isSmall
        self.isFullWidth = isFullWidth
        self.iconFontSize = iconFontSize
        self.color = color
    }

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 4) {
                if let icon = icon, !iconOnRight {
                    AppIcon(icon: icon, size: iconFontSize, color: color == nil ? .filledButtonForegroundColor : .customFilledButtonForegroundColor(color!))
                }

                Text(title)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                    .foregroundColor(color == nil ? .filledButtonForegroundColor : .customFilledButtonForegroundColor(color!))
                    .lineLimit(1)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, alignment: .center)
                    .padding(.horizontal, 2)

                if let icon = icon, iconOnRight {
                    AppIcon(icon: icon, size: iconFontSize, color: color == nil ? .filledButtonForegroundColor : .customFilledButtonForegroundColor(color!))
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
        }
        .frame(height: isSmall ? smallButtonHeight : mediumButtonHeight)
        .background((color ?? .accentColor).opacity(isEnabled ? 1 : 0.6))
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .disabled(!isEnabled)
    }
}

struct OutlinedButton: View {
    let title: String
    let icon: AppIcons?
    let onClick: () -> Void
    let isEnabled: Bool
    let isThemed: Bool
    let iconOnRight: Bool
    let isSmall: Bool
    let isFullWidth: Bool
    let iconFontSize: CGFloat
    let color: Color?

    // No-icon constructor
    init(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        color: Color? = nil
    ) {
        self.title = title
        self.icon = nil
        self.onClick = onClick
        self.isEnabled = isEnabled
        self.isThemed = false
        self.iconOnRight = true
        self.isSmall = isSmall
        self.isFullWidth = false
        self.iconFontSize = defaultIconFontSize
        self.color = color
    }

    // Full-width constructor
    static func fullWidth(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        isThemed: Bool = true,
        color: Color? = nil
    ) -> OutlinedButton {
        OutlinedButton(
            title: title,
            icon: nil,
            onClick: onClick,
            isEnabled: isEnabled,
            isThemed: isThemed,
            iconOnRight: true,
            isSmall: isSmall,
            isFullWidth: true,
            iconFontSize: defaultIconFontSize,
            color: color
        )
    }

    // Themed constructor
    static func themed(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        color: Color? = nil
    ) -> OutlinedButton {
        OutlinedButton(
            title: title,
            icon: nil,
            onClick: onClick,
            isEnabled: isEnabled,
            isThemed: true,
            iconOnRight: true,
            isSmall: isSmall,
            isFullWidth: false,
            iconFontSize: defaultIconFontSize,
            color: color
        )
    }

    // With icon constructor
    static func withIcon(
        title: String,
        icon: AppIcons,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isThemed: Bool = false,
        iconOnRight: Bool = true,
        isSmall: Bool = false,
        isFullWidth: Bool = false,
        iconFontSize: CGFloat = defaultIconFontSize,
        color: Color? = nil
    ) -> OutlinedButton {
        OutlinedButton(
            title: title,
            icon: icon,
            onClick: onClick,
            isEnabled: isEnabled,
            isThemed: isThemed,
            iconOnRight: iconOnRight,
            isSmall: isSmall,
            isFullWidth: isFullWidth,
            iconFontSize: iconFontSize,
            color: color
        )
    }

    private init(
        title: String,
        icon: AppIcons?,
        onClick: @escaping () -> Void,
        isEnabled: Bool,
        isThemed: Bool,
        iconOnRight: Bool,
        isSmall: Bool,
        isFullWidth: Bool,
        iconFontSize: CGFloat,
        color: Color? = nil
    ) {
        self.title = title
        self.icon = icon
        self.onClick = onClick
        self.isEnabled = isEnabled
        self.isThemed = isThemed
        self.iconOnRight = iconOnRight
        self.isSmall = isSmall
        self.isFullWidth = isFullWidth
        self.iconFontSize = iconFontSize
        self.color = color
    }

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 4) {
                if let icon = icon, !iconOnRight {
                    AppIcon(icon: icon, size: iconFontSize, color: foregroundColor)
                }

                Text(title)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                    .foregroundColor(foregroundColor.opacity(isEnabled ? 1 : 0.6))
                    .lineLimit(1)
                    .frame(maxWidth: isFullWidth ? .infinity : nil, alignment: .center)
                    .padding(.horizontal, 2)

                if let icon = icon, iconOnRight {
                    AppIcon(icon: icon, size: iconFontSize, color: foregroundColor)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: isFullWidth ? .infinity : nil)
        }
        .frame(height: isSmall ? smallButtonHeight : mediumButtonHeight)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(borderColor.opacity(isEnabled ? 1 : 0.6), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 6))
        .disabled(!isEnabled)
    }

    private var foregroundColor: Color {
        if let color = color { return color }
        return isThemed ? .accentColor : .outlineButtonForegroundColor
    }

    private var borderColor: Color {
        if let color = color { return color }
        return isThemed ? .accentColor : .buttonSecondaryBorderColor
    }
}


struct SegmentedButton: View {
    let title: String
    let primaryButtonCallBack: () -> Void
    let secondaryButtonCallBack: () -> Void
    let isEnabled: Bool
    let isSmall: Bool // Added isSmall parameter
    
    init(
        title: String,
        primaryButtonCallBack: @escaping () -> Void,
        secondaryButtonCallBack: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false // Default to false (medium height)
    ) {
        self.title = title
        self.primaryButtonCallBack = primaryButtonCallBack
        self.secondaryButtonCallBack = secondaryButtonCallBack
        self.isEnabled = isEnabled
        self.isSmall = isSmall
    }
    
    var body: some View {
        let height = isSmall ? smallButtonHeight : mediumButtonHeight // Use isSmall to determine height
        HStack(spacing: 0) {
            Button(action: primaryButtonCallBack) {
                Text(title)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                    
                    .foregroundColor(.filledButtonForegroundColor)
                    .frame(maxHeight: .infinity)
                    .padding(.leading, 14)
                    .padding(.trailing, 4)
            }
            .frame(height: height)
            .background(Color.accentColor)
            .clipShape(RoundedCornerShape(radius: 6, corners: [.topLeft, .bottomLeft]))
            .disabled(!isEnabled)
            Button(action: secondaryButtonCallBack) {
                AppIcon(icon: .chevronDown, color: .filledButtonForegroundColor)
                    .frame(width: 20, height: 20)
            }
            .padding(.trailing, 12)
            .frame(height: height)
            .background(Color.accentColor)
            .clipShape(RoundedCornerShape(radius: 6, corners: [.topRight, .bottomRight]))
            .disabled(!isEnabled)
        }
    }
}

struct TextButton: View {
    let title: String
    let onClick: () -> Void
    let isEnabled: Bool
    let isThemed: Bool
    let isSmall: Bool
    let isFullWidth: Bool
    let textColor: Color?

    init(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        isFullWidth: Bool = false,
        textColor: Color? = nil
    ) {
        self.title = title
        self.onClick = onClick
        self.isEnabled = isEnabled
        self.isThemed = false
        self.isSmall = isSmall
        self.isFullWidth = isFullWidth
        self.textColor = textColor
    }

    static func themed(
        title: String,
        onClick: @escaping () -> Void,
        isEnabled: Bool = true,
        isSmall: Bool = false,
        isFullWidth: Bool = false
    ) -> TextButton {
        TextButton(
            title: title,
            onClick: onClick,
            isEnabled: isEnabled,
            isSmall: isSmall,
            isFullWidth: isFullWidth,
            textColor: .accentColor
        )
    }

    var body: some View {
        Button(action: onClick) {
            Text(title)
                .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                
                .foregroundColor(displayTextColor)
                .frame(
                    maxWidth: isFullWidth ? .infinity : nil,
                    alignment: .center
                )
                .padding(.horizontal, 8)
        }
        .background(Color.clear)
        .disabled(!isEnabled)
    }

    private var displayTextColor: Color {
        if let customColor = textColor {
            return customColor
        }
        return isThemed ? .accentColor : .textSecondaryColor
    }
}

// Custom shape for rounding specific corners
struct RoundedCornerShape: Shape {
    let radius: CGFloat
    let corners: UIRectCorner
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// Extension for custom corner radius (kept for compatibility, though not used directly)
extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.init(cornerRadius: cornerRadius)
    }
}

struct Buttons_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Primary action
            FilledButton(title: "Sign In", onClick: { print("Sign In tapped") })
            // Primary with icon
            FilledButton.withIcon(
                title: "Favorite",
                icon: .facebook,
                onClick: { print("Favorite tapped") }
                , isSmall: true,
                iconFontSize: 18
            )
            
            // Destructive (simulate with accent color)
            FilledButton.fullWidth(
                title: "Delete Account",
                onClick: { print("Delete tapped") }
            )
            .padding(.horizontal)
            // Outlined secondary
            OutlinedButton(title: "Learn More", onClick: { print("Learn More tapped") })
            // Outlined with icon
            OutlinedButton.withIcon(
                title: "Next",
                icon: .activity,
                onClick: { print("Next tapped") }
            )
            // Themed outlined
            OutlinedButton.themed(
                title: "Save",
                onClick: { print("Save tapped") }
            )
            // Cancel
            OutlinedButton.fullWidth(
                title: "Cancel",
                onClick: { print("Cancel tapped") },
                isSmall: true
            )
            // Segmented
            SegmentedButton(
                title: "Options",
                primaryButtonCallBack: { print("Primary tapped") },
                secondaryButtonCallBack: { print("Secondary tapped") }
            )
            .padding(.horizontal)
            TextButton(
                title: "Plain Text Button",
                onClick: { print("Plain Text Button tapped") }
            )
            
            TextButton.themed(
                title: "Themed Text Button",
                onClick: { print("Themed tapped") },
                isSmall: false,
                isFullWidth: true
            )
            .padding(.horizontal)
        }
        .padding()
        .previewLayout(.sizeThatFits)
        .preferredColorScheme(.light)
        .background(Color.primaryColor.opacity(0.1))
    }
}
