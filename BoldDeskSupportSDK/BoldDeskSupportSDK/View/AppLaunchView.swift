import SwiftUI

struct AppLaunchView: View {
    @EnvironmentObject var appSettingManager: AppSettingsManager
    @StateObject var dateTimeManager = DateTimeSettingManager.shared
    @StateObject private var viewModel = AppInfoViewModel()
    @State private var isConnected: Bool
    @Environment(\.presentationMode) private var presentationMode

    enum Destination {
        case home
        case recentTickets
        case knowledgeBase
        case createTicket
        case ticketDetail(ticketId: Int, openedFromPush: Bool)
        case article(articleId: Int, articleSlugTitle: String)
    }

    private let destination: Destination
    private let ticketId: Int?
    private let openedFromPush: Bool

    private init(
        destination: Destination,
        ticketId: Int? = nil,
        openedFromPush: Bool = false
    ) {
        self.destination = destination
        self.ticketId = ticketId
        self.openedFromPush = openedFromPush
        let connectionStatus = InternetConnectionListener.shared.isConnected
        self.isConnected = connectionStatus
    }

    static func home() -> AppLaunchView {
        AppLaunchView(destination: .home)
    }

    static func recentTickets() -> AppLaunchView {
        AppLaunchView(destination: .recentTickets)
    }

    static func knowledgeBase() -> AppLaunchView {
        AppLaunchView(destination: .knowledgeBase)
    }

    static func createTicket() -> AppLaunchView {
        AppLaunchView(destination: .createTicket)
    }

    static func ticketDetail(ticketId: Int, openedFromPush: Bool = false)
        -> AppLaunchView
    {
        AppLaunchView(
            destination: .ticketDetail(
                ticketId: ticketId,
                openedFromPush: openedFromPush
            ),
            ticketId: ticketId,
            openedFromPush: openedFromPush
        )
    }

