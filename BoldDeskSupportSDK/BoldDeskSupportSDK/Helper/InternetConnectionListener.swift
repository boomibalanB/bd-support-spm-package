import Foundation
import Network

final class InternetConnectionListener {
    static let shared = InternetConnectionListener()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "InternetConnectionMonitor")
    private var isMonitoring = false
    
    private(set) var isConnected: Bool = false

    private init() {}

    func startListening() async -> Bool {
        if isMonitoring {
            return isConnected
        }

        return await withCheckedContinuation { continuation in
            monitor.pathUpdateHandler = { path in
                if path.status == .satisfied {
                    self.isConnected = true
                } else {
                    self.isConnected = false
                }
                
                if !self.isMonitoring {
                    self.isMonitoring = true
                    continuation.resume(returning: self.isConnected)
                }
            }
            monitor.start(queue: queue)
        }
    }

    func stopListening() {
        guard isMonitoring else { return }
        monitor.cancel()
        isMonitoring = false
    }

    private func getConnectionType(from path: NWPath) -> String {
        if path.usesInterfaceType(.wifi) {
            return "Wi-Fi"
        } else if path.usesInterfaceType(.cellular) {
            return "Cellular"
        } else if path.usesInterfaceType(.wiredEthernet) {
            return "Ethernet"
        } else if path.usesInterfaceType(.other) {
            return "Other"
        } else {
            return "Unknown"
        }
    }
}
