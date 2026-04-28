import SwiftUI

struct PoweredByFooterView: View {
    var body: some View {
        if GeneralSettings.includePoweredBy || (BDSupportSDK.isFromChatSDK && BDSupportSDK.canShowFooterLogo){
            VStack(spacing: 0) {
                Devider(color: Color.borderSecondaryColor)
                HStack (alignment: .bottom){
                    Spacer()
                    if let url = Bundle.framework.url(forResource: "bolddeskLogo", withExtension: "svg") {
                        SVGLogoView(url: url)
                            .frame(width: 16, height: 16)
                            .alignmentGuide(.firstTextBaseline) { d in d[.bottom] } // force baseline at bottom of logo
                    }
                    Text(ResourceManager.localized("poweredByText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.xsmall, weight: .medium, isScaled: false))
                        .foregroundColor(.textTeritiaryColor)
                    + Text(ResourceManager.localized("bolddeskText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.xsmall, weight: .bold, isScaled: false))
                        .foregroundColor(.textTeritiaryColor)
                    Spacer()
                }
                .padding(.top, 20)
            }
            .background(Color.poweredByFooterColor.ignoresSafeArea())
        } else {
            VStack(spacing: 0) {
                Color.clear
                    .frame(height: 20)
            }
            .background(Color.poweredByFooterColor.ignoresSafeArea())
        }
    }
}
