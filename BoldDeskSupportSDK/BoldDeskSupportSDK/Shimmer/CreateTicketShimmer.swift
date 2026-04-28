import SwiftUI

struct ShimmerLine: View {
    var height: CGFloat = 80
    var cornerRadius: CGFloat = 8
    
    var body: some View {
        Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(maxWidth: .infinity, minHeight: height, maxHeight: height)
            .cornerRadius(cornerRadius)
            .shimmer()
    }
}

struct CreateTicketShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(0..<15, id: \.self) { _ in
                ShimmerLine()
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
        .background(Color.clear)
        .cornerRadius(12)
    }
}
