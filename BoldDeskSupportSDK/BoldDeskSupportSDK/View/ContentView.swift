import SwiftUI
import UIKit


struct ContentView: View {
    @EnvironmentObject var toastManager: ToastManager
    var body: some View {
         HelpCenterView()
             .overlay(  ToastStackView()
                 .environmentObject(ToastManager.shared))
    }
}

#Preview {
    ContentView()
}
