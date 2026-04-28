import SwiftUI

class Validation {
    
    func isValidURL(_ text: String) -> Bool {
         let pattern = #"^(http:\/\/www\.|https:\/\/www\.|http:\/\/|https:\/\/)?[a-zA-Z0-9]+([\-\.]{1}[a-zA-Z0-9]+)*\.[a-zA-Z]{2,5}(:[0-9]{1,5})?(\/.*)?"#
         let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive)
         let range = NSRange(location: 0, length: text.utf16.count)
         return regex?.firstMatch(in: text, options: [], range: range) != nil
     }
    
    func regexValidate(text: String, pattern: String) -> Bool {
        // Ensure the pattern matches the entire string
        let anchoredPattern = "\(pattern)"
        
        let regex = try? NSRegularExpression(pattern: anchoredPattern)
        let range = NSRange(location: 0, length: text.utf16.count)
        return regex?.firstMatch(in: text, options: [], range: range) != nil
    }

    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = #"^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPredicate.evaluate(with: email)
    }

}
