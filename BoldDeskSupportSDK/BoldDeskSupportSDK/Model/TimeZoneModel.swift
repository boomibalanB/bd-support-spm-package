import Foundation

struct TimeZoneResponse: Codable {
    let result: [TimeZoneInfo]
}

struct TimeZoneInfo: Codable {
    let id: Int
    let standardName: String
    let dayLightName: String
    let shortCode: String
    let offset: String
    let name: String
    let timeZoneId: String
    let ianaTimeZoneName: String
}
