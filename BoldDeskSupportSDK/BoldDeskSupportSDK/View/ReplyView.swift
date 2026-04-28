import SwiftUI

struct ReplyView: View {
    @StateObject private var replyViewModel: ReplyViewModel
    @State private var replyText: String = ""
    @State private var keyboardHeight: CGFloat = 0
    @Environment(\.presentationMode) private var presentationMode
    @State private var isFocused: Bool = false
    @StateObject private var uploadManager = UploadManager()
    @State private var attachmentCount: Int = 0
    @EnvironmentObject var toastManager: ToastManager
    @State private var isKeyboardVisible: Bool = false
    
    @StateObject private var keyboardObserver = KeyboardObserver()

    let ticketId: Int
    let ticketTitle: String
    let statusId: Int
    let canCloseTicket: Bool
    
    let onDismiss: ((Bool) -> Void)?
    
    // Bottom sheet / Popover parameters
    @State private var showAttachments: Bool = false
    @State private var showFilePicker: Bool = false
    @State private var showUpdateSlider: Bool = false
    
    @State private var showDiscardAlert: Bool = false
    
    @Binding var disableDismiss: Bool
    @Binding var isInProgress: Bool
    
    @State private var tabWidth: CGFloat = 0
    
    // Initializer
    init(
        ticketId: Int,
        ticketTitle: String,
        statusId: Int,
        disableDismiss: Binding<Bool>,
        isInProgress: Binding<Bool>,
        canCloseTicket: Bool,
        onDismiss: ((Bool) -> Void)? = nil,
    ) {
        self.ticketId = ticketId
        self.ticketTitle = ticketTitle
        self.statusId = statusId
        self.onDismiss = onDismiss
        self.canCloseTicket = canCloseTicket
        self._disableDismiss = disableDismiss
        self._isInProgress = isInProgress
        self._uploadManager = StateObject(wrappedValue: UploadManager())
        self._replyViewModel = StateObject(wrappedValue: ReplyViewModel(ticketId: ticketId, statusId: statusId))
    }
    
    var body: some View {
        if DeviceType.isPhone {
            ZStack {
                AppPage {
                    GeometryReader { geometry in
                        contentLayout(geometry: geometry, isKeyboardVisible: $isKeyboardVisible)
                    }
                    .navigationBarHidden(true)
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { notification in
                        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
                            let keyboardRectangle = keyboardFrame.cgRectValue
                            withAnimation(.easeInOut(duration: 0.3)) {
                                keyboardHeight = keyboardRectangle.height
                            }
                        }
                    }
                    .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                        withAnimation(.easeInOut(duration: 0.3)) {
                            keyboardHeight = 0
                        }
                    }
                }
                .overlay(ToastStackView())
                .onChange(of: uploadManager.pickedItems) { newItems in
                    attachmentCount = newItems.count
                }
                .bottomSheet(isPresented: $showFilePicker) { dismiss in
                    filePickerBottomSheetContent(dismiss: dismiss)
                }
                .bottomSheet(isPresented: $showAttachments) { dismiss in
                    attachmentsList(dismiss: dismiss)
                }
                .bottomSheet(isPresented: $showUpdateSlider) { dismiss in
                    updateSlider(dismiss: dismiss)
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .overlay(
                    Group {
                        if replyViewModel.isInProgress {
                            LoadingOverlay()
                                .zIndex(2)
                        }
                    }
                )
                .onReceive(replyViewModel.dismissPublisher) { shouldCloseTicket in
                    onDismiss?(shouldCloseTicket)
                    presentationMode.wrappedValue.dismiss()
                }
                .alert(isPresented: $showDiscardAlert) {
                    discardAlert()
                }
                .onChange(of: uploadManager.pickedItems) { items in
                    replyViewModel.pickedAttachments = items
                    if items.isEmpty {
                        showAttachments = false
                    }
                }
            }
        } else {
            ZStack {
                AppPage {
                    contentLayout(geometry: nil, isKeyboardVisible: $isKeyboardVisible)
                }
                .onChange(of: replyViewModel.replyText) { newText in
                    disableDismiss = replyViewModel.validateReplyText(showToast: false)
                }
                .onChange(of: uploadManager.pickedItems) { newItems in
                    attachmentCount = newItems.count
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                    isKeyboardVisible = true
                }
                .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                    isKeyboardVisible = false
                }
                .onReceive(replyViewModel.dismissPublisher) { shouldCloseTicket in
                    onDismiss?(shouldCloseTicket)
                    presentationMode.wrappedValue.dismiss()
                }
                .navigationViewStyle(StackNavigationViewStyle())
                .overlay(
                    Group {
                        if replyViewModel.isInProgress {
                            LoadingOverlay()
                                .zIndex(2)
                        }
                    }
                )
                .alert(isPresented: $showDiscardAlert) {
                    discardAlert()
                }
            }
            .onChange(of: replyViewModel.isInProgress) { newValue in
                isInProgress = newValue
            }
            .onChange(of: uploadManager.pickedItems) { items in
                replyViewModel.pickedAttachments = items
                if items.isEmpty {
                    showAttachments = false
                }
            }
            .overlay(ToastStackView())
            .applyInteractiveDismiss(disableDismiss)
        }
    }
    
    private func discardAlert() -> Alert {
        Alert(
            title: Text(ResourceManager.localized("discardReplyTitle", comment: "Discard reply?")),
            message: Text(ResourceManager.localized("discardReplyMessage", comment: "Your reply will be lost.")),
            primaryButton: .destructive(
                Text(ResourceManager.localized("discardText", comment: "Discard"))
            ) {
                presentationMode.wrappedValue.dismiss()
            },
            secondaryButton: .cancel()
        )
    }

}

