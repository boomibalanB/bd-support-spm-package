import SwiftUI

struct TicketSearchItemView: View {
    private let title: String
    private let ticketId: Int
    private let statusText: String
    private let statusColor: Color
    private let requesterName: String
    private let createdOn: String
    private let shortCode: String

    init(searchModel: TicketSearchModel) {
        self.title = searchModel.title
        self.ticketId = searchModel.ticketId
        self.statusText = searchModel.safeStatus.description
        self.statusColor = Color(hex: searchModel.safeStatus.backgroundColor)
        self.requesterName = searchModel.requestedBy?.displayName ?? ""
        self.createdOn = StringToDateTime.parseString(data: searchModel.createdOn)
        self.shortCode = searchModel.shortCode
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Avatar Circle
            Circle()
                .fill(Color.secondaryBackgroundColor)
                .frame(width: 36, height: 36)
                .overlay(
                    Circle()
                        .stroke(Color.buttonSecondaryBorderColor, lineWidth: 0.5)
                )
                .overlay(
                    AppIcon(icon: .ticket, color: Color.iconBackgroundColor)
                )

            VStack(alignment: .leading, spacing: 4) {
                
                HStack {
                    // Title
                    Text(title)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: DeviceType.isPhone ? .semibold : .medium))
                        .foregroundColor(.buttonSecondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    Spacer()
                }

                // Ticket ID + separator + createdOn
                HStack(spacing: 6) {
                    Text("#\(ticketId)")
                        .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
                        .foregroundColor(.textQuarteraryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Rectangle()
                            .fill(Color.buttonSecondaryBorderColor)
                            .frame(width: 1, height: 14)

                    Text(createdOn)
                        .font(FontFamily.customFont(size: FontSize.small, weight: DeviceType.isPhone ? .regular : .medium))
                        .foregroundColor(.textQuarteraryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            Spacer()
        }
        .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