    static func article(articleId: Int, articleSlugTitle: String)
        -> AppLaunchView
    {
        AppLaunchView(
            destination: .article(
                articleId: articleId,
                articleSlugTitle: articleSlugTitle
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.initializeFailed && !BDSupportSDK.isFromChatSDK {
                AccessDeniedView()
            } else if !isDataReadyForDestination && !BDSupportSDK.isFromChatSDK {
                if self.isConnected{
                    loadingViewForDestination()
                        .onAppear {
                            Task {
                                await viewModel.loadAppInfo()
                            }
                        }
                } else {
                    AppPage {
                        VStack {
                            switch destination {
                            case .createTicket:
                                if DeviceType.isTablet {
                                    DialogAppBar(
                                        title: ResourceManager.localized(
                                            "createTicket",
                                            comment: ""
                                        ),
                                        actionButtons: [],
                                        onBack: {
                                            presentationMode.wrappedValue
                                                .dismiss()
                                        }
                                    )
                                } else {
                                    CommonAppBar(
                                        title: appBarTitle,
                                        showBackButton: true,
                                        onBack: {
                                            presentationMode.wrappedValue
                                                .dismiss()
                                        }
                                    )
                                }

                            case .ticketDetail(let id, _):
                                CommonAppBar(
                                    title: "# \(id)",
                                    showBackButton: true,
                                    onBack: {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                )

                            default:
                                CommonAppBar(
                                    title: appBarTitle,
                                    showBackButton: true,
                                    onBack: {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                )
                            }
                            NoInternetView {
                                let connectionStatus =
                                    InternetConnectionListener.shared
                                    .isConnected
                                self.isConnected = connectionStatus
                            }
                        }
                    }
                }
            } else {
                switch destination {
                case .home:
                    if KnowledgeBase.isEnabled
                        && (KnowledgeBase.visiblityOptionId == 1
                            || (KnowledgeBase.visiblityOptionId == 2
                                && BDSupportSDK.isLoggedIn()))
                        || (!BDSupportSDK.isLoggedIn()
                            ? GeneralSettings
                                .allowUnauthenticatedUserToCreateTicket
                            : true)
                    {
                        HelpCenterView()
                    } else {
                        CommonAccessDeniedView.home()
                    }
                case .recentTickets:
                    if (!BDSupportSDK.isLoggedIn()
                            ? GeneralSettings
                                .allowUnauthenticatedUserToCreateTicket
                            : true)
                    {
                        HelpCenterView.withRecentTickets()
                    } else {
                        CommonAccessDeniedView.home()
                    }

                case .knowledgeBase:
                    if KnowledgeBase.isEnabled
                        && (KnowledgeBase.visiblityOptionId == 1
                            || (KnowledgeBase.visiblityOptionId == 2
                                && BDSupportSDK.isLoggedIn()))
                    {
                        KnowledgeBaseView()
                    } else {
                        CommonAccessDeniedView.knowledgeBase()
                    }

                case .createTicket:
                    if BDSupportSDK.isFromChatSDK || (AppConstant.authToken.isEmpty
                        ? GeneralSettings.allowUnauthenticatedUserToCreateTicket
                            && ContactUs.isEnabled : ContactUs.isEnabled)
                    {
                        CreateTicket()
                    } else {
                        CommonAccessDeniedView.createTicket()
                    }

                case .ticketDetail(let ticketId, _):
                    if !AppConstant.authToken.isEmpty {
                        TicketDetailView(ticketId: ticketId)
                    } else {
                        CommonAccessDeniedView.ticketDetail(ticketId: ticketId)
                    }
                case .article(let articleId, let articleName):
                    if KnowledgeBase.isEnabled
                        && (KnowledgeBase.visiblityOptionId == 1
                            || (KnowledgeBase.visiblityOptionId == 2
                                && BDSupportSDK.isLoggedIn())) || BDSupportSDK.isFromChatSDK
                    {
                        HTMLWebView(
                            articleId: articleId,
                            articleName: articleName
                        )
                    } else {
                        CommonAccessDeniedView.knowledgeBase()
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .ignoresSafeArea()
    }

    private var isDataReadyForDestination: Bool {
        switch destination {
        case .knowledgeBase, .article:
            return viewModel.hasLoadedGeneralSettings

        case .home, .createTicket, .ticketDetail, .recentTickets:
            if AppConstant.authToken.isEmpty {
                return viewModel.hasLoadedGeneralSettings
            } else {
                return viewModel.hasLoadedGeneralSettings
                    && viewModel.hasLoadedUserInfo
            }
        }
    }

    @ViewBuilder
    private func loadingViewForDestination() -> some View {
        switch destination {
        case .home:
            HelpCenterLoadingView()
        case .recentTickets:
            HelpCenterLoadingView()
        case .knowledgeBase:
            KnowledgeBaseView.shimmerPage()
        case .article:
            HTMLWebView.shimmerPage()
        case .createTicket:
            CreateTicket.shimmerPage()
        case .ticketDetail:
            TicketDetailView.shimmerPage()
        }
    }

    private var appBarTitle: String {
        switch destination {
        case .home, .recentTickets:
            return BDSDKHome.appBarTitle ?? ResourceManager.localized("helpCenterText", comment: "")
        case .knowledgeBase, .article:
            return ResourceManager.localized("knowledgeBaseText", comment: "")
        case .createTicket:
            return ResourceManager.localized("createTicket", comment: "")
        case .ticketDetail:
            return ResourceManager.localized("ticketDetailText", comment: "")
        }
    }
}

struct CommonAccessDeniedView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var toastManager: ToastManager

    let ticketId: Int?

    enum Destination {
        case home
        case knowledgeBase
        case createTicket
        case ticketDetail
    }

    private let destination: Destination

    private init(destination: Destination, ticketId: Int? = nil) {
        self.destination = destination
        self.ticketId = ticketId
    }

    static func home() -> CommonAccessDeniedView {
        CommonAccessDeniedView(destination: .home)
    }

    static func knowledgeBase() -> CommonAccessDeniedView {
        CommonAccessDeniedView(destination: .knowledgeBase)
    }

    static func createTicket() -> CommonAccessDeniedView {
        CommonAccessDeniedView(destination: .createTicket)
    }

    static func ticketDetail(ticketId: Int) -> CommonAccessDeniedView {
        CommonAccessDeniedView(destination: .ticketDetail, ticketId: ticketId)
    }

    var body: some View {
        AppPage {
            VStack(spacing: 0) {
                if destination == .createTicket && DeviceType.isTablet {
                    DialogAppBar(
                        title: ResourceManager.localized(
                            "createTicket",
                            comment: ""
                        ),
                        actionButtons: [],
                        onBack: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                } else {
                    CommonAppBar(
                        title: (destination == .ticketDetail && ticketId != nil)
                            ? "# \(ticketId!)" : appBarTitle,
                        showBackButton: true,
                        onBack: {
                            presentationMode.wrappedValue.dismiss()
                        }
                    )
                }
                Spacer()
                VStack(alignment: .center, spacing: 12) {
                    Text(
                        ResourceManager.localized(
                            "accessDeniedText",
                            comment: ""
                        )
                    )
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(.textSecondaryColor)

                    Text(loadingMessage)
                        .font(
                            FontFamily.customFont(
                                size: FontSize.small,
                                weight: .regular
                            )
                        )
                        .foregroundColor(.textTeritiaryColor)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 12)
                }

                Spacer()
            }
        }
    }

    private var appBarTitle: String {
        switch destination {
        case .home:
            return BDSDKHome.appBarTitle ?? ResourceManager.localized("helpCenterText", comment: "")
        case .knowledgeBase:
            return ResourceManager.localized("knowledgeBaseText", comment: "")
        case .createTicket:
            return ResourceManager.localized("createTicket", comment: "")
        case .ticketDetail:
            return ResourceManager.localized("ticketDetailText", comment: "")
        }
    }

    private var loadingMessage: String {
        switch destination {
        case .home:
            return ResourceManager.localized(
                "homePageAccessDeniedText",
                comment: ""
            )
        case .knowledgeBase:
            return ResourceManager.localized(
                "kbPageAccessDeniedText",
                comment: ""
            )
        case .createTicket:
            return ResourceManager.localized(
                "createTicketAccessDeniedText",
                comment: ""
            )
        case .ticketDetail:
            return ResourceManager.localized(
                "ticketDetailPageAccessDeniedText",
                comment: ""
            )
        }
    }
}

struct HelpCenterLoadingView: View {
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var toastManager: ToastManager

    var body: some View {
        AppPage {
            VStack(spacing: 0) {
                CommonAppBar(
                    title: BDSDKHome.appBarTitle ?? ResourceManager.localized(
                        "helpCenterText",
                        comment: ""
                    ),
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )

                Spacer()
                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle(tint: Color.accentColor)
                    )
                Spacer()
                PoweredByFooterView()
            }
            .background(Color.backgroundPrimary)
        }
        .overlay(ToastStackView())
    }
}
