import SwiftUI

struct AccessDeniedView: View {
    var appBarTitle: String = ""
    var description: String = ""
    var onBack: (() -> Void)?
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var toastManager: ToastManager
    
    // Computed property to get the actual title being displayed
    private var displayTitle: String {
        if !appBarTitle.isEmpty {
            return appBarTitle
        }
        return BDSDKHome.appBarTitle ?? ResourceManager.localized(
            "helpCenterText",
            comment: ""
        )
    }

    var body: some View {
        AppPage {
            VStack(spacing: 0) {
                CommonAppBar(
                    title: displayTitle,
                    showBackButton: true,
                    onBack: {
                        if onBack?() == nil {
                            presentationMode.wrappedValue.dismiss()
                        } else {
                            onBack?()
                        }
                    }
                )
                Spacer()
                VStack(alignment: .center) {
                    Text(
                        ResourceManager.localized(
                            "accessDeniedText",
                            comment: ""
                        )
                    )
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .semibold
                        )
                    )
                    .padding(.bottom, 2)
                    .foregroundColor(.textSecondaryColor)
                    Text(
                        description.isEmpty
                            ? String(
                                format: ResourceManager.localized(
                                    "accessDeniedMessageText",
                                    comment: ""
                                )
                            ) : description
                    )
                    .font(
                        FontFamily.customFont(
                            size: FontSize.small,
                            weight: .regular
                        )
                    )
                    .foregroundColor(.textTeritiaryColor)
                    .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 12)
                Spacer()
            }

        }
    }
}
