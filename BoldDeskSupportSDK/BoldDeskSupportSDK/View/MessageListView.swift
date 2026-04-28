import SwiftUI

struct MessageListView: View {
    @StateObject private var viewModel: MessageListViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.presentationMode) var presentationMode
    @Binding var messagesCount: Int
    @Binding var isLoading: Bool
    @Binding private var ensureCloseTicketActionRestriction : Bool
    
    @Binding var selectedAttachment: Attachment?
    let onAttachmentOptionTapped: () -> Void
    let onAttachmentDelete: () -> Void
    let onMessageDelete: (Message) -> Void
    
    private let ticketId: Int
    
    
    init(
        ticketId: Int,
        messagesCount: Binding<Int>,
        isLoading: Binding<Bool>,
        selectedAttachment: Binding<Attachment?>,
        ensureCloseTicketActionRestriction: Binding<Bool>,
        onAttachmentOptionTapped: @escaping () -> Void,
        onAttachmentDelete: @escaping () -> Void,
        onMessageDelete: @escaping (Message) -> Void
    ) {
        self.ticketId = ticketId
        self._messagesCount = messagesCount
        self._isLoading = isLoading
        self._selectedAttachment = selectedAttachment
        self._ensureCloseTicketActionRestriction = ensureCloseTicketActionRestriction
        self.onAttachmentOptionTapped = onAttachmentOptionTapped
        self.onAttachmentDelete = onAttachmentDelete
        self.onMessageDelete = onMessageDelete
        _viewModel = StateObject(wrappedValue: MessageListViewModel(ticketId: ticketId))
    }
    
    var body: some View {
        ZStack {
            if viewModel.isLoading {
                MessageListShimmerView()
            } else if viewModel.messages.isEmpty {
                NoMessagesFoundBox()
                    .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
                    .padding(.vertical, 24)
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.messages) { message in
                        VStack{
                            MessageItemView(
                                ticketId: ticketId,
                                message: message,
                                selectedAttachment: $selectedAttachment,
                                ensureCloseTicketActionRestriction: $ensureCloseTicketActionRestriction,
                                onAttachmentOptionTapped: {
                                    onAttachmentOptionTapped()
                                },
                                onAttachmentDelete: {
                                    onAttachmentDelete()
                                },
                                onMessageDelete: onMessageDelete
                            )
                            Spacer()
                                .frame(height: 1)
                                .onVisible {
                                    loadMoreIfNeeded(isLast: message.isLastMessage)
                                }
                        }
                        
                    }
                    
                    if viewModel.isLoadingMore && !viewModel.isLoading {
                        LoadingMoreIndicatorView(
                            message: ResourceManager.localized("loadingMoreMessagesText", comment: "")
                        )
                        .padding(.bottom, DeviceConfig.isIPhone ? 28 : 34)
                    }
                    
                    if viewModel.shouldShowNoMoreItems {
                        NoMoreDataView(
                            message: ResourceManager.localized("noMoreDataText", comment: "No more items to load")
                        )
                        .padding(.bottom, DeviceConfig.isIPhone ? 28 : 34)
                    }
                }
                .padding(.vertical, DeviceType.isPhone ? 16 : 20)
            }
        }
        .background(Color.tabBarViewBackgroundTeritiaryColor)
        .onAppear(perform: handleOnAppear)
        .onChange(of: viewModel.hasError, perform: handleErrorChange)
        .onChange(of: viewModel.isLoading) { isLoading = $0 }
        .onChange(of: viewModel.totalMessagesCount) { messagesCount = $0 }
    }
}

extension View {
    func onVisible(_ action: @escaping () -> Void) -> some View {
        self.background(
            GeometryReader { geo in
                Color.clear
                    .onChange(of: geo.frame(in: .global).minY) { _ in
                        let screenHeight = UIScreen.main.bounds.height
                        let frame = geo.frame(in: .global)
                        
                        if frame.minY < screenHeight && frame.maxY > 0 {
                            action()
                        }
                    }
            }
        )
    }
}


struct MessageItemView: View {
    private let ticketId: Int
    let message: Message
    @State private var height: CGFloat = 0
    @Binding private var ensureCloseTicketActionRestriction : Bool
    @State private var showDateTooltip = false
    
    @Binding var selectedAttachment: Attachment?
    let onAttachmentOptionTapped: () -> Void
    let onAttachmentDelete: () -> Void
    let onMessageDelete: (Message) -> Void
    @Environment(\.colorScheme) var colorScheme

    
    init(
        ticketId: Int,
        message: Message,
        selectedAttachment: Binding<Attachment?>,
        ensureCloseTicketActionRestriction: Binding<Bool>,
        onAttachmentOptionTapped: @escaping () -> Void,
        onAttachmentDelete: @escaping () -> Void,
        onMessageDelete: @escaping (Message) -> Void
    ) {
        self.ticketId = ticketId
        self.message = message
        self._selectedAttachment = selectedAttachment
        self._ensureCloseTicketActionRestriction = ensureCloseTicketActionRestriction
        self.onAttachmentOptionTapped = onAttachmentOptionTapped
        self.onAttachmentDelete = onAttachmentDelete
        self.onMessageDelete = onMessageDelete
    }
    
    private var messageLink : String {
        "\(AppConstant.currentDomain)/tickets/\(ticketId)#update-\(message.id)"
    }
    
