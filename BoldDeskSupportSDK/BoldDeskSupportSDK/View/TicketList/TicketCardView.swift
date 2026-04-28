import SwiftUI

struct TicketCardView: View {
    private let title: String
    private let ticketId: Int
    private let statusText: String
    private let statusColor: Color
    private let requesterName: String
    private let createdOn: String
    private let timeAgo: String
    private let shortCode: String
    @Environment(\.colorScheme) var colorScheme
    
    init(ticketModel: Ticket) {
        self.title = ticketModel.title
        self.ticketId = ticketModel.id
        self.statusText = ticketModel.status?.description ?? ""
        self.statusColor = ticketModel.status?.backgroundColorSwiftUI ?? .clear
        self.requesterName = ticketModel.requestedBy?.displayName ?? ""
        self.createdOn = StringToDateTime.parseString(data: ticketModel.createdOn)
        self.timeAgo = StringToDateTime.getTimeAgo(timestamp: ticketModel.createdOn)
        self.shortCode = ticketModel.shortCode
    }

    init(searchModel: TicketSearchModel) {
        self.title = searchModel.title
        self.ticketId = searchModel.ticketId
        self.statusText = searchModel.safeStatus.description
        self.statusColor = Color(hex: searchModel.safeStatus.backgroundColor)
        self.requesterName = searchModel.requestedBy?.displayName ?? ""
        self.createdOn = StringToDateTime.parseString(data: searchModel.createdOn)
        self.timeAgo = StringToDateTime.getTimeAgo(timestamp: searchModel.createdOn)
        self.shortCode = searchModel.shortCode
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                if !title.isEmpty {
                    Text(title)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                        
                        .foregroundColor(.textPrimaryColor)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                }

                HStack {
                    Text("#\(String(ticketId))")
                        .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.vertical, 2)
                        

                    if !DeviceConfig.isIPhone {
                        Spacer()
                    }

                    Text(statusText)
                        .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
                        
                        .foregroundColor(statusColor)
                        .padding(.vertical, 2)
                        .cornerRadius(4)
                        .lineLimit(1)
                }

                Rectangle()
                    .fill(DeviceConfig.isIPhone ? Color.clear : Color.borderSecondaryColor)
                    .frame(height: 1)
                    .overlay(
                        DottedLine()
                            .stroke(DeviceConfig.isIPhone ? Color.buttonSecondaryBorderColor : Color.clear, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                    )
            }

            HStack(alignment: .center, spacing: 10) {
                Circle()
                    .fill(Color.purple)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Text(shortCode)
                            .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                            .foregroundColor(Color.shortCodeTextColor)
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text(requesterName)
                        .font(FontFamily.customFont(size: FontSize.small, weight: .semibold))
                        
                        .foregroundColor(.textTeritiaryColor)
                        .lineLimit(1)

                    Text("\(createdOn) (\(timeAgo))")
                        .font(FontFamily.customFont(size: FontSize.small, weight: .regular))
                        
                        .foregroundColor(.textTeritiaryColor)
                        .lineLimit(1)
                }
            }.padding(.top, 12)
        }
        .padding(.all, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderSecondaryColor, lineWidth: colorScheme == .dark ? 1 : 0)
                .background(Color.cardBackgroundPrimary.cornerRadius(12))
        )
        .shadow(color: .cardShadowColor1, radius: 1, x: 0, y: 1)
        .shadow(color: .cardShadowColor2, radius: 1, x: 0, y: 1)
    }
}

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: 0, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return path
    }
}
