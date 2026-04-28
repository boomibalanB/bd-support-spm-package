import SwiftUI
import UIKit

struct TicketDetailView: View {
    @Namespace private var scrollViewCoordinateSpaceName
    @Environment(\.presentationMode) var presentationMode
    //Tabview layout
    @State private var currentTab: TicketDetailTabs = .messages
    @State private var isTabContentFullScreen: Bool = false
    @State private var navBarBottomPosition: CGFloat =
        DeviceConfig.isIPhone ? 56 : 56
    @State private var stickyTabsYOffset: CGFloat = 0
    @State private var tabContentTopPosition: CGFloat = 0.0

    @State private var showCloseTicketPopup: Bool = false
    @State private var showDeleteDescriptionPopup: Bool = false
    @State private var showDeleteMessagePopup: Bool = false

    //Ticket Details
    @State private var isHeaderExpanded: Bool = false
    @StateObject private var ticketDetailViewModel: TicketDetailViewModel
    @StateObject private var keyboardObserver = KeyboardObserver()
    //Pull to refresh layout
    @State private var refresh = Refresh(
        started: false,
        released: false,
        isInvalid: false
    )
    @State private var currentOffset: CGFloat = 0
    @State var messagesCount: Int = 0
    @State var isMessagesLoading: Bool = true
    @State private var isBounceEnabled: Bool = false

    @State private var messageTabToken: UUID = UUID()
    @EnvironmentObject var toastManager: ToastManager

    @State private var showReplyPage = false

    @State private var disableDismiss = false

    @State private var isInProgress = false

    private var pullProgress: Double {
        let maxPullDistance: CGFloat = 80
        let currentPull = max(0, refresh.offset - refresh.startOffset)
        return min(1.0, Double(currentPull / maxPullDistance))
    }

    private var isSaveEnabled: Bool {
        let trimmedNew = subjectText.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let trimmedOld =
            ticketDetailViewModel.ticketDetails?.title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ) ?? ""

