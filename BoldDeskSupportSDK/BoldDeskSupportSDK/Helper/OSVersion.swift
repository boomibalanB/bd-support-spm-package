import Foundation

final class OSVersion {

    static var isiOS26OrAbove: Bool {
        if #available(iOS 26.0, *) {
            return true
        } else {
            return false
        }
    }

    static var majorVersion: Int {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion
    }
}
