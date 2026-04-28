import SwiftUI

struct NoInternetView: View {
    var onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 30, weight: .semibold))
                .foregroundColor(.textErrorPrimary.opacity(0.8))
                .accessibilityHidden(true)
                .padding()
                .background(Circle().fill(Color.textErrorPrimary.opacity(0.1)))
            
            Spacer().frame(height: 16)
            
            Text(ResourceManager.localized("noInternetConnectionText", comment: "No Internet Connection message"))
                .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                .foregroundColor(.textSecondaryColor)
            
            Spacer().frame(height: 4)
            
            Text(ResourceManager.localized("checkConnectionMessageText", comment: "Please check your connection message"))
                .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                .foregroundColor(.textSecondaryColor)
                .multilineTextAlignment(.center)
            
            Spacer().frame(height: 16)
            
            Button(action: {
                onRetry()
            }) {
                HStack {
                    AppIcon(icon: .reset, size: 16, color: Color.accentColor)
                    Text(ResourceManager.localized("tryAgainText", comment: "Retry"))
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                        .foregroundColor(.accentColor)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 10)
                .background(Color.accentColor.opacity(0.1))
                .cornerRadius(20)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.backgroundPrimary)
        .ignoresSafeArea()
    }
}
