import SwiftUI


private let appBarHeight: CGFloat = DeviceConfig.isIPhone ? 56 : 60

struct AppScaffold<Content: View>: View {
    let title: String
    let isBackVisible: Bool
    let onBack: () -> Void
    let trailingItems: [AnyView]
    let content: Content

    init(
        title: String,
        isBackVisible: Bool = true,
        onBack: @escaping () -> Void = {},
        trailingItems: [AnyView] = [],
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.isBackVisible = isBackVisible
        self.onBack = onBack
        self.trailingItems = trailingItems
        self.content = content()
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ZStack(alignment: .bottom) {
                    Color.primaryColor
                        .frame(height: DeviceConfig.isIPhone ? 8 : 6)
                        .shadow(
                            color: DeviceConfig.isIPhone ? Color.borderSecondaryColor : Color.clear,
                            radius: DeviceConfig.isIPhone ? 1 : 0,
                            x: DeviceConfig.isIPhone ? 0 : 0,
                            y: DeviceConfig.isIPhone ? 1 : 0
                        )
                    if !DeviceConfig.isIPhone {
                        Color.borderSecondaryColor
                            .frame(height: 1)
                    }
                }
                .zIndex(1)

                content
            }
            .background(
                Color(UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1))
//                Color.isDarkColor(.primaryColor)
//                    ? Color(red: 18/255, green: 18/255, blue: 17/255)
//                    : Color(UIColor(red: 247/255, green: 247/255, blue: 247/255, alpha: 1))
            )
            .navigationBarBackButtonHidden(true)
            .modifier(
                AppBarModifier(
                    title: title,
                    onBack: onBack,
                    trailingItems: trailingItems,
                    isBackVisible: isBackVisible
                )
            )
        }
        .navigationViewStyle(.stack)
        .onAppear {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground()
            appearance.shadowColor = .clear
            appearance.backgroundColor = UIColor(Color.primaryColor)
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        }
        .navigationBarHidden(true)
    }
}

struct AppBarActionButton: View {
    let actionIcon: AppIcons?
    let text: String?
    let action: () -> Void
    let isEnabled: Bool
    let isThemed: Bool
    let color: Color?
    let iconsSize: CGFloat

    init(
        actionIcon: AppIcons? = nil,
        text: String? = nil,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isThemed: Bool = false,
        color: Color? = nil,
        iconsSize: CGFloat = 20
    ) {
        self.actionIcon = actionIcon
        self.text = text
        self.action = action
        self.isEnabled = isEnabled
        self.isThemed = isThemed
        self.color = color
        self.iconsSize = iconsSize
    }

    static func icon(
        icon: AppIcons,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isThemed: Bool = false,
        color: Color? = nil,
        iconsSize: CGFloat = 20
    ) -> AppBarActionButton {
        AppBarActionButton(
            actionIcon: icon,
            action: action,
            isEnabled: isEnabled,
            isThemed: isThemed,
            color: color,
            iconsSize: iconsSize
        )
    }

    static func text(
        text: String,
        action: @escaping () -> Void,
        isEnabled: Bool = true,
        isThemed: Bool = false,
        color: Color? = nil
    ) -> AppBarActionButton {
        AppBarActionButton(
            text: text,
            action: action,
            isEnabled: isEnabled,
            isThemed: isThemed,
            color: color
        )
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 0) {
                if let icon = actionIcon {
                    AppIcon(
                        icon: icon,
                        size: iconsSize,
                        color: color
                            ?? (
                                isThemed
                                ? .accentColor
                                : ((Color.isDarkColor(.primaryColor) && !UIColor(.primaryColor).isBlueish()) ? Color.backgroundPrimary : .textTeritiaryColor)
                            )
                    )
                } else if let text = text {
                    Text(text)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
//                        .fontWeight(.semibold)
                        .foregroundColor(
                            color
                            ?? (
                                isThemed
                                ? .accentColor
                                : ((Color.isDarkColor(.primaryColor) && !UIColor(.primaryColor).isBlueish()) ? Color.backgroundPrimary : .textPrimaryColor)
                            )
                        )
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: appBarHeight, alignment: .center)
        }
        .buttonStyle(.plain)

    }
}

struct AppBarModifier: ViewModifier {
    let title: String
    let onBack: (() -> Void)?
    let trailingItems: [AnyView]
    let isBackVisible: Bool

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if isBackVisible {
                        AppBarLeading.withBack(title: title, onBack: onBack ?? {})
                    } else {
                        AppBarLeading.withoutBack(title: title)
                    }
                }
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    ForEach(trailingItems.indices, id: \.self) { idx in
                        trailingItems[idx]
                    }
                }
            }
    }
}

struct AppBarLeading: View {
    let isBackVisible: Bool
    let onBack: (() -> Void)?
    let title: String

    private init(isBackVisible: Bool, onBack: (() -> Void)?, title: String) {
        self.isBackVisible = isBackVisible
        self.onBack = onBack
        self.title = title
    }

    var body: some View {
        Group {
            if let onBack = onBack {
                Button(action: {
                    onBack()
                }) {
                    content
                }
                .buttonStyle(.plain)
            } else {
                content
            }
        }
            .frame(height: appBarHeight)
    }

    private var content: some View {
        HStack(spacing: DeviceConfig.isIPhone ? 8 : 12) {
            if isBackVisible {
                AppIcon(icon: .chevronLeft, color: (Color.isDarkColor(.primaryColor) && !UIColor(.primaryColor).isBlueish()) ? .backgroundPrimary : .textSecondaryColor)
                    .frame(width: 20, height: 20)
            }

            Text(title)
                .foregroundColor((Color.isDarkColor(.primaryColor) && !UIColor(.primaryColor).isBlueish()) ? .backgroundPrimary : .textSecondaryColor)
                .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
//                .fontWeight(.semibold)
                .lineLimit(1)
                .truncationMode(.tail)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.trailing, 12)
    }
}


extension AppBarLeading {
    static func withBack(title: String, onBack: @escaping () -> Void) -> AppBarLeading {
        AppBarLeading(isBackVisible: true, onBack: onBack, title: title)
    }
    
    static func withoutBack(title: String) -> AppBarLeading {
        AppBarLeading(isBackVisible: false, onBack: nil, title: title)
    }
}

