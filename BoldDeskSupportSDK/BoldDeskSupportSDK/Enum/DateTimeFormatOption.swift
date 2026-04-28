import Foundation

struct FormatOption {
    let value: Int
    let text: String
}

enum DateFormats {
    static let all: [FormatOption] = [
        .init(value: 1, text: "d/MMM/yy"),
        .init(value: 2, text: "MMM dd, yyyy"),
        .init(value: 3, text: "dd MMM, yyyy"),
        .init(value: 4, text: "yyyy, MMM dd"),
        .init(value: 5, text: "dd/MM/yyyy"),
        .init(value: 6, text: "MM/dd/yyyy"),
        .init(value: 7, text: "yyyy/MM/dd"),
        .init(value: 9, text: "MM-dd-yyyy"),
        .init(value: 10, text: "yyyy-MM-dd"),
        .init(value: 11, text: "dd.MM.yyyy"),
        .init(value: 12, text: "dd.MM.yy"),
        .init(value: 13, text: "dd. MMMM yyyy")
    ]
}

enum TimeFormats {
    static let all: [FormatOption] = [
        .init(value: 1, text: NSLocalizedString("12HRCLOCK", comment: "")),
        .init(value: 2, text: NSLocalizedString("24HRCLOCK", comment: ""))
    ]
}
