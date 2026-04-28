import SwiftUI

struct ToastStackView: View {
    @EnvironmentObject var manager: ToastManager

    var body: some View {
        VStack {
            Spacer()

            ForEach(manager.toasts) { toast in
                ToastView(item: toast, onClose: {
                    manager.remove(toast: toast)  // ✅ Correct way to remove
                })
                .padding(.bottom, 8)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: manager.toasts)
            }
        }
        .padding(.bottom, 20)
        .padding(.horizontal)
    }
}

struct ToastView: View {
    let item: ToastItem
    var onClose: (() -> Void)? = nil  // Optional close handler

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            AppIcon(icon: item.type.icon, color: .backgroundPrimary)
                .font(.system(size: 20, weight: .medium))

            Text(item.message)
                .foregroundColor(.backgroundPrimary)
                .font(.system(size: 14, weight: .medium))
                .lineLimit(nil)
                .multilineTextAlignment(.leading)
            // Close icon
            Button(action: {
                onClose?()
            }) {
                AppIcon(icon: .close, color: .backgroundPrimary)
                    .font(.system(size: 20, weight: .medium))
            }
        }
        .padding(12)
        .background(item.type.backgroundColor)
        .cornerRadius(12)
        .shadow(radius: 4)
    }
}

