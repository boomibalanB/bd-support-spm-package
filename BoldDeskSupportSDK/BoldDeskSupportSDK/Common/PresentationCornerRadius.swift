import SwiftUI
import UIKit

struct PresentationCornerRadius: ViewModifier {
    let radius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(CornerRadiusSetter(radius: radius))
    }

    private struct CornerRadiusSetter: UIViewControllerRepresentable {
        let radius: CGFloat

        func makeUIViewController(context: Context) -> UIViewController {
            UIViewController()
        }

        func updateUIViewController(_ uiViewController: UIViewController, context: Context) {
            DispatchQueue.main.async {
                applyCornerRadius(uiViewController)
            }
        }

        private func applyCornerRadius(_ hostVC: UIViewController) {

            if #available(iOS 15.0, *) {
                if let sheet = hostVC.parent?.presentationController as? UISheetPresentationController {
                    sheet.preferredCornerRadius = radius
                    return
                }
            }

            if let popVC = hostVC.parent?.presentationController as? UIPopoverPresentationController {
                if let container = popVC.presentedViewController.view.superview {
                    applyToPopoverHierarchy(container)
                    return
                }
            }

            if let presented = hostVC.parent?.presentedViewController {
                applyToPopoverHierarchy(presented.view)
                return
            }

            applyToPopoverHierarchy(hostVC.view)
        }

        private func applyToPopoverHierarchy(_ root: UIView?) {
            guard let root = root else { return }

            let popoverCandidates = findPopoverContainers(in: root)

            for container in popoverCandidates {
                container.layer.cornerRadius = radius
                container.layer.masksToBounds = true
            }
        }

        private func findPopoverContainers(in view: UIView) -> [UIView] {
            var results: [UIView] = []

            let classNames = [
                "_UIPopoverView",
                "_UIPopoverBackgroundView",
                "_UIToolbarPopoverView",
                "UIPopoverBackgroundView"
            ]

            let viewClassName = String(describing: type(of: view))

            if classNames.contains(viewClassName) {
                results.append(view)
            }

            for sub in view.subviews {
                results.append(contentsOf: findPopoverContainers(in: sub))
            }

            return results
        }
    }
}

extension View {
    func presentationCornerRadius(_ radius: CGFloat) -> some View {
        modifier(PresentationCornerRadius(radius: radius))
    }
}
