import SwiftUI
import UIKit

struct DialogAppBar: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var title: String
    var actionButtons: [CustomAppBarAction]
    var onBack: (() -> Void)?
    
    private let height: CGFloat =  64
    
    var body: some View {
        ZStack {
            HStack {
                Button(action: {
                    onBack?() ?? presentationMode.wrappedValue.dismiss()
                }) {
                    Text(ResourceManager.localized("discardText", comment: ""))
                        .foregroundColor(Color.areEqualColors() ? Color.appBarForegroundColor : .accentColor)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                        
                        .lineLimit(1)
                }
                .padding(.leading, 20)
                Spacer()
                
                HStack(spacing: 0) {
                    ForEach(actionButtons.indices, id: \.self) { idx in
                        actionButtons[idx].view
                    }
                }
                .padding(.trailing, 20)
            }
            
            Text(title)
                .foregroundColor(.appBarForegroundColor)
                .font(FontFamily.customFont(size: DeviceConfig.isIPhone ? FontSize.medium : FontSize.large, weight: .semibold))
                
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: height)
        .background(Color.primaryColor)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.borderSecondaryColor),
            alignment: .bottom
        )
    }
}

struct CustomAppBarAction {
    let view: AnyView
    
    init(view: AnyView) {
        self.view = view
    }
    
    static func iconButton(
        appIcon: AppIcons,
        size: CGFloat = 20,
        action: @escaping () -> Void,
        trailingPadding: CGFloat? = nil,
        foregroundColor: Color = Color.areEqualColors() ? Color.appBarForegroundColor : .accentColor
    ) -> CustomAppBarAction {
        let padding = trailingPadding ?? 8
        
        return CustomAppBarAction(
            view: AnyView(
                Button(action: action) {
                    AppIcon(icon: appIcon, size: size, color: foregroundColor)
                        .frame(width: size, height: size)
                }
                .padding(.trailing, padding)
            )
        )
    }
    
    static func textButton(
        text: String,
        action: @escaping () -> Void,
        trailingPadding: CGFloat? = nil,
        isDisabled: Bool = false  
    ) -> CustomAppBarAction {
        let padding = trailingPadding ?? 0
        
        return CustomAppBarAction(
            view: AnyView(
                Button(action: action) {
                    Text(text)
                        .foregroundColor((Color.areEqualColors() ? Color.appBarForegroundColor : .accentColor).opacity(isDisabled ? 0.6 : 1))
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                        .lineLimit(1)
                }
                    .padding(.trailing, padding)
                    .disabled(isDisabled)
            )
        )
    }
}

struct DialogAppBar_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            DialogAppBar(
                title: "Dialog Title",
                actionButtons: [
                    CustomAppBarAction.iconButton(appIcon: .search, action: { print("Done tapped") })
                ],
                onBack: { print("Discard tapped") }
            )
            DialogAppBar(
                title: "Dialog Title No Actions",
                actionButtons: [],
                onBack: { print("Discard tapped") }
            )
            DialogAppBar(
                title: "Create Ticket",
                actionButtons: [
                    CustomAppBarAction.iconButton(appIcon: .search, action: { print("Done tapped") }, trailingPadding: DeviceConfig.isIPhone ? 18 : 28, foregroundColor: .textSecondaryColor),
                    CustomAppBarAction.textButton(text: "Reset", action: { print("Reset tapped") })
                ],
                onBack: { print("Discard tapped") }
            )
            Spacer()
        }
        .background(Color.purple.opacity(0.1))
    }
}