        return !trimmedNew.isEmpty && trimmedNew != trimmedOld
            && !ticketDetailViewModel.isUpdatingSubject
    }

    @State private var isShowEditSubjectIphone = false
    @State private var isShowEditSubjectIpad = false
    @State private var isEditSubjectFocused = false
    @State private var subjectText: String = ""

    @State private var selectedAttachment: Attachment? = nil
    @State private var selectedMessage: Message? = nil

    @State private var isShowingDeleteAttachmentPopup: Bool = false
    @State private var isShowingAttachmentOptions = false

    @State private var isShowingMessageAttachmentOptions: Bool = false
    @State private var isShowingDeleteMessageAttachmentPopup: Bool = false

    @State private var triggerMessageAttachmentDelete: Bool = false
    @State private var triggerMessageAttachmentDownload: Bool = false
    @State private var triggerMessageDelete: Bool = false

    @State private var isNetworkConnected: Bool = true

    @State private var currentTicketId: Int? = nil

    @State private var isOnlineImagePreviewOpen = false

    @State private var ensureCloseTicketActionRestriction: Bool = true
    @State private var canViewMyOrgTickets: Bool = false
    
    @State private var showSubjectPlaceholder = false

    private let isForShimmer: Bool

    @Binding var needsRefresh: Bool
    private var isFromSearchPage: Bool = false

    init(
        ticketId: Int,
        isForShimmer: Bool = false,
        needsRefresh: Binding<Bool>? = nil,
        canViewMyOrgTickets: Bool = false,
        isFromSearchPage: Bool = false
    ) {
        self._ticketDetailViewModel = StateObject(
            wrappedValue: TicketDetailViewModel(ticketId: ticketId)
        )
        self._currentTicketId = State(initialValue: ticketId)
        self.isForShimmer = isForShimmer
        self._needsRefresh = needsRefresh ?? .constant(false)
        self._canViewMyOrgTickets = State(initialValue: canViewMyOrgTickets)
        self.isFromSearchPage = isFromSearchPage
    }

    static func shimmerPage() -> TicketDetailView {
        TicketDetailView(ticketId: 0, isForShimmer: true)
    }

    private var canCloseTicket: Bool {
        guard
            let requesterId = ticketDetailViewModel.ticketDetails?.requester
                .userId,
            let currentUserId = UserInfo.userId
        else {
            return false
        }

        return (requesterId == currentUserId
            || (!GeneralSettings.isMyOrganizationViewDisabledInCustomerPortal
                && canViewMyOrgTickets))
                && ticketDetailViewModel.ticketDetails?.ticketStatusId != 5
                && !GeneralSettings.restrictClosingTicketViaCustomerPortal
    }

    var body: some View {
        if ticketDetailViewModel.isShowAccessDeniedPage {
            AccessDeniedView(
                appBarTitle: currentTicketId != nil
                    ? "# \(currentTicketId!)" : "# --",
                description: ResourceManager.localized(
                    "ticketNotExistText",
                    comment: ""
                ),
                onBack: {
                    needsRefresh = ticketDetailViewModel.isShowAccessDeniedPage
                    presentationMode.wrappedValue.dismiss()
                }
            )
        } else {
            AppPage {
                ZStack(alignment: .bottom) {
                    ZStack(alignment: .bottom) {
                        ZStack(alignment: .top) {
                            VStack(spacing: 0) {
                                CommonAppBar(
                                    title: currentTicketId != nil
                                        ? "# \(currentTicketId!)" : "# --",
                                    showBackButton: true,
                                    onBack: {
                                        presentationMode.wrappedValue
                                            .dismiss()
                                    }
                                ) {
                                    if DeviceConfig.isIPad {
                                        actionButtons()
                                    }
                                }
                                NetworkWrapper(
                                    content: {
                                        ZStack(alignment: .top) {
                                            ScrollViewReader { scrollProxy in
                                                ScrollView(
                                                    showsIndicators: false
                                                ) {
                                                    VStack(spacing: 0) {
                                                        Color.clear
                                                            .frame(
                                                                width: 0,
                                                                height: 0
                                                            )
                                                            .background(
                                                                scrollOffsetReader()
                                                            )
                                                        headerView
                                                            .opacity(
                                                                currentOffset
                                                                    > 0 ? 0 : 1
                                                            )
                                                            .zIndex(
                                                                currentOffset
                                                                    > 0 ? -1 : 1
                                                            )
                                                            .background(
                                                                GeometryGetter(
                                                                    refresh:
                                                                        $refresh
                                                                ) {
                                                                    messageTabToken =
                                                                        UUID()
                                                                }
                                                            )
                                                        Spacer().frame(
                                                            height: 8
                                                        )
                                                        ZStack {
                                                            StickyTabs(
                                                                currentTab:
                                                                    $currentTab,
                                                                yOffset:
                                                                    .constant(
                                                                        0
                                                                    ),
                                                                messagesCount:
                                                                    $messagesCount
                                                            )
                                                            .id(
                                                                HeightMarkers
                                                                    .headerBottomId
                                                            )
                                                            .readingFrame(
                                                                coordinateSpace:
                                                                    .named(
                                                                        scrollViewCoordinateSpaceName
                                                                    )
                                                            ) { frame in
                                                                tabContentTopPosition =
                                                                    frame.minY
                                                                isTabContentFullScreen =
                                                                    tabContentTopPosition
                                                                    <= navBarBottomPosition
                                                            }
                                                            .opacity(
                                                                currentOffset
                                                                    > 0 ? 0 : 1
                                                            )
                                                            .zIndex(
                                                                currentOffset
                                                                    > 0 ? -1 : 1
                                                            )
                                                            if currentTab
                                                                == .messages
                                                            {
                                                                RefreshIndicatorView(
                                                                    progress:
                                                                        pullProgress,
                                                                    isRefreshing:
                                                                        refresh
                                                                        .started
                                                                        && refresh
                                                                            .released
                                                                )
                                                            }
                                                        }
                                                        TabContentView(
                                                            ticketId:
                                                                currentTicketId
                                                                ?? 0,
                                                            currentTab:
                                                                $currentTab,
                                                            messagesCount:
                                                                $messagesCount,
                                                            isLoading:
                                                                $isMessagesLoading,
                                                            messageTabToken:
                                                                $messageTabToken,
                                                            selectedAttachment:
                                                                $selectedAttachment,
                                                            ensureCloseTicketActionRestriction:
                                                                $ensureCloseTicketActionRestriction,
                                                            isShimmer:
                                                                isForShimmer,
                                                            onAttachmentOptionTapped: {
                                                                isShowingMessageAttachmentOptions =
                                                                    true
                                                            },
                                                            onAttachmentDelete: {
                                                                isShowingDeleteMessageAttachmentPopup =
                                                                    true
                                                            },
                                                            onMessageDelete: {
                                                                message in
                                                                selectedMessage =
                                                                    message
                                                                DispatchQueue
                                                                    .main
                                                                    .asyncAfter(
                                                                        deadline:
                                                                            .now()
                                                                            + 0.25
                                                                    ) {
                                                                        showDeleteMessagePopup =
                                                                            true
                                                                    }
                                                            },
                                                            canViewMyOrgTickets:
                                                                canViewMyOrgTickets

                                                        )
                                                    }
                                                    .background(
                                                        Color
                                                            .tabBarViewBackgroundTeritiaryColor
                                                    )
                                                }
                                                .coordinateSpace(
                                                    name: "ticketDetail"
                                                )
                                                .onChange(of: currentTab) { _ in
                                                    isBounceEnabled =
                                                        currentTab == .messages
                                                        && !isMessagesLoading

                                                    DispatchQueue.main.async {
                                                        let isAlreadyAtTop =
                                                            tabContentTopPosition
                                                            <= navBarBottomPosition
                                                            + 1
                                                        if !isAlreadyAtTop
                                                            && currentTab
                                                                != .messages
                                                        {
                                                            withAnimation {
                                                                scrollProxy
                                                                    .scrollTo(
                                                                        HeightMarkers
                                                                            .headerBottomId,
                                                                        anchor:
                                                                            .top
                                                                    )
                                                            }
                                                        }
                                                    }
                                                }
                                                .onChange(of: isMessagesLoading)
                                                { _ in
                                                    DispatchQueue.main
                                                        .asyncAfter(
                                                            deadline: .now()
                                                                + 0.05
                                                        ) {
                                                            isBounceEnabled =
                                                                currentTab
                                                                == .messages
                                                                && !isMessagesLoading
                                                        }
                                                }
                                            }
                                            VStack(spacing: 8) {
                                                headerView
                                                    .opacity(
                                                        currentOffset > 0
                                                            ? 1 : 0
                                                    )
                                                    .zIndex(
                                                        currentOffset > 0
                                                            ? 1 : -1
                                                    )
                                                StickyTabs(
                                                    currentTab: $currentTab,
                                                    yOffset: .constant(0),
                                                    messagesCount:
                                                        $messagesCount
                                                )
                                                .opacity(
                                                    currentOffset > 0 ? 1 : 0
                                                )
                                                .zIndex(
                                                    currentOffset > 0 ? 1 : -1
                                                )
                                            }
                                            .zIndex(currentOffset > 0 ? 1 : -1)
                                        }
                                        .onAppear {
                                            if !isForShimmer {
                                                Task {
                                                    if isFromSearchPage {
                                                        await ticketDetailViewModel.getTicketProperties(ticketId: "\(currentTicketId ?? 0)")
                                                        self.canViewMyOrgTickets = ticketDetailViewModel.isMyOrgTicket
                                                    }
                                                    await ticketDetailViewModel.loadTicketDetails()
                                                }
                                            }
                                        }
                                    },
                                    onConnectionChange: { isConnected in
                                        isNetworkConnected = isConnected
                                    }
                                )
                                PoweredByFooterView()
                            }
                            .background(
                                Color.tabBarViewBackgroundTeritiaryColor
                            )
                            .coordinateSpace(
                                name: scrollViewCoordinateSpaceName
                            )

                            if isNetworkConnected {
                                StickyTabs(
                                    currentTab: $currentTab,
                                    yOffset: $navBarBottomPosition,
                                    messagesCount: $messagesCount
                                )
                                .opacity(isTabContentFullScreen ? 1 : 0)
                            }
                        }
                    }
                    if isNetworkConnected && DeviceConfig.isIPhone {
                        replyNotesFloatingButtons
                    }

                }
            }
            .onChange(of: selectedAttachment) { newAttachment in
                print("Attachment changed:", newAttachment?.name ?? "nil")
            }
            .onChange(of: ticketDetailViewModel.ticketDetails?.ticketStatusId) {
                _ in
                updateRestrictionState()
            }
            .onReceive(AppSettingsManager.shared.$settings) { _ in
                updateRestrictionState()
            }
            .overlay(
                Group {
                    if showCloseTicketPopup || showDeleteDescriptionPopup
                        || showDeleteMessagePopup
                    {
                        ConfirmationDialog(
                            title: ResourceManager.localized(
                                showCloseTicketPopup
                                    ? "closeTicketTitle"
                                    : "deleteDescriptionTitle"
                            ),
                            message: ResourceManager.localized(
                                showCloseTicketPopup
                                    ? "closeTicketMessage"
                                    : "deleteDescriptionMessage"
                            ),
                            confirmButtonText: ResourceManager.localized(
                                showCloseTicketPopup
                                    ? "closeTicketConfirm"
                                    : "deleteDescriptionConfirm"
                            ),
                            cancelButtonText: ResourceManager.localized(
                                "cancelText"
                            ),
                            onConfirm: {
                                if showCloseTicketPopup {
                                    showCloseTicketPopup = false
                                    Task {
                                        await ticketDetailViewModel.closeTicket()
                                    }
                                } else if showDeleteDescriptionPopup {
                                    showDeleteDescriptionPopup = false
                                    Task {
                                        await ticketDetailViewModel
                                            .deleteDescription()
                                    }
                                } else {
                                    showDeleteMessagePopup = false
                                    if selectedMessage?.id != nil {
                                        Task {
                                            await ticketDetailViewModel
                                                .deleteMessage(
                                                    messageId: selectedMessage?
                                                        .id ?? 0,
                                                    onMessageDeleted: {
                                                        messageTabToken = UUID()
                                                    }
                                                )
                                        }
                                    }
                                }
                            },
                            onCancel: {
                                showCloseTicketPopup = false
                                showDeleteDescriptionPopup = false
                                showDeleteMessagePopup = false
                            },
                            icon: showCloseTicketPopup ? .verifiedOk : .delete1,
                            isRed: showDeleteDescriptionPopup
                                || showDeleteMessagePopup
                        )
                        .zIndex(1)
                    }
                }
            )
            .sheet(isPresented: $showReplyPage) {
                ReplyView(
                    ticketId: ticketDetailViewModel.ticketDetails?.ticketId
                        ?? 0,
                    ticketTitle: ticketDetailViewModel.ticketDetails?.title
                        ?? "",
                    statusId: ticketDetailViewModel.ticketDetails?
                        .ticketStatusId ?? 0,
                    disableDismiss: $disableDismiss,
                    isInProgress: $isInProgress,
                    canCloseTicket: canCloseTicket,
                ) { shouldRefreshDetails in
                    disableDismiss = false
                    handleReplyCompletion(shouldRefreshDetails)
                }
                .environmentObject(ToastManager.shared)
                .presentationCornerRadius(12)
            }
            .bottomSheet(isPresented: $isShowEditSubjectIphone) { dismiss in
                editSubjectBottomSheet(dismiss: dismiss)
            }
            .bottomSheet(isPresented: $isShowingMessageAttachmentOptions) {
                dismiss in
                attachmentOptionsBottomSheet(
                    dismiss: dismiss,
                    onDelete: {
                        isShowingDeleteMessageAttachmentPopup = true
                    },
                    onDownload: {
                        if selectedAttachment != nil {
                            DownloadManager.shared.handleDownloadTapped(
                                attachment: selectedAttachment!,
                                dataToken: AppConstant.fileToken
                            )
                        }
                    }
                )
            }
            .bottomSheet(isPresented: $isShowingAttachmentOptions) { dismiss in
                attachmentOptionsBottomSheet(
                    dismiss: dismiss,
                    onDelete: {
                        isShowingDeleteAttachmentPopup = true
                    },
                    onDownload: {
                        if selectedAttachment != nil {
                            DownloadManager.shared.handleDownloadTapped(
                                attachment: selectedAttachment!,
                                dataToken: AppConstant.fileToken
                            )
                        }
                    }
                )
            }
            .overlay(
                deleteAttachmentPopup()
            )
            .sheet(isPresented: $isShowEditSubjectIpad) {
                editSubjectBottomSheet(dismiss: {
                    isShowEditSubjectIpad = false
                })
                .presentationCornerRadius(12)
            }
            .animation(
                .easeInOut(duration: 0.3),
                value: (showCloseTicketPopup && showDeleteDescriptionPopup)
            )
            .animation(
                .easeInOut(duration: 0.3),
                value: (showCloseTicketPopup && showDeleteDescriptionPopup)
            )
            .overlay(
                Group {
                    if ticketDetailViewModel.isInProgress || isInProgress {
                        LoadingOverlay()
                            .zIndex(2)
                    }
                }
            )
            .onReceive(
                NotificationCenter.default.publisher(
                    for: .toggleOnlineImagePreview
                )
            ) { _ in
                isOnlineImagePreviewOpen.toggle()
            }
            .animation(
                .easeInOut(duration: 0.3),
                value: ticketDetailViewModel.isInProgress
            )
            .overlay(
                Group {
                    if !showReplyPage && !isOnlineImagePreviewOpen {
                        ToastStackView()
                    }
                }
            )
        }
    }

    private func updateRestrictionState() {
        let requesterId = ticketDetailViewModel.ticketDetails?.requester.userId
        let currentUserId = UserInfo.userId
        if ticketDetailViewModel.ticketDetails?.ticketStatusId == 5 {
            ensureCloseTicketActionRestriction = !GeneralSettings.restrictActionsOnClosedTickets
            return
        }
        else {
            ensureCloseTicketActionRestriction = true
        }
        if requesterId != currentUserId && !(!GeneralSettings.isMyOrganizationViewDisabledInCustomerPortal && canViewMyOrgTickets) {
            ensureCloseTicketActionRestriction = !GeneralSettings.restrictCcUsersFromUpdatingTicket
        }
    }

    @ViewBuilder
    private func deleteAttachmentPopup() -> some View {
        if isShowingDeleteAttachmentPopup
            || isShowingDeleteMessageAttachmentPopup,
            let attachment = selectedAttachment
        {
            let isMessageAttachmentDelete =
                isShowingDeleteMessageAttachmentPopup
            AttachmentOptionsProvider.deleteAttachmentDialog(
                attachmentName: attachment.name,
                isPresented: isShowingDeleteAttachmentPopup
                    ? $isShowingDeleteAttachmentPopup
                    : $isShowingDeleteMessageAttachmentPopup,
                onDeleteConfirm: {
                    Task {
                        let isMessage = isMessageAttachmentDelete
                        await ticketDetailViewModel.deleteTicketAttachment(
                            attachmentId: attachment.id,
                            isMessageAttachment: isMessage,
                            onAttachmentDeleted: {
                                messageTabToken = UUID()
                            }
                        )
                    }
                }
            )
        }
    }

    enum HeightMarkers {
        static let headerBottomId = "header_bottom"
    }

    @ViewBuilder
    private func attachmentOptionsBottomSheet(
        dismiss: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        onDownload: @escaping () -> Void
    ) -> some View {
        if let attachmentName = selectedAttachment?.name {
            AttachmentOptionsProvider.attachmentOptionsView(
                attachmentName: attachmentName,
                isPresented: isShowingDeleteAttachmentPopup
                    ? $isShowingAttachmentOptions
                    : $isShowingMessageAttachmentOptions,
                onDownload: {
                    onDownload()
                    dismiss()
                },
                onDelete: {
                    isShowingAttachmentOptions = false
                    isShowingMessageAttachmentOptions = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        onDelete()
                    }
                },
                dismiss: dismiss
            )
        } else {
            EmptyView()
        }
    }

    @ViewBuilder
    private func editSubjectBottomSheet(dismiss: (() -> Void)?) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            if DeviceType.isPhone {
                Text(ResourceManager.localized("editSubjectText", comment: ""))
                    .font(
                        FontFamily.customFont(
                            size: FontSize.semilarge,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(Color.textPrimary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .padding(.bottom, 10)
                AdaptiveDivider(isDashed: false)
            } else {
                DialogAppBar(
                    title: ResourceManager.localized(
                        "editSubjectText",
                        comment: ""
                    ),
                    actionButtons: [
                        CustomAppBarAction.textButton(
                            text: ResourceManager.localized(
                                "saveText",
                                comment: ""
                            ),
                            action: {
                                isEditSubjectFocused = false
                                dismiss?()
                                Task {
                                    await ticketDetailViewModel.updateSubject(
                                        newSubject:
                                            subjectText.trimmingCharacters(
                                                in: .whitespacesAndNewlines
                                            )
                                    )
                                }
                            },
                            isDisabled: !isSaveEnabled
                        )
                    ],
                    onBack: {
                        isShowEditSubjectIpad = false
                    }
                )
            }
            MultilineTextEditor(
                text: $subjectText,
                isFocused: $isEditSubjectFocused,
                font: FontFamily.customUIFont(
                    size: FontSize.medium,
                    weight: .regular
                ),
                lineHeight: 20,
                isEditable: true,
                autoFocus: true,
                restrictNewLine: true,
                onChange: { newText in
                    showSubjectPlaceholder = newText.isEmpty
                },
                onFocusIn: {
                    showSubjectPlaceholder = false
                },
                onFocusOut: {
                    showSubjectPlaceholder = subjectText.isEmpty
                }
            )
            .disabled(false)
            .overlay(
                VStack {
                    HStack {
                        if showSubjectPlaceholder {
                            Text(
                                ResourceManager.localized(
                                    "enterSubjectText",
                                    comment: ""
                                )
                            )
                            .font(
                                FontFamily.customFont(
                                    size: FontSize.medium,
                                    weight: .regular
                                )
                            )
                            .foregroundColor(Color.textPlaceHolderColor)
                            .allowsHitTesting(false)
                        }
                        Spacer()
                    }
                    Spacer()
                }
            )
            .frame(
                maxHeight: DeviceType.isTablet
                    ? nil
                    : (keyboardObserver.isKeyboardVisible
                        ? UIScreen.main.bounds.height * 0.3
                        : UIScreen.main.bounds.height * 0.4)
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.backgroundPrimary)
            if DeviceType.isPhone {
                AdaptiveDivider(isDashed: false)

                HStack(spacing: 12) {
                    if DeviceType.isTablet {
                        Spacer()
                    }

                    FilledButton(
                        title: ResourceManager.localized(
                            "saveText",
                            comment: ""
                        ),
                        onClick: {
                            isEditSubjectFocused = false
                            dismiss?()
                            Task {
                                await ticketDetailViewModel.updateSubject(
                                    newSubject: subjectText.trimmingCharacters(
                                        in: .whitespacesAndNewlines
                                    )
                                )
                            }
                        },
                        isEnabled: isSaveEnabled,
                        isSmall: true
                    )

                    OutlinedButton(
                        title: ResourceManager.localized(
                            "discardText",
                            comment: ""
                        ),
                        onClick: {
                            isEditSubjectFocused = false
                            dismiss?()
                        },
                        isEnabled: !ticketDetailViewModel.isLoading,
                        isSmall: true
                    )

                    if DeviceType.isPhone {
                        Spacer()
                    }
                }
                .padding(.top, 12)
                .padding(.horizontal, 16)
                .padding(
                    .bottom,
                    DeviceType.isPhone
                        ? 4 : keyboardObserver.isKeyboardVisible ? 12 : 16
                )
            }
        }
        .onAppear {
            showSubjectPlaceholder = subjectText.isEmpty
        }
        .onDisappear {
            showSubjectPlaceholder = false
        }
    }

    @ViewBuilder
    private func scrollOffsetReader() -> some View {
        Color.clear
            .frame(height: 0)
            .background(
                GeometryReader { reader in
                    let frame = reader.frame(in: .named("ticketDetail"))
                    Color.clear
                        .onAppear {
                            currentOffset = frame.minY
                        }
                        .onChange(of: frame.minY) { newValue in
                            currentOffset = newValue
                        }
                }
            )
    }

    @ViewBuilder
    private var headerView: some View {
        if ticketDetailViewModel.isLoading {
            TicketHeaderSectionShimmer()
        } else {
            TicketHeaderSection(
                ticketDetailViewModel: ticketDetailViewModel,
                isExpanded: $isHeaderExpanded,
                ensureCloseTicketActionRestriction:
                    $ensureCloseTicketActionRestriction,
                onEdit: {
                    Task {
                        subjectText =
                            ticketDetailViewModel.ticketDetails?.title ?? ""
                        DispatchQueue.main.async {
                            if DeviceType.isPhone {
                                isShowEditSubjectIphone = true
                            } else {
                                isShowEditSubjectIpad = true
                            }
                        }
                    }
                },
                onDeleteDescription: {
                    showDeleteDescriptionPopup = true
                },
                selectedAttachment: $selectedAttachment,
                onAttachmentOptionTapped: {
                    isShowingAttachmentOptions = true
                },
                onAttachmentDelete: {
                    isShowingDeleteAttachmentPopup = true
                },
                canViewMyOrgTickets: canViewMyOrgTickets
            )

        }
    }

    private func handleReplyCompletion(_ shouldRefreshDetails: Bool) {
        messageTabToken = UUID()

        if shouldRefreshDetails {
            Task {
                await ticketDetailViewModel.loadTicketDetails(force: true)
            }
        }
    }

    @ViewBuilder
    private func actionButtons() -> some View {
        HStack(spacing: 12) {
            FilledButton.withIcon(
                title: ResourceManager.localized("replyText", comment: ""),
                icon: .replicate02,
                onClick: {
                    if DeviceType.isPhone {
                        NavigationHelper.push(
                            ReplyView(
                                ticketId: ticketDetailViewModel.ticketDetails?
                                    .ticketId ?? 0,
                                ticketTitle: ticketDetailViewModel
                                    .ticketDetails?.title ?? "",
                                statusId: ticketDetailViewModel.ticketDetails?
                                    .ticketStatusId ?? 0,
                                disableDismiss: $disableDismiss,
                                isInProgress: $isInProgress,
                                canCloseTicket: canCloseTicket,
                            ) { shouldRefreshDetails in
                                handleReplyCompletion(shouldRefreshDetails)
                                isInProgress = false
                            }
                            .environmentObject(ToastManager.shared)
                        )
                    } else {
                        isInProgress = false
                        showReplyPage = true
                    }
                },
                isEnabled: !ticketDetailViewModel.isLoading
                && ensureCloseTicketActionRestriction,
                        
                iconOnRight: false,
                isSmall: true,
                color: DeviceType.isTablet && Color.areEqualColors()
                    ? Color.appBarForegroundColor : nil
            )

            if DeviceConfig.isIPhone {
                Rectangle()
                    .fill(Color.borderSecondaryColor)
                    .frame(width: 1, height: 32)
            }

            if DeviceType.isPhone {
                OutlinedButton(
                    title: ResourceManager.localized(
                        "closeTicketText",
                        comment: ""
                    ),
                    onClick: {
                        showCloseTicketPopup = true
                    },
                    isEnabled: !ticketDetailViewModel.isLoading
                        && canCloseTicket,
                    isSmall: true
                )
            } else {
                OutlinedButton.themed(
                    title: ResourceManager.localized(
                        "closeTicketText",
                        comment: ""
                    ),
                    onClick: {
                        showCloseTicketPopup = true
                    },
                    isEnabled: !ticketDetailViewModel.isLoading
                        && canCloseTicket,
                    isSmall: true,
                    color: Color.areEqualColors()
                        ? Color.appBarForegroundColor : nil
                )
            }
        }
    }

    private var replyNotesFloatingButtons: some View {
        actionButtons()
            .padding(.all, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.borderSecondaryColor, lineWidth: 1)
            )
            .shadow(
                color: Color.textPrimary.opacity(0.03),
                radius: 8,
                x: 0,
                y: 8
            )
            .shadow(
                color: Color.textPrimary.opacity(0.08),
                radius: 24,
                x: 0,
                y: 20
            )
            .padding(.bottom, 45)
    }
}

