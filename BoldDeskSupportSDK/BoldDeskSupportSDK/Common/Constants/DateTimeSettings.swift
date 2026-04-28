import Foundation

struct DateTimeSetting {
    let dateFormatId: Int
    let dateFormat: String
    let ianaTimeZoneName: String
    let timeFormatId: Int
    let timeFormat: String
    let timeZoneId: Int
    let timeZoneName: String
}

extension DateTimeSetting {
    static var name: String {
        DateTimeSettingManager.shared.setting?.timeZoneName ?? "(UTC-11:00)"
    }
    
    static var timeFormat: String {
        DateTimeSettingManager.shared.setting?.timeFormat ?? "hh:mm aa"
    }

    static var dateFormat: String {
        DateTimeSettingManager.shared.setting?.dateFormat ?? "MMM dd, yyyy"
    }
    
    static var ianaTimeZoneName: String {
        DateTimeSettingManager.shared.setting?.ianaTimeZoneName ?? "Etc/GMT+11"
    }
}

final class DateTimeSettingManager: ObservableObject {
    static let shared = DateTimeSettingManager()
    
    @Published private(set) var setting: DateTimeSetting?
    
    private init() {}
    
    func updateSetting(_ newSetting: DateTimeSetting) {
        self.setting = newSetting
    }
    
    func clear() {
        self.setting = nil
    }
}
