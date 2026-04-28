import Foundation

// MARK: - Main Ticket Model
struct Ticket: Codable, Identifiable {
    let ticketId: Int
    let title: String
    let createdOn: String
    let status: TicketStatus?
    let requestedBy: TicketRequestedBy?
    let lastRepliedOn: String

    var id: Int { ticketId }
}

// MARK: - Ticket Status Model
struct TicketStatus: Codable {
    let id: Int
    let description: String
    let backgroundColor: String
    let textColor: String
}

// MARK: - Ticket Requested By Model
struct TicketRequestedBy: Codable {
    let name: String
    let displayName: String
    let userId: Int
}

struct TicketResponse: Codable {
    let result: [Ticket]
    let count: Int
}


// MARK: - Extensions for convenience
extension Ticket {
    var requesterName: String {
        requestedBy?.displayName ?? ""
    }

    var shortCode: String {
        let words = requesterName.split(separator: " ").map { String($0) }
        if words.isEmpty {
            return requesterName.prefix(2).uppercased()
        } else if words.count == 1 {
            return words[0].prefix(2).uppercased()
        } else {
            let firstLetters = words.prefix(2).map { $0.prefix(1).uppercased() }
            return firstLetters.joined()
        }
    }

    var createdOnDate: Date? {
        ISO8601DateFormatter().date(from: createdOn)
    }

    var lastRepliedOnDate: Date? {
        ISO8601DateFormatter().date(from: lastRepliedOn)
    }
}


#if canImport(SwiftUI)
import SwiftUI

extension TicketStatus {
    var backgroundColorSwiftUI: Color {
        Color(hex: backgroundColor)
    }
    var textColorSwiftUI: Color {
        Color(hex: textColor)
    }
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}
#endif

#if canImport(UIKit)
import UIKit

extension TicketStatus {
    var backgroundColorUIKit: UIColor { UIColor(hex: backgroundColor) }
    var textColorUIKit: UIColor { UIColor(hex: textColor) }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(red: CGFloat(r) / 255,
                  green: CGFloat(g) / 255,
                  blue: CGFloat(b) / 255,
                  alpha: CGFloat(a) / 255)
    }
}
#endif