struct TicketHeaderSection: View {
    @ObservedObject var ticketDetailViewModel: TicketDetailViewModel

    @State private var height: CGFloat = 0
    @Binding private var isExpanded: Bool
    @State private var originalHeight: CGFloat = 0
    @Binding var selectedAttachment: Attachment?
    @Binding private var ensureCloseTicketActionRestriction: Bool

    let onEditSubject: () -> Void
    let onDeleteDescription: () -> Void
    let onAttachmentOptionTapped: () -> Void
    let onAttachmentDelete: () -> Void
    var canViewMyOrgTickets: Bool = false

    @State private var showDateTooltip = false
    @Namespace private var tooltipNamespace

    init(
        ticketDetailViewModel: TicketDetailViewModel,
        isExpanded: Binding<Bool>,
        ensureCloseTicketActionRestriction: Binding<Bool>,
        onEdit: @escaping () -> Void,
        onDeleteDescription: @escaping () -> Void,
        selectedAttachment: Binding<Attachment?>,
        onAttachmentOptionTapped: @escaping () -> Void,
        onAttachmentDelete: @escaping () -> Void,
        canViewMyOrgTickets: Bool = false
    ) {
        self.ticketDetailViewModel = ticketDetailViewModel
        self._isExpanded = isExpanded
        self._ensureCloseTicketActionRestriction =
            ensureCloseTicketActionRestriction
        self.onEditSubject = onEdit
        self.onDeleteDescription = onDeleteDescription
        self.onAttachmentOptionTapped = onAttachmentOptionTapped
        self._selectedAttachment = selectedAttachment
        self.onAttachmentDelete = onAttachmentDelete
        self.canViewMyOrgTickets = canViewMyOrgTickets
    }

