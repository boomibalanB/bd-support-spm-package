import SwiftUI

struct CreateTicket: View {
    @State private var cardShow = false
    @StateObject private var uploadManager = UploadManager()
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var createTicketViewModel: CreateTicketViewModel
    @EnvironmentObject var toastManager: ToastManager
    @StateObject private var keyboardObserver = KeyboardObserver()
    @State private var showFilePicker: Bool = false
    @State private var showFilePopover: Bool = false
    @State private var formDisabled: Bool = false

    private let isForShimmer: Bool
    
    init(isForShimmer: Bool = false) {
        self.isForShimmer = isForShimmer
        _createTicketViewModel = StateObject(wrappedValue: CreateTicketViewModel(isDisabled: isForShimmer))
    }
    
    static func shimmerPage() -> CreateTicket {
        CreateTicket(isForShimmer: true)
    }

    var body: some View {

        AppPage {
            ZStack {
                VStack(alignment: .leading, spacing: 0) {
                    if DeviceConfig.isIPhone {
                        CommonAppBar(
                            title: ResourceManager.localized(
                                "createTicket",
                                comment: ""
                            ),
                            showBackButton: true,
                            onBack: {
                                presentationMode.wrappedValue.dismiss()
                            },
                            actionButtons: {
                                TextButton(
                                    title: ResourceManager.localized(
                                        "resetText",
                                        comment: ""
                                    ),
                                    onClick: {
                                        Task {
                                            await createTicketViewModel
                                                .resetForm()
                                        }
                                    },
                                    textColor: .accentColor
                                )
                            }
                        )
                    } else {
                        DialogAppBar(
                            title: ResourceManager.localized(
                                "createTicket",
                                comment: ""
                            ),
                            actionButtons: buildActionButtons(),
                            onBack: {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
                    NetworkWrapper {
                        VStack {
                            ZStack {
                                if createTicketViewModel.isLoading {
                                    CreateTicketShimmer()
                                } else {
                                    ScrollViewReader { proxy in
                                        VStack(spacing: 0) {
                                            if AppConstant.authToken.isEmpty {
                                                HStack(alignment: .center, spacing: 8) {
                                                    AppIcon(icon: .info,
                                                            size: 16, color: .infoBannerIconColor)
                                                    Text(ResourceManager.localized("pleaseProvideEmailOrPhone", comment: ""))
                                                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                                                        .foregroundColor(.textSecondaryColor)
                                                        .multilineTextAlignment(.leading)
                                                }
                                                .padding(.vertical, 10)
                                                .padding(.horizontal, DeviceType.isPhone ? 16 : 20)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .background(Color.infoBannerBackgroundColor)
                                            }
                                            ScrollView {
                                                ForEach(
                                                    Array(
                                                        createTicketViewModel
                                                            .formFieldModel
                                                            .enumerated()
                                                    ),
                                                    id: \.offset
                                                ) { index, field in
                                                    renderFieldView(
                                                        for: field,
                                                        index: index,
                                                        proxy: proxy
                                                    )
                                                    .padding(
                                                        .top,
                                                        index == 0
                                                            ? DeviceType.isPhone
                                                                ? 16 : 16 : 0
                                                    )
                                                    .padding(.horizontal, 6)
                                                    .disabled(formDisabled)
                                                }
                                            }
                                            .applyKeyboardToolbar()
                                        }
                                    }
                                }
                            }.frame(maxHeight: .infinity)
                            if !keyboardObserver.isKeyboardVisible {
                                VStack(alignment: .leading) {
                                    Divider()
                                    if createTicketViewModel.isShowTicketLink {
                                        SingleLineTextAndLink(
                                            text: BDSupportSDK.chatData?.offlineSettings?.confirmationMessage ?? "",
                                            ticketId: createTicketViewModel.ticketId,
                                            link: "\(AppConstant.currentDomain)/tickets/\(createTicketViewModel.ticketId)"
                                        )
                                        .padding(.top, 12)
                                        .padding(.bottom, 12)
                                        .padding(.horizontal)
                                    } else if DeviceType.isPhone {
                                        HStack(spacing: 12) {
                                            FilledButton(
                                                title: ResourceManager.localized(
                                                    "createText",
                                                    comment: ""
                                                ),
                                                onClick: {
                                                    Task {
                                                        await createTicketViewModel
                                                            .submiTicket()
                                                    }
                                                }
                                            )

                                            OutlinedButton(
                                                title: ResourceManager.localized(
                                                    "cancelText",
                                                    comment: ""
                                                ),
                                                onClick: {
                                                    presentationMode.wrappedValue
                                                        .dismiss()
                                                }
                                            )
                                        }
                                        .padding(.top, 12)
                                        .padding(.bottom, 12)
                                        .padding(.leading)
                                    }
                                }
                                .background(Color.backgroundPrimary)
                            }
                        }
                    }
                    if !(keyboardObserver.isKeyboardVisible)
                        && !DeviceType.isTablet
                    {
                        PoweredByFooterView()
                    }
                }
                if createTicketViewModel.isShowProgress {
                    Color.black.opacity(0.3)  // dim background
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: .white)
                        )
                        .scaleEffect(1.5)
                }
            }
            .background(DeviceConfig.isIPhone ? Color.cardBackgroundPrimary : Color.backgroundPrimary)
            .onTapGesture {
                UIApplication.shared.endEditing()
            }
        }
        .bottomSheet(isPresented: $showFilePicker) { dismiss in
            filePickerBottomSheetContent(dismiss: dismiss)
        }
        .background(Color.backgroundPrimary)
        .onChange(of: createTicketViewModel.shouldDismiss) { newValue in
            if !BDSupportSDK.isFromChatSDK {
                ToastManager.shared.show(
                    "Ticket Created successfully",
                    type: .success
                )
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    presentationMode.wrappedValue.dismiss()
                }
            }
        }
        .onChange(of: createTicketViewModel.isShowTicketLink) { newValue in
            if newValue{
                formDisabled = true
            }
        }
        .overlay(ToastStackView())
        .navigationBarHidden(true)
        .onChange(of: uploadManager.pickedItems) { items in
            createTicketViewModel.pickedItem = items
        }
    }
    private func filePickerBottomSheetContent(dismiss: (() -> Void)? = nil)
        -> some View
    {
        AttachmentBodyContent(
            manager: uploadManager,
            onTap: {
                dismiss?()
            }
        )
    }
    private var attachmentRows: some View {
        VStack(alignment: .leading) {
            ForEach(
                Array(uploadManager.pickedItems.enumerated()),
                id: \.element.id
            ) { index, pickedItem in
                UploadingRow(
                    pickedItem: pickedItem,
                    isLast: index == uploadManager.pickedItems.count - 1,
                    isProgressShow: false,
                    onDelete: {
                        onDelete(index: index)
                    }
                )
                .padding(.horizontal, 12)
                .padding(
                    .bottom,
                    index == uploadManager.pickedItems.count - 1 ? 16 : 12
                )
            }
        }
    }

