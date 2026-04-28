import SwiftUI

struct NetworkWrapper<Content: View>: View {
    @State private var retryKey = UUID()
    @State private var isConnected: Bool
    
    let content: () -> Content
    var onConnectionChange: ((Bool) -> Void)?
    
    init(
        @ViewBuilder content: @escaping () -> Content,
        onConnectionChange: ((Bool) -> Void)? = nil
    ) {
        self.content = content
        self.onConnectionChange = onConnectionChange
        let connectionStatus = InternetConnectionListener.shared.isConnected
        self.isConnected = connectionStatus
        self.onConnectionChange?(self.isConnected)
    }
    
    var body: some View {
        ZStack {
            if isConnected {
                content()
            } else {
                NoInternetView {
                    let connectionStatus = InternetConnectionListener.shared.isConnected
                    self.isConnected = connectionStatus
                    retryKey = UUID()
                    onConnectionChange?(self.isConnected)
                }
            }
        }
        .id(retryKey)
        .onChange(of: isConnected) { newValue in
            onConnectionChange?(newValue)
        }
    }
}
