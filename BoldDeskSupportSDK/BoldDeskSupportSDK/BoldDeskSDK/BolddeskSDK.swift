internal import SDWebImageSVGCoder
internal import Sentry
import SwiftUI
import UIKit

public struct BDSupportSDK {
    static let loginBL = LoginBL()
    private static var fontsRegistered = false
    public static var applySystemFontSize = false
    private static var fcmToken: String?
    public static var isFromChatSDK: Bool = false
    static var appKey: String = ""
    static var email: String = ""
    static var name: String = ""
    static var phoneNo: String = ""
    static var formId: String?
    static var chatData: ChatConfiguration?
    static var canShowFooterLogo: Bool = false
    private static var themeManager: ThemeManager { ThemeManager.shared }

    // Keep a single reusable hosting controller for all SDK screens.
    private static var hostingController: UIHostingController<AnyView>?

    public static func initialize(
        appId: String,
        brandURl: String,
        _ successCallback: ((String?) -> Void)? = nil,
        _ errorCallback: ((String?) -> Void)? = nil
    ) {
        AppConstant.baseUrl = "https://\(brandURl)/sdk-api/v1.0"
        AppConstant.currentDomain = "https://\(brandURl)/en-US/support"
        AppConstant.inlineImageBaseUrl = "https://\(brandURl)"
        Task {
            await InternetConnectionListener.shared.startListening()
        }
        getAppDetails(brandUrl: brandURl)
        if AppConstant.environment != "development" {
            initializeSentry()
        }
        if (AppConstant.appId.isEmpty
            || AppConstant.brandURl.isEmpty && appId.isEmpty
            || brandURl.isEmpty)
            || AppConstant.appId != appId
            || AppConstant.brandURl != brandURl
        {
            clearallLocalData()
            Task {
                await initializeAPI(
                    appId: appId,
                    brandURl: brandURl,
                    successCallback,
                    errorCallback
                )
            }
        } else {
            Task {
                await initializeAPI(
                    appId: appId,
                    brandURl: brandURl,
                    successCallback,
                    errorCallback
                )
            }
        }
    }

    public static func clearallLocalData() {
        Task {
            AppConstant.appId = ""
            AppConstant.brandURl = ""
            AppConstant.mobileSDKId = ""
            AppConstant.authToken = ""
            AppConstant.authTokenExpiration = ""
            await deleteFCMRegistrationToken()
        }
        
    }

    public static func logout() {
        Task {
            await deleteFCMRegistrationToken()
            AppConstant.authToken = ""
            AppConstant.authTokenExpiration = ""
        }
    }