    private var canDeleteMessage: Bool {
        guard
            let currentUserId = UserInfo.userId
        else {
            return false
        }
        
        return message.updatedBy.userId == currentUserId &&
        !GeneralSettings.restrictUpdatingTicketTitleAndDeletingMessagesOrFilesInCustomerPortal
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                CircleAvatar(initials: message.updatedBy.shortCode, backgroundColor: .accentColor)
                VStack(alignment: .leading, spacing: 0) {
                    Text(message.updatedBy.displayName)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                        .foregroundColor(Color.textSecondaryColor)
                    Text(StringToDateTime.isLessThan24HoursAgo(timestamp: message.updatedOn) ? StringToDateTime.getTimeAgo(timestamp: message.updatedOn) : StringToDateTime.parseString(data: message.updatedOn))
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        .foregroundColor(Color.textTeritiaryColor)
                        .onTapGesture {
                            withAnimation(nil) {
                                GlobalTooltipState.resetAll()
                                showDateTooltip.toggle()
                            }
                        }
                }
                Spacer()
                
                HStack (spacing: 8) {
                    CopyButton(
                        textToCopy: messageLink,
                        tooltipText: "Copy ticket link"
                    )
                    
                    if ensureCloseTicketActionRestriction && message.updateFlagId != 5 && canDeleteMessage {
                        Button(action: {
                            onMessageDelete(message)
                        }) {
                            AppIcon(icon: .delete)
                                .frame(width: 28, height: 28)
                        }
                    }
                }
                
            }
            .padding(.top, 12)
            .padding(.horizontal, 12)
            .overlay(
                Group {
                    if showDateTooltip {
                        CreatedOnTooltipView(createdOnTextToShow: StringToDateTime.parseString(data: message.updatedOn), isVisible: $showDateTooltip, isMessage: true)
                    }
                }
            )
            .onAppear {
                GlobalTooltipState.register($showDateTooltip)
            }
            VStack (spacing: 0) {
                HTMLView(
                    htmlContent: message.message,
                    contentHeight: $height,
                    token: AppConstant.fileToken
                )
                .onTapGesture {
                    withAnimation(nil) {
                        GlobalTooltipState.resetAll()
                    }
                }
                .frame(height: height)
                
                VStack (spacing: 8) {
                    ForEach(message.attachments, id: \.id) { attachment in
                        HStack{
                            AttachmentItemView(
                                selectedAttachment: $selectedAttachment,
                                attachment: attachment,
                                canDelete: ensureCloseTicketActionRestriction && canDeleteMessage,
                                dataToken: AppConstant.fileToken,
                                onDelete: {
                                    onAttachmentDelete()
                                },
                                onMoreTapped: {
                                    onAttachmentOptionTapped()
                                },
                            )
                            .frame(width: DeviceType.isPhone
                                   ? nil
                                   : UIScreen.main.bounds.width * 0.5)
                            Spacer()
                        }
                        
                    }
                }
                .padding(.vertical, 8)
            }
            .padding(.leading, 56)
            .padding(.trailing, 12)
            .padding(.vertical, 12)
            
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.borderSecondaryColor, lineWidth: colorScheme == .dark ? 1 : 0)
                .background(Color.cardBackgroundPrimary.cornerRadius(12))
        )
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        .padding(.horizontal, DeviceType.isPhone ? 12 : 16)
        .onTapGesture {
            withAnimation(nil) {
                GlobalTooltipState.resetAll()
            }
        }
    }
}

// MARK: - Helpers
private extension MessageListView {
    func handleOnAppear() {
        if viewModel.messages.isEmpty && !viewModel.isLoading {
            Task { await viewModel.loadMessages() }
        }
    }
    
    func handleErrorChange(_ hasError: Bool) {
        if hasError {
            ToastManager.shared.show(viewModel.errorMessage ?? "An unknown error occurred", type: .error)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                viewModel.hasError = false
            }
        }
    }
    
    func loadMoreIfNeeded(isLast: Bool) {
        if isLast &&
            !viewModel.isLoadingMore &&
            !viewModel.isLoading &&
            viewModel.canLoadMore {
            Task {
                await viewModel.loadMoreMessages()
            }
        }
    }
}

struct MessageListShimmerView: View {
    var body: some View {
        VStack(spacing: 12) {
            ForEach(0..<(DeviceConfig.isIPhone ? 10 : 20), id: \.self) { _ in
                MessageCardShimmer()
            }
            
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .background(Color.tabBarViewBackgroundTeritiaryColor)
        .ignoresSafeArea(.all, edges: .bottom)
    }
}

struct MessageCardShimmer: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Circle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 40)
                    .shimmer()
                
                VStack(alignment: .leading, spacing: 4) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 120, height: 16)
                        .cornerRadius(4)
                        .shimmer()
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 200, height: 14)
                        .cornerRadius(4)
                        .shimmer()
                }
                
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(height: 60)
                    .cornerRadius(4)
                    .shimmer()
            }
        }
        .padding(16)
        .background(Color.backgroundPrimary)
        .cornerRadius(12)
    }
}

struct NoMessagesFoundBox: View {
    var body: some View {
        Text(ResourceManager.localized("noMessagesFoundText", comment: ""))
            .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
            .foregroundColor(Color.textPlaceHolderColor)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.backgroundPrimary)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.buttonSecondaryBorderColor, lineWidth: 1)
            )
    }
}
