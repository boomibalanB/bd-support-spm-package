import SwiftUI

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -200
    private let timer = Timer.publish(every: 0.016, on: .main, in: .common).autoconnect()
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .white.opacity(0.4),
                        .white.opacity(0.8),
                        .white.opacity(0.4)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .rotationEffect(.degrees(30))
                .offset(x: phase)
                .mask(content)
            )
            .onReceive(timer) { _ in
                phase += 3
                if phase > 350 {
                    phase = -200
                }
            }
    }
}

extension View {
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

struct ShimmerKnowledgeBaseView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading , spacing: 24){
                // Cards
                if DeviceConfig.isIPhone {
                    ForEach(0..<15) { _ in
                        ArticleCardShimmer()
                            .padding(.horizontal)
                    }
                }
                else{
                    let columns = [
                                GridItem(.flexible(), spacing: 32),
                                GridItem(.flexible(), spacing: 0)
                            ]
                            LazyVGrid(columns: columns, spacing: 24) {
                                ForEach(0..<20) { _ in
                                    ArticleCardShimmer()
                                }
                            }
                            .padding(.horizontal, 32)
                }
            }
            .padding(.top)
        }
    }
}

struct ArticleCardShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 36, height: 36)
                    .shimmer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 180, height: 14)
                    .shimmer()
                
                Spacer()
            }

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 12)
                .shimmer()

            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(width: 100, height: 14)
                .shimmer()
        }
        .padding()
        .background(Color.backgroundPrimary)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderSecondaryColor, lineWidth: 1)
        )
    }
}

struct ArticlesShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 40)
                .shimmer()
                .padding(.horizontal)
                .padding(.top, 20)
            
            ForEach(0..<30) { _ in
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 30)
                    .shimmer()
                    .padding(.horizontal)
            }
        }
    }
}
