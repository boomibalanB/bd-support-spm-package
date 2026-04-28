import SwiftUI

struct TicketCardShimmer: View {
    @State private var isAnimating = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                shimmer {
                    RoundedRectangle(cornerRadius: 4)
                        .frame(
                            width: DeviceConfig.isIPhone ? UIScreen.main.bounds.width * 0.6 : UIScreen.main.bounds.width * 0.3,
                            height: 20
                        )
                }
                
                HStack {
                    shimmer {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 80, height: 16)
                    }
                    
                    if !DeviceConfig.isIPhone {
                        Spacer()
                    }
                    
                    shimmer {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 60, height: 16)
                    }
                }
                
                Spacer()
                    .frame(height: 1)
            }
            
            HStack(alignment: .center, spacing: 10) {
                shimmer {
                    Circle()
                        .frame(width: 32, height: 32)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    shimmer {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 100, height: 14)
                    }
                    
                    shimmer {
                        RoundedRectangle(cornerRadius: 4)
                            .frame(width: 160, height: 12)
                    }
                }
                
                Spacer()
            }
            .padding(.top, 12)
        }
        .padding(.all, 16)
        .background(Color.cardBackgroundPrimary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        .shadow(
            color: .cardShadowColor1,
            radius: 1,
            x: 0,
            y: 1
        )
        .shadow(
            color: .cardShadowColor2,
            radius: 1,
            x: 0,
            y: 1
        )
        .onAppear {
            isAnimating = true
        }
    }
    
    @ViewBuilder
    private func shimmer<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .foregroundColor(Color.textTeritiaryColor.opacity(0.3))
            .opacity(isAnimating ? 0.5 : 1.0)
            .animation(
                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
                value: isAnimating
            )
    }
}
