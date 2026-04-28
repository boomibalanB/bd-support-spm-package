import SwiftUI

struct CommonAppBar<Actions: View>: View {
    let title: String
    var subtitle: String? // Optional subtitle
    var showBackButton: Bool = false
    let onBack: (() -> Void)?
    let actionButtons: () -> Actions
    
    @Environment(\.presentationMode) private var presentationMode
    @Environment(\.colorScheme) var colorScheme
    
    init(
        title: String,
        subtitle: String? = nil, // New optional parameter
        showBackButton: Bool = false,
        onBack: (() -> Void)? = nil,
        @ViewBuilder actionButtons: @escaping () -> Actions = { EmptyView() }
    ) {
        self.title = title
        self.subtitle = subtitle
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.actionButtons = actionButtons
    }
    
    var body: some View {
        let textColor: Color =  colorScheme == .dark ? Color.textPrimaryColor : Color.isDarkColor(.primaryColor) ? .backgroundPrimary : .textSecondaryColor
        
        HStack {
            if showBackButton {
                Button(action: {
                    if let onBack = onBack {
                        onBack()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                }) {
                    HStack(spacing: DeviceConfig.isIPhone ? 8 : 12) {
                        AppIcon(
                            icon: .chevronLeft,
                            size: DeviceConfig.isIPhone ? 24 : 26,
                            color: textColor
                        )
                        .frame(width: DeviceConfig.isIPhone ? 24 : 26,
                               height: DeviceConfig.isIPhone ? 24 : 26)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .foregroundColor(textColor)
                                
                                .font(FontFamily.customFont(size: DeviceConfig.isIPhone ? FontSize.large : FontSize.xlarge, weight: .semibold))
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            if let subtitle = subtitle, !subtitle.isEmpty {
                                Text(subtitle)
                                    .foregroundColor(textColor.opacity(0.7))
                                    .font(FontFamily.customFont(size: FontSize.small, weight: .regular))
                                    
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .foregroundColor(textColor)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                        
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if let subtitle = subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .foregroundColor(textColor.opacity(0.7))
                            .font(FontFamily.customFont(size: FontSize.small, weight: .regular))
                            
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
            
            Spacer()
            
            actionButtons()
        }
        .padding(.horizontal, DeviceConfig.isIPhone ? 12 : 16)
        .frame(height: DeviceConfig.isIPhone ? 56 : 56)
        .background(Color.primaryColor)
        .background(Color.white)
        .zIndex(1)
        .shadow(
            color: DeviceConfig.isIPhone && colorScheme != .dark ? Color.textPrimary.opacity(0.05) : .clear,
            radius: 2,
            x: 0,
            y: 1
        )
        .zIndex(DeviceConfig.isIPhone ? 1 : 0)
        .overlay(
            Rectangle()
                .fill(DeviceConfig.isIPhone && colorScheme != .dark  ? .clear : Color.borderSecondaryColor)
                .frame(height: 1),
            alignment: .bottom
        )
    }
}


// MARK: - Custom App Bar Helper
func CommonAppBarCustom(@ViewBuilder content: () -> some View) -> some View {
    HStack {
        content()
    }
    .padding(.horizontal, DeviceConfig.isIPhone ? 12 : 16)
    .frame(height: DeviceConfig.isIPhone ? 56 : 56)
    .background(Color.primaryColor)
    .background(Color.white)
    .shadow(
        color: DeviceConfig.isIPhone ? Color.textPrimary.opacity(0.05) : .clear,
        radius: 2,
        x: 0,
        y: 1
    )
    .zIndex(DeviceConfig.isIPhone ? 1 : 0)
    .overlay(
        Rectangle()
            .fill(DeviceConfig.isIPhone ? .clear : Color.borderSecondaryColor)
            .frame(height: 1),
        alignment: .bottom
    )
    
    
}

// MARK: - Previews

struct CommonAppBar_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            CommonAppBar(
                title: "My Title",
                showBackButton: true,
                onBack: {
                    print("Back tapped!")
                }
            ) {
                HStack(spacing: DeviceConfig.isIPhone ? 8 : 12) {
                    Button(action: { print("Edit tapped") }) {
                        Image(systemName: "pencil")
                    }
                    Button(action: { print("Delete tapped") }) {
                        Image(systemName: "trash")
                    }
                }
            }

        }
    }
}