    private var isDescriptionDeleted: Bool {
        return ticketDetailViewModel.ticketDetails?.updateFlagId == 5
    }

    private var canEditTicketTitle: Bool {
        guard
            let requesterId = ticketDetailViewModel.ticketDetails?.requester
                .userId,
            let currentUserId = UserInfo.userId
        else {
            return false
        }

        return (requesterId == currentUserId && !GeneralSettings
            .restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal)
            || (!GeneralSettings.isMyOrganizationViewDisabledInCustomerPortal
                && canViewMyOrgTickets)
            && !GeneralSettings
                .restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal
                && ensureCloseTicketActionRestriction
    }

    private var canDeleteDescription: Bool {
        guard
            let updatedUserId = ticketDetailViewModel.ticketDetails?
                .updatedByUserId,
            let currentUserId = UserInfo.userId
        else {
            return false
        }
        return updatedUserId == currentUserId
            && !(!GeneralSettings.isMyOrganizationViewDisabledInCustomerPortal
                && canViewMyOrgTickets)
            && !GeneralSettings
                .restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal
            && ensureCloseTicketActionRestriction
    }

    private var createdOn: String {
        StringToDateTime.isLessThan24HoursAgo(
            timestamp: ticketDetailViewModel.ticketDetails?
                .createdOn ?? ""
        )
            ? StringToDateTime.getTimeAgo(
                timestamp: ticketDetailViewModel.ticketDetails?.createdOn ?? ""
            )
            : StringToDateTime.parseString(
                data: ticketDetailViewModel.ticketDetails?.createdOn ?? ""
            )
    }

