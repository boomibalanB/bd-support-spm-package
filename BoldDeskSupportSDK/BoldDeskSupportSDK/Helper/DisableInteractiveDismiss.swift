import SwiftUI

extension View {
    @ViewBuilder
    func applyInteractiveDismiss(_ disabled: Bool) -> some View {
        if #available(iOS 15.0, *) {
            self.interactiveDismissDisabled(disabled)
        } else {
            self.background(
                HostingControllerResolver { vc in
                    vc.parent?.isModalInPresentation = disabled
                }
            )
        }
    }
}

private struct HostingControllerResolver: UIViewControllerRepresentable {
    var onResolve: (UIViewController) -> Void
    
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = UIViewController()
        DispatchQueue.main.async {
            if let parent = vc.parent {
                onResolve(parent)
            }
        }
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
        if let parent = uiViewController.parent {
            onResolve(parent)  // updates when state/binding changes
        }
    }
}
