import Foundation

class StringToDateTime {
    
    static func parseString(data: String, includeTimeStamp: Bool = false) -> String {
        // Use your robust helper that tries fractional and non-fractional
        guard let dateTime = parseISOString(data) else {
            return data
        }
        
        // Convert to target timezone
        let outputFormatter = DateFormatter()
        outputFormatter.dateFormat = "\(DateTimeSetting.dateFormat) \(DateTimeSetting.timeFormat)"
        outputFormatter.timeZone = TimeZone(identifier: DateTimeSetting.ianaTimeZoneName)
        
        let output = outputFormatter.string(from: dateTime)
        
        if includeTimeStamp {
            let timeAgo = getTimeAgo(timestamp: data)
            return "\(output) (\(timeAgo))"
        } else {
            return output
        }
    }
    
    static func getTimeAgo(timestamp: String) -> String {
        guard let createdTime = parseISOString(timestamp) else {
            return timestamp
        }
        
        let currentDateTime = Date()
        let timeInterval = abs(currentDateTime.timeIntervalSince(createdTime))
        
        let seconds = Int(timeInterval)
        let minutes = seconds / 60
        let hours = minutes / 60
        let days = hours / 24
        let months = days / 30 // Approximate
        
        let agoText = ResourceManager.localized("agoText", value: "ago", comment: "")
        
        switch true {
        case seconds < 60:
            let secondText = seconds == 1 ?
                ResourceManager.localized("secondText", comment: "") :
                ResourceManager.localized("secondsText", comment: "")
            return "\(seconds) \(secondText) \(agoText)"
            
        case minutes < 60:
            let minuteText = minutes == 1 ?
                ResourceManager.localized("minuteText", comment: "") :
                ResourceManager.localized("minutesText", comment: "")
            return "\(minutes) \(minuteText) \(agoText)"
            
        case hours < 24:
            let hourText = hours == 1 ?
                ResourceManager.localized("hourText", comment: "") :
                ResourceManager.localized("hoursText", comment: "")
            return "\(hours) \(hourText) \(agoText)"
            
        case days < 30:
            let dayText = days == 1 ?
                ResourceManager.localized("dayText", comment: "") :
                ResourceManager.localized("daysText", comment: "")
            return "\(days) \(dayText) \(agoText)"
            
        default:
            let monthText = months == 1 ?
                ResourceManager.localized("monthText", comment: "") :
                ResourceManager.localized("monthsText", comment: "")
            return "\(months) \(monthText) \(agoText)"
        }
    }
    
    static func isLessThan24HoursAgo(timestamp: String) -> Bool {
        guard let createdTime = parseISOString(timestamp) else {
            return false
        }

        let currentDate = Date()
        let timeInterval = currentDate.timeIntervalSince(createdTime)
        
        return timeInterval >= 0 && timeInterval < 24 * 60 * 60
    }
    
    // Helper function to parse ISO string to Date
    private static func parseISOString(_ dateString: String) -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Try with fractional seconds first
        if let date = formatter.date(from: dateString) {
            return date
        }
        
        // Try without fractional seconds
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: dateString)
    }
}