    private var createdOnTextToShow: String {
        StringToDateTime.parseString(
            data: ticketDetailViewModel.ticketDetails?.createdOn ?? ""
        )
    }

    var body: some View {
        VStack {
            VStack(alignment: .leading, spacing: 12) {

                if DeviceConfig.isIPhone {
                    if ticketDetailViewModel.isUpdatingSubject {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 30)
                            .padding(.vertical, 4)
                            .shimmer()
                            .padding(.top, 4)
                    } else {
                        InlineEditableText(
                            text: ticketDetailViewModel.ticketDetails?.title
                                ?? "",
                            canEdit: canEditTicketTitle,
                            onEdit: {
                                onEditSubject()
                            }
                        )
                        .padding(.top, 4)
                    }
                }

                HStack(spacing: 8) {
                    HStack(spacing: 8) {
                        AppIcon(icon: .user, size: 16)
                            .padding(.vertical, 3)
                        Text(
                            ticketDetailViewModel.ticketDetails?.requester
                                .displayName ?? ""
                        )
                        .font(
                            FontFamily.customFont(
                                size: FontSize.small,
                                weight: .medium
                            )
                        )
                        .foregroundColor(.textSecondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    }
                    Circle()
                        .fill(Color.buttonSecondaryBorderColor)
                        .frame(width: 4, height: 4)
                    HStack(spacing: 8) {
                        AppIcon(icon: .clock, size: 16)
                            .padding(.vertical, 3)
                        Text(
                            createdOn
                        )
                        .font(
                            FontFamily.customFont(
                                size: FontSize.small,
                                weight: .medium
                            )
                        )
                        .foregroundColor(.textSecondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .onTapGesture {
                            withAnimation(nil) {
                                GlobalTooltipState.resetAll()
                                showDateTooltip.toggle()
                            }
                        }
                        .overlay(
                            Group {
                                if DeviceType.isTablet && showDateTooltip {
                                    CreatedOnTooltipView(
                                        createdOnTextToShow:
                                            createdOnTextToShow,
                                        isVisible: $showDateTooltip,
                                        isMessage: false
                                    )
                                }
                            }
                        )
                    }
                    Circle()
                        .fill(Color.buttonSecondaryBorderColor)
                        .frame(width: 4, height: 4)
                    Text(ticketDetailViewModel.ticketDetails?.status ?? "")
                        .font(
                            FontFamily.customFont(
                                size: FontSize.small,
                                weight: .semibold
                            )
                        )
                        .foregroundColor(.textSecondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }

                if DeviceConfig.isIPad {
                    if ticketDetailViewModel.isUpdatingSubject {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.25))
                            .frame(height: 30)
                            .padding(.vertical, 4)
                            .shimmer()
                    } else {
                        InlineEditableText(
                            text: ticketDetailViewModel.ticketDetails?.title
                                ?? "",
                            canEdit: canEditTicketTitle,
                            onEdit: {
                                onEditSubject()
                            }
                        )
                    }
                }

                AdaptiveDivider(isDashed: false)

                if let description = ticketDetailViewModel.ticketDetails?
                    .description,
                    !description.trimmingCharacters(in: .whitespacesAndNewlines)
                        .isEmpty
                {

                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(
                                ResourceManager.localized(
                                    "descriptionText",
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
                            .padding(.vertical, 4)
                            Spacer()

                            HStack(spacing: 16) {
                                if !isDescriptionDeleted && canDeleteDescription
                                {
                                    Button(action: {
                                        onDeleteDescription()
                                    }) {
                                        AppIcon(
                                            icon: .delete,
                                            color: .buttonSecondaryColor
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                if !isDescriptionDeleted {
                                    AppIcon(
                                        icon: !isExpanded ? .squarePlus : .minimize,
                                        color: .buttonSecondaryColor
                                    )
                                }
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if !isDescriptionDeleted {
                                withAnimation {
                                    isExpanded.toggle()
                                }
                            }
                        }

                        if isExpanded || (isDescriptionDeleted) {
                            HTMLView(
                                htmlContent: description,
                                contentHeight: Binding(
                                    get: { height },
                                    set: { newHeight in
                                        height = newHeight
                                        originalHeight = newHeight
                                    }
                                )
                            )
                            .frame(height: height)
                            .background(Color.clear)

                            VStack(spacing: 8) {
                                ForEach(
                                    ticketDetailViewModel.ticketDetails?
                                        .attachments ?? [],
                                    id: \.id
                                ) { attachment in
                                    HStack {
                                        AttachmentItemView(
                                            selectedAttachment:
                                                $selectedAttachment,
                                            attachment: attachment,
                                            canDelete: canDeleteDescription,
                                            dataToken: AppConstant.fileToken,
                                            onDelete: {
                                                onAttachmentDelete()
                                            },
                                            onMoreTapped: {
                                                onAttachmentOptionTapped()
                                            },
                                        )
                                        .frame(
                                            width: DeviceType.isPhone
                                                ? nil
                                                : UIScreen.main.bounds.width
                                                    * 0.5
                                        )
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .overlay(
                Group {
                    if DeviceType.isPhone && showDateTooltip {
                        CreatedOnTooltipView(
                            createdOnTextToShow: createdOnTextToShow,
                            isVisible: $showDateTooltip,
                            isMessage: false
                        )
                    }
                }
            )
            .onAppear {
                GlobalTooltipState.register($showDateTooltip)
            }
            .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
            .padding(.vertical, DeviceType.isPhone ? 8 : 12)
            .padding(.bottom, 12)
            .background(Color.backgroundPrimary)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.borderSecondaryColor),
                alignment: .bottom
            )
            .onTapGesture {
                withAnimation(nil) {
                    GlobalTooltipState.resetAll()
                }
            }
        }
    }
}

struct BottomBorderShape: Shape {
    var radius: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: 0, y: rect.maxY - radius))
        path.addArc(
            center: CGPoint(x: radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.maxX - radius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.maxX - radius, y: rect.maxY - radius),
            radius: radius,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )

        return path
    }
}

struct InlineEditableText: View {
    let text: String
    var canEdit: Bool = false
    var onEdit: (() -> Void)? = nil
    private let maxChars: Int = DeviceType.isPhone ? 150 : 250

    var body: some View {
        (Text(truncatedText)
            + (!canEdit
                ? Text("")
                : Text("  ")
                    + Text(AppIcons.edit.unicode).font(
                        .custom("fontello", size: 20)
                    )))
            .font(
                FontFamily.customFont(size: FontSize.xlarge, weight: .semibold)
            )
            .foregroundColor(.textPrimary)
            .truncationMode(.tail)
            .onTapGesture {
                if canEdit {
                    onEdit?()
                }
            }
    }

    private var truncatedText: String {
        if text.count > maxChars {
            let index = text.index(text.startIndex, offsetBy: maxChars)
            return String(text[..<index]) + "…"
        }
        return text
    }
}

//Tabview layout Helpers
enum TicketDetailTabs: Int, StickyTabItem {
    case messages
    case properties

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .messages:
            return ResourceManager.localized("messagesText", comment: "")
        case .properties:
            return ResourceManager.localized("propertiesText", comment: "")
        }
    }
}

struct TabContentView: View {
    let ticketId: Int
    @Binding var currentTab: TicketDetailTabs
    @Binding var messagesCount: Int
    @Binding private var ensureCloseTicketActionRestriction: Bool
    @State private var isExpanded: Bool = false
    @State private var proxy: ScrollViewProxy?
    @State private var isBounceEnabled: Bool = true
    @State private var propertiesTabToken: UUID = UUID()
    @State private var scrollViewRef: UIScrollView?

    @Binding var selectedAttachment: Attachment?
    let onAttachmentOptionTapped: () -> Void
    let onAttachmentDelete: () -> Void
    let onMessageDelete: (Message) -> Void
    var canViewMyOrgTickets: Bool = false

    @Binding var isLoading: Bool
    @Binding var messageTabToken: UUID

    let isShimmer: Bool

    private let pageWidth: CGFloat = UIScreen.main.bounds.width

    init(
        ticketId: Int,
        currentTab: Binding<TicketDetailTabs>,
        messagesCount: Binding<Int>,
        isLoading: Binding<Bool>,
        messageTabToken: Binding<UUID>,
        selectedAttachment: Binding<Attachment?>,
        ensureCloseTicketActionRestriction: Binding<Bool>,
        isShimmer: Bool = false,
        onAttachmentOptionTapped: @escaping () -> Void,
        onAttachmentDelete: @escaping () -> Void,
        onMessageDelete: @escaping (Message) -> Void,
        canViewMyOrgTickets: Bool = false
    ) {
        self.ticketId = ticketId
        self._currentTab = currentTab
        self._messagesCount = messagesCount
        self._isLoading = isLoading
        self._messageTabToken = messageTabToken
        self._selectedAttachment = selectedAttachment
        self._ensureCloseTicketActionRestriction =
            ensureCloseTicketActionRestriction
        self.isShimmer = isShimmer
        self.onAttachmentOptionTapped = onAttachmentOptionTapped
        self.onAttachmentDelete = onAttachmentDelete
        self.onMessageDelete = onMessageDelete
        self.canViewMyOrgTickets = canViewMyOrgTickets
    }

    var body: some View {
        Group {
            switch currentTab {
            case .messages:
                if isShimmer {
                    MessageListShimmerView()
                } else {
                    messagesTab
                }
            case .properties:
                propertiesTab
            }
        }
        .transition(.opacity.animation(.easeIn))
    }

    @State private var didPrint = false

    private var messagesTab: some View {
        MessageListView(
            ticketId: ticketId,
            messagesCount: $messagesCount,
            isLoading: $isLoading,
            selectedAttachment: $selectedAttachment,
            ensureCloseTicketActionRestriction:
                $ensureCloseTicketActionRestriction,
            onAttachmentOptionTapped: {
                onAttachmentOptionTapped()
            },
            onAttachmentDelete: {
                onAttachmentDelete()
            },
            onMessageDelete: onMessageDelete
        )
        .id(messageTabToken)
    }

    private var propertiesTab: some View {
        PropertiesCardScreen(
            ticketId: ticketId,
            ensureCloseTicketActionRestriction:
                $ensureCloseTicketActionRestriction,
            canEditDetails: canViewMyOrgTickets
        ).id(propertiesTabToken)
    }
}

protocol StickyTabItem: CaseIterable, Hashable {
    var title: String { get }
}

struct StickyTabs<Tab: StickyTabItem>: View {
    @Binding var currentTab: Tab
    @Binding var yOffset: CGFloat
    @Binding var messagesCount: Int

    var body: some View {
        tabBarButtons
            .offset(y: yOffset)
    }
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var namespace
    private let systemBackgroundColor = Color(UIColor.systemBackground)

    private var tabBarButtons: some View {

        HStack(spacing: 0) {
            ForEach(Array(Tab.allCases), id: \.self) { tab in
                let selected = currentTab == tab
                let isMessageTab =
                    tab.title
                    == ResourceManager.localized("messagesText", comment: "")
                let messageSuffix =
                    (isMessageTab && messagesCount > 0)
                    ? " (\(messagesCount))" : ""
                let title = tab.title + messageSuffix
                Text(title)
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(
                        selected ? .accentColor : .textSecondaryColor
                    )
                    .padding(.all, 12)
                    .padding(.horizontal, DeviceType.isPhone ? 0 : 8)
                    .onTapGesture {
                        currentTab = tab
                    }
                    .background(
                        ZStack(alignment: .bottom) {
                            if selected {
                                Color.accentColor
                                    .frame(height: 2)
                                    .padding(.top, 38)
                            } else {
                                Color.clear.frame(height: 2)
                            }
                        }
                    )
            }
            Spacer()
        }
        .background(Color.backgroundPrimary)
        .frame(height: 44, alignment: .bottom)
        .overlay(
            Rectangle()
                .frame(height: colorScheme == .dark ? 1 : 0)
                .foregroundColor(.borderSecondaryColor),
            alignment: .bottom
        )
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 2)
    }
}

struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

struct FrameReader: View {
    let coordinateSpace: CoordinateSpace
    let onChange: (_ frame: CGRect) -> Void

    init(
        coordinateSpace: CoordinateSpace,
        onChange: @escaping (_ frame: CGRect) -> Void
    ) {
        self.coordinateSpace = coordinateSpace
        self.onChange = onChange
    }

    var body: some View {
        GeometryReader { geo in
            Color.clear
                .preference(
                    key: FramePreferenceKey.self,
                    value: geo.frame(in: coordinateSpace)
                )
        }
        .onPreferenceChange(FramePreferenceKey.self, perform: onChange)
    }
}

extension View {
    func readingFrame(
        coordinateSpace: CoordinateSpace = .global,
        onChange: @escaping (_ frame: CGRect) -> Void
    ) -> some View {
        background(
            FrameReader(coordinateSpace: coordinateSpace, onChange: onChange)
        )
    }
}
