import SwiftUI

struct CreatedOnTooltipView: View {
    let createdOnTextToShow: String
    @Binding var isVisible: Bool
    var isMessage: Bool = false
    
    var body: some View {
        if isVisible {
            Group {
                if isMessage && DeviceType.isTablet {
                    HStack {
                        Spacer()
                            .frame(width: isMessage ? 56 : 0)
                        CreatedOnTooltipContent(createdOnTextToShow) {
                            isVisible = false
                        }
                        .offset(y: 16)
                        Spacer()
                    }
                } else {
                    CreatedOnTooltipContent(createdOnTextToShow) {
                        isVisible = false
                    }
                    .offset(y: isMessage ? 16 : DeviceType.isPhone ? -32 : 24)
                }
            }
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    withAnimation(nil) {
                        isVisible = false
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func CreatedOnTooltipContent(
        _ createdOnTextToShow: String,
        onDismiss: @escaping () -> Void
    ) -> some View {
        Text("\(ResourceManager.localized("createdOnText")) \(createdOnTextToShow) \(DateTimeSetting.name)")
            .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
            .foregroundColor(Color.backgroundPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.textPrimary)
            )
            .fixedSize()
            .onTapGesture {
                withAnimation(nil) {
                    onDismiss()
                }
            }
    }
}
