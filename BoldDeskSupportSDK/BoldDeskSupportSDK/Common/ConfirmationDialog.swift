import SwiftUI

struct ConfirmationDialog: View {
    let title: String
    let message: String
    let confirmButtonText: String
    let cancelButtonText: String
    let onConfirm: () -> Void
    let onCancel: () -> Void
    let icon: AppIcons
    let isRed: Bool

    let stackSpacing: CGFloat = 12
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var highlightColor: Color {
        isRed ? Color.textErrorPrimary : Color.accentColor
    }

    var body: some View {
        if horizontalSizeClass == .compact {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    Spacer()
                    dialogContent
                        .background(Color.backgroundPrimary)
                        .cornerRadius(16, corners: [.topLeft, .topRight, .bottomLeft, .bottomRight])
                        .transition(.move(edge: .bottom))
                }
                .padding(.all, 16)
                .padding(.bottom, geometry.safeAreaInsets.bottom)
                .background(Color.backgroundOverlayColor)
                .ignoresSafeArea()
            }
        } else {
            ZStack {
                Color.backgroundOverlayColor
                    .ignoresSafeArea()
                
                dialogContent
                    .background(Color.backgroundPrimary)
                    .cornerRadius(16)
                    .frame(maxWidth: 400)
                    .padding(.horizontal, 32)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }
    
    private var dialogContent: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                onCancel()
            }) {
                AppIcon(icon: .close, size: 24, color: Color.foregroundQuinaryColor)
            }
            .frame(width: 44, height: 44)
            .padding(.trailing, 12)
            .padding(.top, 12)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(highlightColor.opacity(0.2))
                                .frame(width: 48, height: 48)
                            
                            AppIcon(icon: icon, size: 24, color: highlightColor)
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(FontFamily.customFont(size: FontSize.xlarge, weight: .semibold))
                            .foregroundColor(Color.textPrimaryColor)
                        
                        Text(message)
                            .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                            .foregroundColor(Color.textTeritiaryColor)
                    }
                    .padding(.bottom)
                }
                .padding(.horizontal, 20)
                
                Group {
                    if DeviceConfig.isIPhone {
                        VStack(spacing: stackSpacing) {
                            FilledButton.fullWidth(title: confirmButtonText, onClick: onConfirm, color: isRed ? .errorToasterColor : nil)
                            OutlinedButton.fullWidth(title: cancelButtonText, onClick: onCancel)
                        }
                    } else {
                        HStack(spacing: stackSpacing) {
                            OutlinedButton.fullWidth(title: cancelButtonText, onClick: onCancel)
                            FilledButton.fullWidth(title: confirmButtonText, onClick: onConfirm, color: isRed ? .errorToasterColor : nil)
                        }
                    }
                }
                .padding(.horizontal, DeviceConfig.isIPhone ? 16 : 24)
                .padding(.bottom, DeviceConfig.isIPhone ? 16 : 24)
                .padding(.top, DeviceConfig.isIPad ? 8 : 0)
            }
            .padding(.top, DeviceConfig.isIPhone ? 20 : 24)
        }
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}
