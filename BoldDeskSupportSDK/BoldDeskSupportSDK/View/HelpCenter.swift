import SwiftUI

struct HelpCenterView: View {
    @State private var isShow = false
    @Environment(\.presentationMode) private var presentationMode
    @EnvironmentObject var toastManager: ToastManager
    private let withRecentTickets: Bool
    @StateObject private var homeViewModel: HomeViewModel
    @State private var needsRefresh: Bool = false
    
    init(withRecentTickets: Bool = false) {
        self.withRecentTickets = withRecentTickets
        let vm = HomeViewModel()
        vm.isLoading = withRecentTickets && !AppConstant.authToken.isEmpty
        _homeViewModel = StateObject(wrappedValue: vm)
        
        if withRecentTickets && !AppConstant.authToken.isEmpty {
            Task {
                await vm.loadInitialTickets()
            }
        }
    }
    
    static func withRecentTickets() -> HelpCenterView {
        HelpCenterView(withRecentTickets: true)
    }
    
    private var isCreateTicketOnlyEnabled: Bool {
        !canViewTickets && !isKBEnabled
        && GeneralSettings.allowUnauthenticatedUserToCreateTicket
        && ContactUs.isEnabled
    }
    
    private var canViewTickets: Bool {
        !AppConstant.authToken.isEmpty
    }
    
