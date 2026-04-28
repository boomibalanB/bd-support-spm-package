
public struct BDSDKHome {
    static var headerName: String? = nil
    static var headerDescription: String? = nil
    static var kbTitle: String? = nil
    static var kbDescription: String? = nil
    static var ticketTitle: String? = nil
    static var ticketDescription: String? = nil
    static var submitButtonText: String? = nil
    static var appBarTitle: String? = nil
    static var logoURL: String? = nil
    
    public static func setHeaderLogo(logoURL: String){
        self.logoURL = logoURL
    }
    
    public static func setHomeDashboardContent(headerName: String? = nil, headerDescription: String? = nil, kbTitle: String? = nil, kbDescription: String? = nil, ticketTitle: String? = nil, ticketDescription: String? = nil, submitButtonText: String? = nil, appBarTitle: String? = nil){
            self.headerName = headerName
            self.headerDescription = headerDescription
            self.kbTitle = kbTitle
            self.kbDescription = kbDescription
            self.ticketTitle = ticketTitle
            self.ticketDescription = ticketDescription
            self.submitButtonText = submitButtonText
            self.appBarTitle = appBarTitle
    }
}
