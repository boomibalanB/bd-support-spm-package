import SwiftUI

struct TicketSearchItemShimmerView: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {

            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 36, height: 36)
                .shimmer()

            VStack(alignment: .leading, spacing: 4) {

                HStack {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 16)
                        .cornerRadius(4)
                        .shimmer()
                    Spacer()
                }

                HStack(spacing: 6) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 60, height: 12)
                        .cornerRadius(3)
                        .shimmer()

                    Rectangle()
                        .fill(Color.buttonSecondaryBorderColor)
                            .frame(width: 1, height: 14)
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 12)
                        .cornerRadius(3)
                        .shimmer()

                    Spacer()
                }
            }

            Spacer()
        }
        .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
        .padding(.vertical, 14)
        .shimmer()
    }
}
