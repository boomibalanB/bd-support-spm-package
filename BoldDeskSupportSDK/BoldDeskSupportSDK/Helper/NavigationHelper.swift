import SwiftUI
import UIKit

enum NavigationHelper {
    /// Push any SwiftUI view onto the top-most navigation stack.
    static func push<V: View>(_ view: V, animated: Bool = true) {
        DispatchQueue.main.async {
            guard let rootVC = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first?.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
                print("⚠️ No rootViewController found")
                return
            }

            var navController: UINavigationController? = nil
            var currentVC: UIViewController? = rootVC

            // Traverse through view controller hierarchy to find UINavigationController
            while currentVC != nil {
                if let nav = currentVC as? UINavigationController {
                    navController = nav
                    break
                } else if let tab = currentVC as? UITabBarController {
                    currentVC = tab.selectedViewController
                } else if let presented = currentVC?.presentedViewController {
                    currentVC = presented
                } else {
                    currentVC = currentVC?.children.first
                }
            }

            guard let navController = navController else {
                print("⚠️ No navigation controller found")
                return
            }

            let hostingController = UIHostingController(rootView: view)
            navController.pushViewController(hostingController, animated: animated)
        }
    }
}


extension UIApplication {
    func topMostViewController(
        _ controller: UIViewController? = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    ) -> UIViewController? {
        if let nav = controller as? UINavigationController {
            return topMostViewController(nav.visibleViewController)
        }
        if let tab = controller as? UITabBarController {
            return topMostViewController(tab.selectedViewController)
        }
        if let presented = controller?.presentedViewController {
            return topMostViewController(presented)
        }
        return controller
    }

    /// Get the top UINavigationController (if it exists)
    func topNavigationController() -> UINavigationController? {
        if let nav = topMostViewController() as? UINavigationController {
            return nav
        }
        return topMostViewController()?.navigationController
    }
}
