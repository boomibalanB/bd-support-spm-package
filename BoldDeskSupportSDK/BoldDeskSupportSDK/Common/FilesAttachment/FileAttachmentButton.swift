import SwiftUI

struct AttachmentButtonView: View {
    var onTap: () -> Void
    var body: some View{
        if DeviceType.isPhone{
            VStack{
                
                HStack(alignment: .center, spacing: 4) {
                    AppIcon(icon: .attachment, color: .iconBackgroundColor)
                    Text(ResourceManager.localized("attachFileText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                        
                        .foregroundColor(Color.accentColor)
                    
                    Text(ResourceManager.localized("fileSizeText", comment: ""))
                        .foregroundColor(Color.textSecondaryColor)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundColor(Color.buttonSecondaryBorderColor)
                )
                .background(Color.white)
                .cornerRadius(8)
                .contentShape(Rectangle()) // Makes entire box tappable
                .onTapGesture {
                    onTap()
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
            }
        }
        else {
            VStack{
//                Rectangle()
//                    .frame(height: 1)
//                    .foregroundColor(Color.borderSecondaryColor)
                HStack(alignment: .center, spacing: 4) {
                    AppIcon(icon: .attachment, color: .iconBackgroundColor)
                    Text(ResourceManager.localized("clicktoAttachText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                        
                        .foregroundColor(Color.accentColor)
                    
                    Text(ResourceManager.localized("fileSizeText", comment: ""))
                        .foregroundColor(Color.textSecondaryColor)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        
                }
                .frame(maxWidth: .infinity)
                .background(Color.white)
                .cornerRadius(8)
                .contentShape(Rectangle()) // Makes entire box tappable
                .onTapGesture {
                    onTap()
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 14)
        }
    }
}
