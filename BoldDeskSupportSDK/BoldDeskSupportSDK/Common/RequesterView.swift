import SwiftUI

struct RequesterCardView: View {
    var name: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Requester")
                .font(FontFamily.customFont(size: FontSize.xsmall, weight: .medium))
                
                .foregroundColor(Color.textSecondaryColor)

            HStack(spacing: 6) {
                // Circle with initial
                Text(String(name.prefix(1)).uppercased())
                    .font(FontFamily.customFont(size: FontSize.xsmall, weight: .semibold))
                    
                    .foregroundColor(.white)
                    .frame(width: 24, height: 24)
                    .background(Color.purple)
                    .clipShape(Circle())
                    
                Text(name)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                    
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity, alignment: .leading )
            }
        }
        .padding(12)
        .background(Color.disabledColor)
        .cornerRadius(6)
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(Color.borderSecondaryColor, lineWidth: 1)
        )
        .frame(maxWidth: .infinity, minHeight: 76, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
    }
}
