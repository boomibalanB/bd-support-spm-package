import SwiftUI

class ToastManager: ObservableObject {
    static let shared = ToastManager()

    @Published var toasts: [ToastItem] = []
    func show(_ message: String, type: ToastType = .info) {
        let toast = ToastItem(message: message, type: type)

        DispatchQueue.main.async {
            withAnimation {
                self.toasts.append(toast)
            }

            // Auto dismiss after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.remove(toast: toast)
            }
        }
    }

    func remove(toast: ToastItem) {
        withAnimation {
            toasts.removeAll { $0.id == toast.id }
        }
    }
}

enum ToastType {
    case success, error, info

    var backgroundColor: Color {
        switch self {
        case .success: return Color.successToasterColor
        case .error: return Color.errorToasterColor
        case .info: return Color.infoToasterColor
        }
    }

    var icon: AppIcons {
        switch self {
        case .success: return .verifiedFill
        case .error: return .closeFilled
        case .info: return .infoFill
        }
    }
}

struct ToastItem: Identifiable, Equatable {
    let id = UUID()
    let message: String
    let type: ToastType
}

