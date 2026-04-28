import UIKit
import SwiftUI

final class ClipboardManager {
    private init() {}

    static func copy(_ text: String?, successMessage: String? = nil) {
        guard let text, !text.isEmpty else {
            ToastManager.shared.show("Nothing to copy", type: .error)
            return
        }

        UIPasteboard.general.string = text

        if let successMessage {
            ToastManager.shared.show(successMessage, type: .success)
        } else {
            ToastManager.shared.show("Copied to clipboard", type: .success)
        }
    }
}

struct CopyButton: View {
    let textToCopy: String
    var tooltipText: String? = "Copied!"

    var body: some View {
        Button {
            UIPasteboard.general.string = textToCopy
            ToastManager.shared.show("Copied to clipboard", type: .success)
        } label: {
            AppIcon(icon: .link)
                .frame(width: 28, height: 28)
        }

    }
}
