import SwiftUI

struct TicketHeaderSectionShimmer: View {
    private let cornerRadius: CGFloat = 16
    private let lineColor = Color.gray.opacity(0.25)

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(lineColor)
                        .frame(width: 220, height: 22)
                }

                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        Circle().fill(lineColor).frame(width: 18, height: 18)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(lineColor)
                            .frame(width: 80, height: 14)
                    }
                    dot()
                    HStack(spacing: 8) {
                        Circle().fill(lineColor).frame(width: 18, height: 18)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(lineColor)
                            .frame(width: 90, height: 14)
                    }
                    dot()
                    Capsule()
                        .fill(lineColor)
                        .frame(width: 56, height: 20)
                }

                Rectangle()
                    .fill(Color.gray.opacity(0.18))
                    .frame(height: 1)

                RoundedRectangle(cornerRadius: 4)
                    .fill(lineColor)
                    .frame(width: 100, height: 16)
                    .padding(.vertical, 4)

                VStack(alignment: .leading, spacing: 8) {
                    line(shortenTo: 1.0)
                    line(shortenTo: 0.95)
                    line(shortenTo: 0.88)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .padding(.bottom, 20)
            .shimmer()
        }
        .background(
            RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
                .fill(Color.backgroundPrimary)
        )
        .overlay(
            RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight])
                .stroke(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .clipShape(RoundedCorner(radius: cornerRadius, corners: [.bottomLeft, .bottomRight]))
        .accessibilityHidden(true)
    }

    private func dot() -> some View {
        Circle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: 4, height: 4)
    }

    private func line(height: CGFloat = 14, shortenTo: CGFloat) -> some View {
        GeometryReader { proxy in
            RoundedRectangle(cornerRadius: 4)
                .fill(lineColor)
                .frame(width: proxy.size.width * shortenTo, height: height, alignment: .leading)
        }
        .frame(height: height)
    }
}