// MARK: - Common Layout
private extension ReplyView {
    func contentLayout(geometry: GeometryProxy? = nil, isKeyboardVisible: Binding<Bool>) -> some View {
        VStack(spacing: 0) {
            // App Bar
            if DeviceConfig.isIPhone {
                CommonAppBar(
                    title: ResourceManager.localized("replyText", comment: ""),
                    subtitle: "#\(ticketId) - \(ticketTitle)",
                    showBackButton: true,
                    onBack: {
                        if replyViewModel.validateReplyText(showToast: false) {
                            showDiscardAlert = true
                        } else {
                            presentationMode.wrappedValue.dismiss()
                        }
                    }
                ) {
                    Button(action: {
                        isFocused = false
                        if uploadManager.pickedItems.isEmpty {
                            showFilePicker = true
                        } else {
                            showAttachments = true
                        }
                    }) {
                        ZStack(alignment: .topTrailing) {
                            AppIcon(icon: .file, color: .appBarForegroundColor)
                                .padding(10)
                            
                            if attachmentCount > 0 {
                                Text("\(attachmentCount)")
                                    .font(FontFamily.customFont(size: FontSize.xxxsmall, weight: .medium))
                                    .foregroundColor(.filledButtonForegroundColor)
                                    .padding(5)
                                    .background(Color.accentColor)
                                    .clipShape(Circle())
                                    .offset(x: -5, y: 2)
                            }
                        }
                    }
                }
            } else {
                CommonAppBarCustom {
                    HStack(spacing: 0) {
                        CircleAvatar(initials: "SA", backgroundColor: .green)
                        Spacer().frame(width: 16)
                        ZStack (alignment: .bottom) {
                            VStack {
                                Spacer()
                                Text(ResourceManager.localized("replyText", comment: ""))
                                    .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                                    .foregroundColor(Color.areEqualColors() ? .appBarForegroundColor : Color.accentColor)
                                    .padding(.horizontal, 4)
                                    .background(
                                        GeometryReader { geo in
                                            Color.clear
                                                .onAppear {
                                                    tabWidth = geo.size.width
                                                }
                                                .onChange(of: geo.size.width) { newWidth in
                                                    tabWidth = newWidth
                                                }
                                        }
                                    )
                                    .frame(height: 20)
                                Spacer()
                            }
                            Rectangle()
                                .fill(Color.accentColor)
                                .frame(width: tabWidth, height: 3)
                        }
                        Spacer()
                        Button(action: {
                            isFocused = false
                            if replyViewModel.validateReplyText(showToast: false) {
                                showDiscardAlert = true
                            } else {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            AppIcon.appbar(.close)
                        }
                        .frame(width: 28, height: 28)
                    }
                    .frame(height: 56)
                }
            }
            VStack(spacing: 0) {
                
                AdaptiveDivider(isDashed: false)
                
                VStack(alignment: .leading, spacing: 16) {
                    MultilineTextEditor(
                        text: $replyViewModel.replyText,
                        isFocused: $isFocused,
                        font: FontFamily.customUIFont(size: FontSize.medium, weight: .regular),
                        lineHeight: 20,
                        isEditable: true,
                        onChange: { newText in

                        },
                        onFocusIn: {
                            
                        },
                        onFocusOut: {
                           
                        }
                    )
                    .disabled(false)
                    .overlay(
                        VStack {
                            HStack {
                                if replyViewModel.replyText.isEmpty {
                                    Text(ResourceManager.localized("addMessageText", comment: ""))
                                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                                        .foregroundColor(Color.textPlaceHolderColor)
                                        .allowsHitTesting(false)
                                }
                                Spacer()
                            }
                            Spacer()
                        }
                    )
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                if DeviceType.isTablet {
                    if uploadManager.pickedItems.count > 0 {
                        AdaptiveDivider(isDashed: false)
                        attachmentsList()
                    }
                    AdaptiveDivider(isDashed: false)
                    Button(action: {
                        isFocused = false
                        showFilePicker.toggle()
                    }) {
                        HStack(spacing: 0) {
                            AppIcon(icon: .attachment, size: 24)
                                .padding(.trailing, 12)
                            Text("Attach file")
                                .foregroundColor(Color.accentColor)
                                .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                            Text(" (up to 20MB)")
                                .foregroundColor(Color.textSecondaryColor)
                                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        }
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundColor(Color.buttonSecondaryBorderColor)
                        )
                        .padding(.horizontal, 12)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .popover(isPresented: $showFilePicker, attachmentAnchor: .rect(.bounds), arrowEdge: .bottom) {
                        AttachmentBodyContent(
                            manager: uploadManager,
                            onTap: {
                                showFilePicker = false
                            }
                        )
                        .frame(width: min(280, UIScreen.main.bounds.width / 4))
                        .padding(.vertical, 12)
                        .padding(.horizontal, 8)
                        .background(Color.popoverBackground)
                    }
                }
                HStack(spacing: 12) {
                    Group {
                        if DeviceType.isPhone {
                            if statusId != 5 && canCloseTicket {
                                SegmentedButton(
                                    title: ResourceManager.localized("updateText", comment: ""),
                                    primaryButtonCallBack: {
                                        isFocused = false
                                        Task {
                                            await replyViewModel.validateAndUpdateReply(shouldCloseTicket: false)
                                        }
                                    },
                                    secondaryButtonCallBack: {
                                        isFocused = false
                                        if replyViewModel.validateReplyText() {
                                            showUpdateSlider = true
                                        }
                                    },
                                    isSmall: true
                                )
                            } else {
                                FilledButton(
                                    title: ResourceManager.localized("updateText", comment: ""),
                                    onClick: {
                                        isFocused = false
                                        Task {
                                            await replyViewModel.validateAndUpdateReply(shouldCloseTicket: false, shouldRefreshDetails: GeneralSettings.closedTicketStatusConfig?.fallbackStatusId == 2)
                                        }
                                    },
                                    isSmall: true
                                )
                            }
                            OutlinedButton(
                                title: ResourceManager.localized("discardText", comment: ""),
                                onClick: {
                                    isFocused = false
                                    if replyViewModel.validateReplyText(showToast: false) {
                                        showDiscardAlert = true
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                },
                                isSmall: true
                            )
                            Spacer()
                        } else {
                            Spacer()
                            OutlinedButton(
                                title: ResourceManager.localized("discardText", comment: ""),
                                onClick: {
                                    isFocused = false
                                    if replyViewModel.validateReplyText(showToast: false) {
                                        showDiscardAlert = true
                                    } else {
                                        presentationMode.wrappedValue.dismiss()
                                    }
                                },
                                isSmall: true
                            )
                            if statusId != 5 && canCloseTicket {
                                OutlinedButton.themed(
                                    title: ResourceManager.localized("updateAndCloseTicketText", comment: ""),
                                    onClick: {
                                        isFocused = false
                                        Task {
                                            await replyViewModel.validateAndUpdateReply(shouldCloseTicket: true)
                                        }
                                    },
                                    isSmall: true
                                )
                            }
                            FilledButton(
                                title: ResourceManager.localized("updateText", comment: ""),
                                onClick: {
                                    isFocused = false
                                    let shouldRefresh = (statusId == 5) &&
                                        (GeneralSettings.closedTicketStatusConfig?.fallbackStatusId == 2)
                                    
                                    Task {
                                        await replyViewModel.validateAndUpdateReply(
                                            shouldCloseTicket: false,
                                            shouldRefreshDetails: shouldRefresh
                                        )
                                    }
                                },
                                isSmall: true
                            )
                            
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 16)
                .padding(.top, 12)
                .background(Color.clear)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color.borderSecondaryColor),
                    alignment: .top
                )
                .padding(
                    .bottom,
                    (isKeyboardVisible.wrappedValue && geometry != nil)
                    ? (keyboardHeight - (geometry?.safeAreaInsets.bottom ?? 0))
                    : 0
                )
            }
            .background(Color.backgroundPrimary)
            
            if !(keyboardObserver.isKeyboardVisible) && !DeviceType.isTablet {
                PoweredByFooterView()
            }
                
        }
    }
    
    private func filePickerBottomSheetContent(dismiss: (() -> Void)? = nil) -> some View {
        AttachmentBodyContent(manager: uploadManager, onTap: {
            dismiss?()
            if !uploadManager.pickedItems.isEmpty {
                showAttachments = true
            }
        })
    }
    
    private func updateSlider(dismiss: (() -> Void)? = nil) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            updateButton(
                title: ResourceManager.localized("updateText", comment: ""),
                dismiss: {
                    dismiss?()
                    Task {
                        await replyViewModel.validateAndUpdateReply(shouldCloseTicket: false)
                    }
                }
            )
            updateButton(
                title: ResourceManager.localized("updateAndCloseTicketText", comment: ""),
                dismiss: {
                    dismiss?()
                    Task {
                        await replyViewModel.validateAndUpdateReply(shouldCloseTicket: true)
                    }
                }
            )
        }
    }
    
    @ViewBuilder
    private func updateButton(title: String, dismiss: (() -> Void)?) -> some View {
        Button(action: { dismiss?() }) {
            HStack {
                Text(title)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                    .foregroundColor(.textSecondaryColor)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 16)
                Spacer()
            }
        }
    }
    
    private func attachmentsList(dismiss: (() -> Void)? = nil) -> some View {
        Group {
            if DeviceType.isPhone {
                VStack(alignment: .leading) {
                    Text(ResourceManager.localized("attachmentsText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
                        .foregroundColor(Color.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)

                    Group {
                        if uploadManager.pickedItems.count >= 5 {
                            ScrollView {
                                attachmentRows
                                    .padding(.horizontal, 16)
                            }
                            .padding(.vertical, 10)
                            .frame(maxHeight: UIScreen.main.bounds.height / 2)
                        } else {
                            attachmentRows
                                .padding(.vertical, 10)
                                .padding(.horizontal, 16)
                        }
                    }

                    AdaptiveDivider(isDashed: false)

                    HStack {
                        FilledButton(
                            title: ResourceManager.localized("addAttachmentText", comment: ""),
                            onClick: {
                                dismiss?()
                                showFilePicker = true
                            },
                            isSmall: true
                        )
                        OutlinedButton(
                            title: ResourceManager.localized("discardText", comment: ""),
                            onClick: { dismiss?() },
                            isSmall: true
                        )
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 16)
                }
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(Array(uploadManager.pickedItems.enumerated()), id: \.element.id) { index, pickedItem in
                            UploadingRow(
                                pickedItem: pickedItem,
                                isLast: false,
                                isProgressShow: false,
                                onDelete: {
                                    onDelete(index: index)
                                }
                            )
                        }
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 12)
                }
            }
        }
    }
    
    private var attachmentRows: some View {
        VStack(spacing: 12) {
            ForEach(Array(uploadManager.pickedItems.enumerated()), id: \.element.id) { index, pickedItem in
                UploadingRow(
                    pickedItem: pickedItem,
                    isLast: index == uploadManager.pickedItems.count - 1,
                    isProgressShow: false,
                    onDelete: {
                        onDelete(index: index)
                    }
                )
            }
        }
    }
    
    func onDelete(index: Int) {
        uploadManager.totalFileSizeInBytes -=
            uploadManager.pickedItems[index].fileSizeInBytes
        uploadManager.pickedItems.remove(at: index)
    }
    
}

