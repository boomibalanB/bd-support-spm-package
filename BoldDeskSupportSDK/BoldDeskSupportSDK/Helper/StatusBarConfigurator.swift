import SwiftUI
import UIKit

class StatusBarConfigurator: ObservableObject {

    static var shared = StatusBarConfigurator()
    
    private var window: UIWindow?
    
    var statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            window?.rootViewController?.setNeedsStatusBarAppearanceUpdate()
        }
    }
    
    fileprivate func prepare(scene: UIWindowScene) {
        if window == nil {
            let window = UIWindow(windowScene: scene)
            let viewController = ViewController()
            viewController.configurator = self
            window.rootViewController = viewController
            window.frame = UIScreen.main.bounds
            window.alpha = 0
            self.window = window
        }
        window?.windowLevel = .statusBar
        window?.makeKeyAndVisible()
    }
    
    fileprivate class ViewController: UIViewController {
        weak var configurator: StatusBarConfigurator!
        override var preferredStatusBarStyle: UIStatusBarStyle { configurator.statusBarStyle }
    }
}

fileprivate struct SceneFinder: UIViewRepresentable {
    
    var getScene: ((UIWindowScene) -> ())?
    
    func makeUIView(context: Context) -> View { View() }
    func updateUIView(_ uiView: View, context: Context) { uiView.getScene = getScene }
    
    class View: UIView {
        var getScene: ((UIWindowScene) -> ())?
        override func didMoveToWindow() {
            if let scene = window?.windowScene {
                getScene?(scene)
            }
        }
    }
}

extension View {
    func prepareStatusBarConfigurator() -> some View {
        return self.background(SceneFinder { scene in
            StatusBarConfigurator.shared.prepare(scene: scene)
        })
    }
}
