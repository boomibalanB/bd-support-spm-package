import SwiftUI
enum FeedbackContentEnum: String, CaseIterable, Codable, Identifiable {
    case outdatedContent = "Correct inaccurate or outdated content"
    case improve = "Improve illustrations or images"
    case brokenLinks = "Fix typos or broken links"
    case moreInformation = "Need more information"
    case outdatedCode = "Correct inaccurate or outdated code samples"
    case canWeContant = "Can we contact you about this feedback?"
    
    var value: String {
        rawValue
    }

    // Conform to Identifiable for SwiftUI
    var id: String {
        rawValue
    }
}