    private static func initializeAPI(
        appId: String,
        brandURl: String,
        _ successCallback: ((String?) -> Void)? = nil,
        _ errorCallback: ((String?) -> Void)? = nil
    ) async {
        do {
            let response = try await loginBL.initializeSDK(
                appID: appId,
                brandUrl: brandURl
            )
            if let dataDict = response.data as? [String: Any],
                response.isSuccess
            {
                let sdkSuccessFlag = (dataDict["success"] as? Bool) ?? false
                if sdkSuccessFlag {
                    successCallback?(
                        ResourceManager.localized("appValidText", comment: "")
                    )
                    if let sdkId = dataDict["mobileSDKId"] as? String {
                        AppConstant.appId = appId
                        AppConstant.brandURl = brandURl
                        AppConstant.mobileSDKId = sdkId
                    }
                } else {
                    errorCallback?(
                        ResourceManager.localized(
                            "appNotValidText",
                            comment: ""
                        )
                    )
                }
            } else {
                ErrorLogs.logErrors(
                    data: response.data,
                    isCatchError: false
                )
                errorCallback?(
                    ResourceManager.localized("appNotValidText", comment: "")
                )
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "initialize in BDSupportSDK",
                isCatchError: true,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }
    
    public static func chatSDKData(
        chatData: ChatConfiguration,
        onTicketCreatedEventCallBack: ((String, String?) -> Void)? = nil
    ) {
        self.chatData = chatData
        self.isFromChatSDK = chatData.isFromChatSDK
        // Set provided callback (if any) when initializing chat SDK data
        self.onTicketCreatedEventCallBack = onTicketCreatedEventCallBack
        AppConstant.baseUrl = "\(chatData.brandURL)/sdk-api/v1.0"
        AppConstant.currentDomain = "\(chatData.brandURL)/en-US/support"
        AppConstant.inlineImageBaseUrl = "\(chatData.brandURL)"
        AppConstant.maxFileSizeInMB = Int(bytesToMegabytes(
            Int64(chatData.generalSettings?.uploadFileSize ?? 0)
        ))
        canShowFooterLogo = chatData.generalSettings?.includePoweredBy ?? false
    }

    public static func isLoggedIn() -> Bool {
        return !isTokenExpired()
    }

    private static func isTokenExpired() -> Bool {
        let expiry = AppConstant.authTokenExpiration
        guard !expiry.isEmpty,
            let expiryDate = DateUtils.utcStringToDate(expiry)
        else {
            return true
        }
        return Date() >= expiryDate
    }

    public static func loginWithJWTToken(
        jwtToken: String,
        _ successCallback: ((String?) -> Void)? = nil,
        _ errorCallback: ((String?) -> Void)? = nil
    ) {
        Task {
            do {
                Task {
                    await InternetConnectionListener.shared.startListening()
                }
                let response = try await loginBL.loginJWT(jwtToken: jwtToken)
                if let dataDict = response.data as? [String: Any],
                    response.isSuccess
                {
                    if let sdkSuccessFlag = dataDict["access_token"] as? String
                    {
                        AppConstant.authToken = sdkSuccessFlag
                        if !AppConstant.authToken.isEmpty {
                            if let expirySeconds = dataDict["expires_in"]
                                as? Double, expirySeconds > 0
                            {
                                let expiryDate = Date().addingTimeInterval(
                                    expirySeconds
                                )
                                let utcString = DateUtils.dateToUTCString(
                                    expiryDate
                                )
                                AppConstant.authTokenExpiration = utcString
                            } else {
                                AppConstant.authTokenExpiration = ""
                            }
                        }
                        if !AppConstant.authToken.isEmpty
                            && !AppConstant.mobileSDKId.isEmpty
                            && fcmToken?.isEmpty == false
                        {
                            setFCMRegistrationToken()
                        }
                        successCallback?(
                            ResourceManager.localized(
                                "loginSuccessMessagetext",
                                comment: ""
                            )
                        )
                    }
                } else {
                    AppConstant.authToken = ""
                    AppConstant.authTokenExpiration = ""
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                    errorCallback?(
                        ResourceManager.localized(
                            "loginErrorMessagetext",
                            comment: ""
                        )
                    )
                }
            } catch {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "initialize in BDSupportSDK",
                    isCatchError: true,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
        }
    }
    private static func setup() {
        initializeDefaultItems()
    }

    private static var Theme: SDKTheme = .light {
        didSet {
            setPreferredTheme(Theme)
        }
    }

    public static func setPreferredTheme(_ theme: SDKTheme) {
        switch theme {
        case .light:
            themeManager.setTheme(.light)
        case .dark:
            themeManager.setTheme(.dark)
        case .system:
            themeManager.setTheme(.system)
        }
    }

    private static func initializeSentry() {
        DispatchQueue.main.async {
            SentrySDK.start { options in
                options.dsn = AppConstant.sentryDSN
                options.sendDefaultPii = true
                options.environment = AppConstant.environment

            }
        }
    }

    internal static func reset() {
        DispatchQueue.main.async {
            hostingController?.dismiss(animated: true) {
                hostingController = nil
            }
        }
    }

    public static func applyTheme(
        accentColor: String = "",
        primaryColor: String = ""
    ) {
        AppConstant.accentColor = accentColor
        AppConstant.primaryColor = primaryColor
    }

    internal static func validateToken() {
        if isTokenExpired() {
            AppConstant.authToken = ""
            AppConstant.authTokenExpiration = ""
        }
    }

    public static func showKB() {
        Task {
            let _ = await InternetConnectionListener.shared.startListening()
            validateToken()
            kbView()
        }
    }

    private static func kbView() {
        let view: AnyView =
            AnyView(
                AppLaunchView.knowledgeBase()
                    .environmentObject(ToastManager.shared)
            )
        presentOrReplaceRoot(view)
    }

    public static func showCreateTicket() {
        Task {
            let _ = await InternetConnectionListener.shared.startListening()
            validateToken()
            submitTicketView()
        }
    }

    private static func submitTicketView() {
        let view: AnyView = AnyView(
            AppLaunchView.createTicket()
                .presentationCornerRadius(DeviceType.isPhone ? 0 : 12)
                .environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(view, isShowDialog: DeviceConfig.isIPad)
    }

    public static func showHomeDashboard() {
        Task {
            let _ = await InternetConnectionListener.shared.startListening()
            validateToken()
            homeView()
        }
    }

    private static func homeView() {
        let view: AnyView = AnyView(
            AppLaunchView.home()
                .environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(view)
    }
    
    public static func showRecentTickets() {
        Task {
            let _ = await InternetConnectionListener.shared.startListening()
            validateToken()
            recentTicketsView()
        }
    }

    private static func recentTicketsView() {
        let view: AnyView = AnyView(
            AppLaunchView.recentTickets()
                .environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(view)
    }
    
    public static func showArticle(articleId: Int, articleSlugTitle: String) {
        Task {
            let _ = await InternetConnectionListener.shared.startListening()
            validateToken()
            articleView(articleId: articleId, articleSlugTitle: articleSlugTitle)
        }
    }
    
    private static func articleView(articleId: Int, articleSlugTitle: String) {
        let view: AnyView = AnyView(
            AppLaunchView.article(articleId: articleId, articleSlugTitle: articleSlugTitle)
                .environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(view)
    }

    private static func accessdeniedView() {
        let view: AnyView = AnyView(
            AccessDeniedView()
                .environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(view)
    }

    private static func isShowAccessDeniedView() -> Bool {
        if AppConstant.appId.isEmpty || AppConstant.brandURl.isEmpty {
            return true
        }
        return false
    }

    public static func enableLogging() {
        NetworkLogger.isEnabled = true
    }

    public static func enablePushNotification(fcmToken: String) {
        self.fcmToken = fcmToken
    }

    private static func setFCMRegistrationToken() {
        Task {
            do {
                let response = try await loginBL.setFCMRegistrationToken(
                    deviceToken: fcmToken!
                )
                if response.isSuccess {
                    AppConstant.deviceToken = fcmToken ?? ""
                } else {
                    ErrorLogs.logErrors(
                        data: response.data,
                        isCatchError: false
                    )
                }
            } catch {
                ErrorLogs.logErrors(
                    data: error,
                    exceptionPage: "initialize in BDSupportSDK",
                    isCatchError: true,
                    stackTrace: Thread.callStackSymbols.joined(separator: "\n")
                )
            }
        }
    }

    private static func deleteFCMRegistrationToken() async {
        do {
            let response = try await loginBL.deleteFCMRegistrationToken()
            if response.isSuccess {
                AppConstant.deviceToken = ""
            } else {
                ErrorLogs.logErrors(
                    data: response.data,
                    isCatchError: false
                )
            }
        } catch {
            ErrorLogs.logErrors(
                data: error,
                exceptionPage: "initialize in BDSupportSDK",
                isCatchError: true,
                stackTrace: Thread.callStackSymbols.joined(separator: "\n")
            )
        }
    }

    public static func isFromMobileSDK(userInfo: [AnyHashable: Any]) -> Bool {
        let data =
            (userInfo["data"] as? [String: Any]) ?? (userInfo as? [String: Any])
        return data?.keys.contains("isFromSDK") ?? false
    }

    @discardableResult
    public static func processRemoteNotification(userInfo: [AnyHashable: Any])
        -> Bool
    {
        Task {
            await InternetConnectionListener.shared.startListening()
        }
        getAppDetails(brandUrl: AppConstant.brandURl)
        if AppConstant.environment != "development" {
            initializeSentry()
        }
        let data =
            (userInfo["data"] as? [String: Any]) ?? (userInfo as? [String: Any])
        let idString = data?["id"] as? String
        let id = Int(idString ?? "") ?? (data?["id"] as? Int) ?? 0
        guard id != 0 else { return false }

        // Replace whatever is showing with the ticket detail screen.
        let view = AnyView(
            AppLaunchView.ticketDetail(ticketId: id, openedFromPush: true)
                .environmentObject(ToastManager.shared)
                .id("\(UUID().uuidString)")
        )
        presentOrReplaceRoot(view)
        return true
    }
    
    @discardableResult
    public static func openTicketDetailsView(ticketId: Int)
        -> Bool
    {
        // Replace whatever is showing with the ticket detail screen.
        let view = AnyView(
            AppLaunchView.ticketDetail(ticketId: ticketId, openedFromPush: true)
                .environmentObject(ToastManager.shared)
                .id("\(UUID().uuidString)")
        )
        presentOrReplaceRoot(view)
        return true
    }
    
    public private(set) static var onTicketCreatedEventCallBack: ((String, String?) -> Void)?

    internal static func navigateToTicketList() {
        let view = AnyView(
            TicketListView()
                .environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(view)
    }

    private static func initializeDefaultItems() {
        let SVGCoder = SDImageSVGCoder.shared
        SDImageCodersManager.shared.addCoder(SVGCoder)
        guard !fontsRegistered else { return }
        ResourceManager.registerFonts([
            "Inter-Regular.ttf",
            "Inter-Medium.ttf",
            "Inter-SemiBold.ttf",
            "Inter-Bold.ttf",
            "CustomIcons.ttf",
        ])
        fontsRegistered = true
    }

    private static func presentSwiftUIView<Content: View>(_ view: Content) {
        let wrapped = AnyView(
            view.environmentObject(ToastManager.shared)
        )
        presentOrReplaceRoot(wrapped)
    }

    // Presents or replaces the root SwiftUI view within the SDK's hosting controller.
    // Ensures only one active UIHostingController is used to display SDK screens.
    private static func presentOrReplaceRoot(
        _ view: AnyView,
        retryCount: Int = 0,
        isShowDialog: Bool = false
    ) {
        DispatchQueue.main.async {
            setup()

            // Defines the logic for presenting or updating the existing hosting controller.
            let presentBlock = {
                if let hc = hostingController,
                    hc.presentingViewController != nil
                {
                    // Case 1: Hosting controller is already presented — just replace its root view.
                    hc.rootView = view
                } else if let hc = hostingController {
                    // Case 2: Hosting controller exists but not currently presented — present it.
                    // Note: The hc variable is already of type PortraitHostingController from the first creation.
                    hc.rootView = view
                    hc.modalPresentationStyle = .fullScreen
                    if let topVC = topViewController() {
                        topVC.present(hc, animated: true)
                    }
                } else {
                    // Case 3: No existing hosting controller — create and present a new, portrait-locked one.
                    let hc = UIHostingController(
                        rootView: view.environmentObject(ToastManager.shared)  // ✅ Inject once
                    )
                    // Detect device type (iPad vs iPhone)
                    if DeviceConfig.isIPad && isShowDialog {
                        // iPad → show as dialog
                        hc.modalPresentationStyle = .formSheet
                        let screenSize = UIScreen.main.bounds.size
                        let width =
                            DeviceConfig.isPortrait
                            ? screenSize.width * 0.75 : screenSize.width * 0.55
                        let height =
                            DeviceConfig.isPortrait
                            ? screenSize.height * 0.55 : screenSize.height * 0.7
                        hc.preferredContentSize = CGSize(
                            width: width,
                            height: height
                        )
                    } else {
                        // iPhone → full screen
                        hc.modalPresentationStyle = .fullScreen
                    }

                    if let topVC = topViewController() {
                        topVC.present(hc, animated: true)
                    }
                }
            }

            // Retry logic: waits until a top view controller is available before presenting.
            if topViewController() == nil {
                if retryCount < 2 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        presentOrReplaceRoot(view, retryCount: retryCount + 1)
                    }
                }
                return
            }
            presentBlock()

        }
    }

    // Finds the top-most view controller to present from
    private static func topViewController(base: UIViewController? = nil)
        -> UIViewController?
    {
        if !Thread.isMainThread {
            return DispatchQueue.main.sync {
                return topViewController(base: base)
            }
        }

        // Find active window scene
        let windowScene = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }

        // Find key window from that scene
        let keyWindow = windowScene?
            .windows
            .first(where: { $0.isKeyWindow })

        let root = base ?? keyWindow?.rootViewController

        if let nav = root as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(base: tab.selectedViewController)
        }
        if let presented = root?.presentedViewController {
            return topViewController(base: presented)
        }
        return root
    }

    private static func getAppDetails(brandUrl: String) {
        let device = UIDevice.current
        AppConstant.deviceName = device.name
        AppConstant.osVersion = device.systemVersion
        AppConstant.clientAppName =
            Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "UnknownApp"
        let applicationInfo =
            "Device Name - \(AppConstant.deviceName), IOSVersion - \(AppConstant.osVersion), App Name - \(AppConstant.clientAppName), SDK Version - \(AppConstant.sdkVersion), Brand URL - \(brandUrl)"

        AppConstant.applicationInfo = applicationInfo
    }
}

extension UIColor {
    static func fromHex(_ hex: String) -> UIColor? {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexString.hasPrefix("#") { hexString.removeFirst() }

        guard hexString.count == 6,
            let rgbValue = UInt64(hexString, radix: 16)
        else {
            return nil
        }

        let red = CGFloat((rgbValue >> 16) & 0xFF) / 255.0
        let green = CGFloat((rgbValue >> 8) & 0xFF) / 255.0
        let blue = CGFloat(rgbValue & 0xFF) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}

extension Color {
    static func fromHex(_ hex: String) -> Color? {
        guard let uiColor = UIColor.fromHex(hex) else { return nil }
        return Color(uiColor)
    }
}
