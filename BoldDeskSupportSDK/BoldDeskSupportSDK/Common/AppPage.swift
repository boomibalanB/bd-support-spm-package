import SwiftUI

struct AppPage<Content: View>: View {
    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content

        if Color.isDarkColor(.primaryColor) {
            StatusBarConfigurator.shared.statusBarStyle = .lightContent
        } else {
            StatusBarConfigurator.shared.statusBarStyle = .darkContent
        }
    }

    var body: some View {
        NavigationView {
            GeometryReader { geometry in
                content()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .prepareStatusBarConfigurator()
                    .overlay(
                        VStack(spacing: 0) {
                            Color.primaryColor
                                .frame(height: geometry.safeAreaInsets.top)
                                .ignoresSafeArea(edges: .top)
                            Spacer()
                        }
                    )
            }
        }
        .navigationBarHidden(true)
        .navigationViewStyle(.stack)
    }
}