    func onDelete(index: Int) {
        uploadManager.totalFileSizeInBytes -=
            uploadManager.pickedItems[index].fileSizeInBytes
        uploadManager.pickedItems.remove(at: index)
    }

    func buildActionButtons() -> [CustomAppBarAction] {
        var buttons: [CustomAppBarAction] = []

        if !createTicketViewModel.isLoading
            && !createTicketViewModel.isShowProgress
        {
            buttons.append(
                .iconButton(
                    appIcon: AppIcons.reset,
                    action: {
                        Task {
                            await createTicketViewModel.resetForm()
                        }
                    },
                    trailingPadding: 16
                )
            )

            buttons.append(
                .textButton(
                    text: ResourceManager.localized("createText", comment: ""),
                    action: {
                        Task {
                            await createTicketViewModel.submiTicket()
                        }
                    }
                )
            )
        }

        return buttons
    }

    @ViewBuilder
    func renderFieldView(
        for field: FormFieldModel,
        index: Int,
        proxy: ScrollViewProxy
    ) -> some View {
        if field.apiName == "cc"
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            CCTextfieldView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal ?? "",
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                selectedItems:
                    Binding(  // Creating a Binding
                        get: { createTicketViewModel.ccFieldvalues },
                        set: { newValue in
                            createTicketViewModel.updateCCFieldItems(
                                index: index,
                                selectedItems: newValue
                            )
                            _ = createTicketViewModel.ccFieldvalidation(
                                index: index,
                                selectedItems: newValue
                            )
                        }
                    ),
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if (field.fieldControlName
            == FormFieldType.singleLineTextBox.value
            || field.fieldControlName == FormFieldType.email.value)
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            TextFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding(  // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        createTicketViewModel.updatedEnteredText(
                            index: index,
                            text: newValue
                        )
                    }
                ),
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: createTicketViewModel.textFieldValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if (field.fieldControlName == FormFieldType.multiLineTextBox.value
            || field.fieldControlName == FormFieldType.description.value)
                && !(field.hideInCreateFormCustomerPortal ?? false)
                && field.isVisibleInCustomerPortal ?? false
                && field.isVisible ?? true
        {
            CustomTextEditor(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding(  // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        createTicketViewModel.updatedEnteredText(
                            index: index,
                            text: newValue
                        )
                    }
                ),
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validations: createTicketViewModel.textFieldValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.checkBox.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            CheckboxWithLabel(
                title: field.labelForCustomerPortal ?? "",
                showInfoButton: true,
                isChecked: field.isChecked ?? false,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                updateCheckBox: createTicketViewModel.updateRadioCheckBox,
                validation: createTicketViewModel.checkBoxValidation,
                noteMessage: field.noteMessage ?? "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.radioButton.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            RadioButtonsView(
                label: field.labelForCustomerPortal ?? "",
                selectedOption: field.isChecked ?? true,
                options: createTicketViewModel.radioOption,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: createTicketViewModel.checkBoxValidation,
                infoButtonVisible: true,
                updateSelectedRadioButton: createTicketViewModel
                    .updateRadioCheckBox,
                noteMessage: field.noteMessage ?? "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.date.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            FloatingLabelDateField(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                selectedDate: field.selectedDate,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                updateSelectedDate: createTicketViewModel.updateSelectedDate,
                validation: createTicketViewModel.dateTimeValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.datetime.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            FloatingLabelDateTimeField(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                selectedDateTime: field.selectedDateTime,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                updateSelectedDate: createTicketViewModel
                    .updateSelectedDateTime,
                validation: createTicketViewModel.dateTimeValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.numeric.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            NumericFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding(  // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        createTicketViewModel.updatedEnteredText(
                            index: index,
                            text: newValue
                        )
                    }
                ),
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: createTicketViewModel.textFieldValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                updateEnteredText: createTicketViewModel.updatedEnteredText,
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.decimal.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            DecimalFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding(  // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        createTicketViewModel.updatedEnteredText(
                            index: index,
                            text: newValue
                        )
                    }
                ),
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: createTicketViewModel.textFieldValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                updateEnteredText: createTicketViewModel.updatedEnteredText,
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if (field.fieldControlName == FormFieldType.dropdown.value
            || field.fieldControlName == FormFieldType.lookup.value)
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            SingleSelectDropdownView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                updateSelectedItem: createTicketViewModel.updateSelectedItem,
                validation: createTicketViewModel.singleSelectValidation,
                selectedItem: field.selectedItem,
                fetchItems: createTicketViewModel.getDropdownItems,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .top)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isDisabled: formDisabled,
                isValid: field.isValid ?? true
            )
        } else if field.fieldControlName == FormFieldType.multiselect.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            MultiSelectDropdownView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                updateSelectedItem: createTicketViewModel.updateSelectedItems,
                validation: createTicketViewModel.multiSelectValidation,
                selectedItem: field.selectedItems ?? [],
                fetchItems: createTicketViewModel.getDropdownItems,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .top)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.regex.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            TextFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding(  // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        createTicketViewModel.updatedEnteredText(
                            index: index,
                            text: newValue
                        )
                    }
                ),
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: createTicketViewModel.textFieldValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.url.value
            && !(field.hideInCreateFormCustomerPortal ?? false)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            TextFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding(  // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        createTicketViewModel.updatedEnteredText(
                            index: index,
                            text: newValue
                        )
                    }
                ),
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: createTicketViewModel.textFieldValidation,
                onTap: {
                    scrollToField(
                        fieldID: index,
                        proxy: proxy,
                        pointer: .center
                    )
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: formDisabled
            )
        } else if field.fieldControlName == FormFieldType.fileUpload.value && field.isVisible ?? true {
            AttachmentButton(onTap: {
                if DeviceConfig.isIPhone {
                    showFilePicker = true
                } else {
                    showFilePopover = true
                }
            })
            .popover(
                isPresented: $showFilePopover,
                attachmentAnchor: .rect(.bounds),
                arrowEdge: .bottom
            ) {
                filePickerBottomSheetContent(dismiss: {
                    showFilePopover = false
                }
                )
                .frame(width: min(280, UIScreen.main.bounds.width / 4))
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .background(Color.popoverBackground)
            }
            .padding(.bottom, uploadManager.pickedItems.count > 0 ? 12 : 20)
            attachmentRows
        } else {
            VStack(spacing: 0) {}
        }
    }
    func scrollToField(
        fieldID: Int?,
        proxy: ScrollViewProxy,
        pointer: UnitPoint
    ) {
        if let id = fieldID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    proxy.scrollTo(id, anchor: pointer)
                }
            }
        }
    }
}

extension UIApplication {
    func endEditing() {
        sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

extension View {
    @ViewBuilder
    func applyKeyboardToolbar() -> some View {
        if #available(iOS 15.0, *) {
            self.toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        UIApplication.shared.endEditing()
                    }.foregroundColor(Color.accentColor)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
        } else {
            self
        }
    }
}