    private var isKBEnabled: Bool {
        (self.withRecentTickets ? false : KnowledgeBase.isEnabled
         && (KnowledgeBase.visiblityOptionId == 1
             || (KnowledgeBase.visiblityOptionId == 2
                 && BDSupportSDK.isLoggedIn())))
    }
    
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
                if !withRecentTickets || (withRecentTickets ? AppConstant.authToken.isEmpty : false) {
                    commonHelpCenterBody()
                } else {
                    if homeViewModel.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(
                                CircularProgressViewStyle(tint: Color.accentColor)
                            )
                        Spacer()
                    } else if !homeViewModel.recentTickets.isEmpty {
                        recentTicketsSection()
                    }
                    else {
                        commonHelpCenterBody()
                    }
                }
                PoweredByFooterView()
            }
            .background(
                homeViewModel.recentTickets.isEmpty ?
                Color.backgroundPrimary.ignoresSafeArea() :
                Color.backgroundTeritiaryColor.ignoresSafeArea())
            .overlay(
                Group {
                    if !isShow {
                        ToastStackView()
                    }
                }
            )
        }
    }
    
    @ViewBuilder
    private func recentTicketsSection() -> some View {
        VStack(spacing: 0) {
            HStack {
                Text(ResourceManager.localized("recentTicketText", comment: ""))
                    .foregroundColor(Color.textSecondaryColor)
                    .font(
                        FontFamily.customFont(
                            size: DeviceType.isPhone ? FontSize.large : FontSize.xlarge,
                            weight: .semibold
                        )
                    )

                Spacer()

                TextButton.themed(title: ResourceManager.localized("viewAllText", comment: ""), onClick: {
                    NavigationHelper.push(
                        TicketListView()
                            .environmentObject(ToastManager.shared)
                    )
                })
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(homeViewModel.recentTickets.indices, id: \.self) { idx in
                        let ticket = homeViewModel.recentTickets[idx]
                        NavigationLink(destination:
                                        TicketDetailView(
                                            ticketId: ticket.ticketId,
                                            needsRefresh: $needsRefresh,
                                            canViewMyOrgTickets: false
                                        )
                        ) {
                            TicketCardView(ticketModel: ticket)
                        }
                    }
                }
                .padding(.horizontal, DeviceType.isPhone ? 16 : 20)
            }

            Spacer()

            VStack(spacing: 0) {
                submitTicketButton()
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.vertical, DeviceType.isPhone ? 16 : 22)
            .background(Color.cardBackgroundPrimary)
        }
        .sheet(isPresented: $isShow) {
            CreateTicket()
                .background(Color.backgroundOverlayColor)
                .presentationCornerRadius(12)
        }
    }

    @ViewBuilder
    private func commonHelpCenterBody() -> some View {
        VStack(spacing: 16) {
            VStack(spacing: 0) {
                NetworkImageViewForHome(imageUrl: BDSDKHome.logoURL)
                    .padding(.bottom, 12)
                
                Text(
                    BDSDKHome.headerName
                    ?? ResourceManager.localized(
                        "welcomeText",
                        comment: ""
                    )
                )
                .font(
                    FontFamily.customFont(
                        size: FontSize.large,
                        weight: .semibold
                    )
                )
                
                .foregroundColor(.textPrimary)
                .padding(.bottom, 6)
                Text(
                    BDSDKHome.headerDescription
                    ?? ResourceManager.localized(
                        "howCanWeHelpText",
                        comment: ""
                    )
                )
                .font(
                    FontFamily.customFont(
                        size: FontSize.medium,
                        weight: .medium
                    )
                )
                
                .foregroundColor(.textTeritiaryColor)
                .padding(.bottom, 4)
                
            }
            .padding(.top, DeviceConfig.isIPhone ? 48 : 32)
            
            VStack(spacing: 12) {
                if DeviceType.isTablet && isCreateTicketOnlyEnabled {
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: 48)
                        haveAQueryText()
                        submitButtonView()
                        Spacer()
                    }
                }
                if isKBEnabled {
                    NavigationLink(destination: KnowledgeBaseView()) {
                        HelpCenterCard(
                            icon: .knowledgeBase,
                            iconBackgroundColor: Color.utilityPurple,
                            title: BDSDKHome.kbTitle
                            ?? ResourceManager.localized(
                                "knowledgeBaseText"
                            ),
                            description: BDSDKHome.kbDescription
                            ?? ResourceManager.localized(
                                "knowledgeBaseDescriptionText"
                            )
                        )
                    }
                }
                if canViewTickets {
                    NavigationLink(destination: TicketListView()) {
                        HelpCenterCard(
                            icon: .ticket,
                            iconBackgroundColor: Color.utilitySuccess,
                            title: BDSDKHome.ticketTitle
                            ?? ResourceManager.localized(
                                "ticketText"
                            ),
                            description: BDSDKHome.ticketDescription
                            ?? ResourceManager.localized(
                                "ticketDescriptionText",
                                comment: ""
                            )
                        )
                    }
                }
            }
            Spacer()
            VStack(spacing: 0) {
                submitTicketButton()
            }
            .sheet(isPresented: $isShow) {
                CreateTicket()
                    .background(Color.backgroundOverlayColor)
                    .presentationCornerRadius(12)
            }
            .padding(.top, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(homeViewModel.recentTickets.isEmpty ? Color.backgroundPrimary : Color.backgroundTeritiaryColor)
        .padding(.horizontal, DeviceConfig.isIPhone ? 12 : 84)
    }
    
    @ViewBuilder
    private func submitButtonView() -> some View {
        FilledButton(
            title: ResourceManager.localized("submitRequestText", comment: ""),
            onClick: {
                isShow = true
            },
            isSmall: true
        )
        .padding(.bottom, withRecentTickets ? 20 : 54)
        .frame(width: UIScreen.main.bounds.width * 0.38)
    }
    
    @ViewBuilder
    private func submitTicketButton() -> some View {
        if AppConstant.authToken.isEmpty
            ? GeneralSettings
            .allowUnauthenticatedUserToCreateTicket
            && ContactUs.isEnabled : ContactUs.isEnabled
        {
            if DeviceType.isPhone
                ? true : !isCreateTicketOnlyEnabled
            {
                haveAQueryText()
            }
            if DeviceType.isPhone {
                NavigationLink(
                    destination: CreateTicket(),
                    label: {
                        Text(BDSDKHome.submitButtonText ?? ResourceManager.localized("submitRequestText", comment: ""))
                            .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                            .frame(maxWidth: .infinity, maxHeight: 32)
                            .background(Color.accentColor)
                            .foregroundColor(Color.backgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    }
                )
                .padding(.horizontal, 39.5)
                .padding(.bottom, withRecentTickets ? 12 : 54)
            } else {
                if !isCreateTicketOnlyEnabled {
                    submitButtonView()
                }
            }
        }
    }
    
    @ViewBuilder
    private func haveAQueryText() -> some View {
        Text(ResourceManager.localized("haveAQueryText", comment: ""))
            .font(
                FontFamily.customFont(size: FontSize.medium, weight: .semibold)
            )
        
            .foregroundColor(.textSecondaryColor)
            .padding(.bottom, 4)
        Text(ResourceManager.localized("contactSupportText", comment: ""))
            .font(
                FontFamily.customFont(size: FontSize.medium, weight: .regular)
            )
        
            .foregroundColor(.textTeritiaryColor)
            .multilineTextAlignment(.center)
            .padding(.bottom, 16)
    }
}

struct HelpCenterCard: View {
    let icon: AppIcons
    let iconBackgroundColor: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Rectangle()
                    .frame(width: 32, height: 32)
                    .foregroundColor(iconBackgroundColor)
                    .cornerRadius(6)
                
                AppIcon(icon: icon, size: 16, color: .iconColor)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .semibold
                        )
                    )
                
                    .foregroundColor(.textSecondaryColor)
                
                Text(description)
                    .font(
                        FontFamily.customFont(
                            size: FontSize.small,
                            weight: .regular
                        )
                    )
                
                    .foregroundColor(.textTeritiaryColor)
                    .fixedSize(horizontal: false, vertical: true)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
        }
        .padding(DeviceConfig.isIPhone ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.borderSecondaryColor, lineWidth: 1)
                .background(Color.cardBackgroundPrimary.cornerRadius(10))
        )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = 12
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    HelpCenterView()
}
