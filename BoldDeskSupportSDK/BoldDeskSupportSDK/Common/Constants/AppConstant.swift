import SwiftUI

struct AppConstant {
    static var fileToken : String? = nil
    
    static let timeZoneName = "Asia/Kolkata"
    
    static let sentryDSN = "https://ea67668c225f91abe61df3cd89cf9c1d@logs.bolddesk.com/121"
    
    static let environment = "development"
    
    static let tenentName = ""
    static var maxFileSizeInMB = 20
    static let sdkVersion = "1.0.0"
    static var applicationInfo = ""
    static var deviceName = ""
    static var osVersion = ""
    static var clientAppName = ""
    
    @Preference(key: "baseUrl", defaultValue: "") static var baseUrl
    @Preference(key: "currentDomain", defaultValue: "") static var currentDomain
    @Preference(key: "inlineImageBaseUrl", defaultValue: "") static var inlineImageBaseUrl
    @Preference(key: "authToken", defaultValue: "") static var authToken
    @Preference(key: "appId", defaultValue: "") static var appId
    @Preference(key: "brandURl", defaultValue: "") static var brandURl
    @Preference(key: "mobileSDKId", defaultValue: "") static var mobileSDKId
    @Preference(key: "deviceToken", defaultValue: "") static var deviceToken
    @Preference(key: "accentColor", defaultValue: "") static var accentColor
    @Preference(key: "primaryColor", defaultValue: "") static var primaryColor
    @Preference(key: "authTokenExpiration", defaultValue: "") static var authTokenExpiration
}
