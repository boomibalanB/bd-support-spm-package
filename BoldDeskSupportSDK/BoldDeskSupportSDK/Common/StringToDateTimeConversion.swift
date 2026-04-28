import SwiftUI

func parseDate(dateString: String) -> Date? {
    let formats = [
        "yyyy-MM-dd HH:mm:ss",
        "yyyy-MM-dd'T'HH:mm:ssZ",
        "yyyy-MM-dd'T'HH:mm",
        "yyyy-MM-dd HH:mm",
        "yyyy-MM-dd" // date only
    ]
    
    for format in formats {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = format
        
        if let date = formatter.date(from: dateString) {
            return date
        }
    }
    
    return nil
}
