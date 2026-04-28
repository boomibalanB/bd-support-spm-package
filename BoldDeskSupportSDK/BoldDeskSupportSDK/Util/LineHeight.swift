import SwiftUI

class LineHeight{
    func lineSpacingForXSmall() -> CGFloat {
        let fontSize: CGFloat = FontSize.xsmall
        let lineHeight: CGFloat = 18 // based on your mapping
        let lineSpacing: CGFloat = lineHeight - fontSize
        return lineSpacing / 1.8
    }
    func lineSpacingForMedium() -> CGFloat {
        let fontSize: CGFloat = FontSize.medium
        let lineHeight: CGFloat = 20 // based on your mapping
        let lineSpacing: CGFloat = lineHeight - fontSize
        return lineSpacing / 1.8
    }
    func lineSpacingForLarge() -> CGFloat {
        let fontSize: CGFloat = FontSize.large
        let lineHeight: CGFloat = 24 // based on your mapping
        let lineSpacing: CGFloat = lineHeight - fontSize
        return lineSpacing / 1.8
    }
    func lineSpacingForXLarge() -> CGFloat {
        let fontSize: CGFloat = FontSize.xlarge
        let lineHeight: CGFloat = 28 // based on your mapping
        let lineSpacing: CGFloat = lineHeight - fontSize
        return lineSpacing / 1.8
    }
    func lineSpacingForSemiLarge() -> CGFloat {
        let fontSize: CGFloat = FontSize.semilarge
        let lineHeight: CGFloat = 30 // based on your mapping
        let lineSpacing: CGFloat = lineHeight - fontSize
        return lineSpacing / 1.8
    }
    func lineSpacingForExtraLarge() -> CGFloat {
        let fontSize: CGFloat = FontSize.extralarge
        let lineHeight: CGFloat = 32 // based on your mapping
        let lineSpacing: CGFloat = lineHeight - fontSize
        return lineSpacing / 1.8
    }
}
