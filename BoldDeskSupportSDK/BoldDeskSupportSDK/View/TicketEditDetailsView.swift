import SwiftUI

struct TicketEditDetailsView: View {
    var ticketId: Int
    @Binding var isRefreshPropertiesTab : Bool
    @StateObject private var uploadManager = UploadManager()
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var ticketDetaisViewModel: TicketEditDetailsViewModel
    @EnvironmentObject var toastManager: ToastManager
    
    init(ticketId: Int, isRefreshPropertiesTab : Binding<Bool>) {
        self.ticketId = ticketId
        self._isRefreshPropertiesTab = isRefreshPropertiesTab
        _ticketDetaisViewModel = StateObject(wrappedValue: TicketEditDetailsViewModel(ticketId: String(ticketId)))
    }
    
    var body: some View {
        AppPage(
            
        ) {
            ZStack{
                VStack(alignment: .leading) {
                    if DeviceConfig.isIPhone {
                        CommonAppBar(
                            title: ResourceManager.localized("detailsText", comment: ""),
                            showBackButton: true,
                            onBack: {
                                presentationMode.wrappedValue.dismiss()
                            }
                        )
                    }
                    else{
                        DialogAppBar(title: ResourceManager.localized("detailsText", comment: ""), actionButtons: buildActionButtons(), onBack: {
                            presentationMode.wrappedValue.dismiss()
                        })
                    }
                    ZStack{
                        if ticketDetaisViewModel.isLoading {
                            CreateTicketShimmer()
                        }
                        else{
                            ScrollViewReader { proxy in
                                ScrollView {
                                    RequesterCardView(name: ticketDetaisViewModel.ticketDetailsModel?.requester?.displayName ?? "")
                                    ForEach(Array(ticketDetaisViewModel.formFieldModel.enumerated()), id: \.element.id) { index, field in
                                        renderFieldView(for: field, index: index, proxy: proxy)
                                    }
                                }
                                .applyKeyboardToolbar()
                            }
                        }
                    }.frame(maxHeight: .infinity)
                    if DeviceType.isPhone && ticketDetaisViewModel.hasFormChanged && !ticketDetaisViewModel.isLoading {
                        VStack(alignment: .leading) {
                            Divider()
                            HStack(spacing: 12) {
                                FilledButton(title: ResourceManager.localized("updateText",comment: ""), onClick: {
                                    Task{
                                        await ticketDetaisViewModel.updateTicket()
                                    }
                                })
                                
                                OutlinedButton(title:ResourceManager.localized("cancelText",comment: ""), onClick: {
                                    presentationMode.wrappedValue.dismiss()
                                })
                            }
                            .padding(.top, 12)
                            .padding(.bottom, 12)
                            .padding(.leading)
                            Divider()
                                .frame(height: 1)
                                .background(Color.cardBackgroundPrimary)
                        }
                        .background(Color.backgroundPrimary)
                    }
                    if DeviceConfig.isIPhone {
                        PoweredByFooterView()
                    }
                }
                .background( DeviceConfig.isIPhone ? Color.cardBackgroundPrimary : Color.backgroundPrimary)
                .onChange(of: ticketDetaisViewModel.isRefresh) { refresh in
                    if refresh {
                        isRefreshPropertiesTab = true
                    }
                }
                if ticketDetaisViewModel.isShowProgress {
                    Color.black.opacity(0.3)            // dim background
                        .ignoresSafeArea()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }
                //                if DeviceType.isPhone && !ticketDetaisViewModel.isLoading {
                //                    BottomSheet(cardShow: $cardShow, height: UIScreen.main.bounds.height / 5.5, content: {
                //                        AttachmentBodyContent(manager: uploadManager, onTap: {
                //                            cardShow = false
                //                        })
                //
                //                    })
                //
                //                }
            }
        }
        .background(Color.cardBackgroundPrimary)
        .onChange(of: ticketDetaisViewModel.shouldDismiss) { newValue in
            presentationMode.wrappedValue.dismiss()
        }
        .navigationBarHidden(true)
        .overlay(ToastStackView())
    }
    
    func buildActionButtons() -> [CustomAppBarAction] {
        var buttons: [CustomAppBarAction] = []
        
        if !ticketDetaisViewModel.isLoading && !ticketDetaisViewModel.isShowProgress && ticketDetaisViewModel.hasFormChanged {
            buttons.append(
                .textButton(text: ResourceManager.localized("updateText", comment: ""), action: {
                    Task{
                        await ticketDetaisViewModel.updateTicket()
                    }
                })
            )
        }

        return buttons
    }
    
    @ViewBuilder
    func renderFieldView(for field: FormFieldModel, index: Int, proxy: ScrollViewProxy) -> some View {
        if field.apiName == "cc"
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
            && GeneralSettings.ccConfiguration?.isCcEnabled ?? false
        {
            CCTextfieldView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal ?? "",
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                selectedItems:
                    Binding(  // Creating a Binding
                        get: { ticketDetaisViewModel.ccFieldvalues },
                        set: { newValue in
                            ticketDetaisViewModel.updateCCFieldItems(
                                index: index,
                                selectedItems: newValue
                            )
                            _ = ticketDetaisViewModel.ccFieldvalidation(
                                index: index,
                                selectedItems: newValue
                            )
                        }
                    ),
                noteMessage: field.noteMessageDisplayBelowField ?? false
                    ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true) && !(GeneralSettings.ccConfiguration?.isCCEnabledInCustomerPortal ?? true)
            )
        }
        else if (field.fieldControlName == FormFieldType.singleLineTextBox.value ||
            field.fieldControlName == FormFieldType.email.value)
            && field.apiName != "cc"
//            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true {
            TextFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding( // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        ticketDetaisViewModel.updatedEnteredText(index: index, text: newValue)
                    }
                             ),
                index : index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: ticketDetaisViewModel.textFieldValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true)
            )
        }
        else if (field.fieldControlName == FormFieldType.multiLineTextBox.value
                    || field.fieldControlName == FormFieldType.description.value)
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            CustomTextEditor(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding( // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        ticketDetaisViewModel.updatedEnteredText(index: index, text: newValue)
                    }
                             ),
                index : index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validations: ticketDetaisViewModel.textFieldValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true))
        }
        else if field.fieldControlName == FormFieldType.checkBox.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            CheckboxWithLabel(
                title: field.labelForCustomerPortal ?? "",
                showInfoButton: field.noteMessage?.isEmpty == false,
                isChecked: field.isChecked ?? false,
                index: index,
                isRequired:field.isRequiredInCustomerPortal ?? false,
                updateCheckBox : ticketDetaisViewModel.updateRadioCheckBox,
                validation: ticketDetaisViewModel.checkBoxValidation,
                noteMessage: field.noteMessage ?? "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled:!(field.userCanEdit ?? true)
            )
        }
        else if field.fieldControlName == FormFieldType.radioButton.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            RadioButtonsView(
                label:field.labelForCustomerPortal ?? "",
                selectedOption: field.isChecked ?? true,
                options: ticketDetaisViewModel.radioOption,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: ticketDetaisViewModel.checkBoxValidation,
                infoButtonVisible: field.noteMessage?.isEmpty == false,
                updateSelectedRadioButton: ticketDetaisViewModel.updateRadioCheckBox,
                noteMessage: field.noteMessage ?? "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled:!(field.userCanEdit ?? true))
        }
        else if field.fieldControlName == FormFieldType.date.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            FloatingLabelDateField(
                label: field.labelForCustomerPortal ?? "" ,
                placeholder: field.placeholderForCustomerPortal,
                selectedDate: field.selectedDate,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                updateSelectedDate : ticketDetaisViewModel.updateSelectedDate,
                validation: ticketDetaisViewModel.dateTimeValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true))
        }
        
        else if field.fieldControlName == FormFieldType.datetime.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            FloatingLabelDateTimeField(
                label: field.labelForCustomerPortal ?? "" ,
                placeholder: field.placeholderForCustomerPortal,
                selectedDateTime: field.selectedDateTime,
                index: index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                updateSelectedDate : ticketDetaisViewModel.updateSelectedDateTime,
                validation: ticketDetaisViewModel.dateTimeValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true))
        }
        else if field.fieldControlName == FormFieldType.numeric.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            NumericFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding( // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        ticketDetaisViewModel.updatedEnteredText(index: index, text: newValue)
                    }
                             ),
                index : index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: ticketDetaisViewModel.textFieldValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                }, updateEnteredText: ticketDetaisViewModel.updatedEnteredText,
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true)
            )
        }
        
        else if field.fieldControlName == FormFieldType.decimal.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            DecimalFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding( // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        ticketDetaisViewModel.updatedEnteredText(index: index, text: newValue)
                    }
                             ),
                index : index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: ticketDetaisViewModel.textFieldValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                updateEnteredText: ticketDetaisViewModel.updatedEnteredText,
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true))
        }
        else if field.apiName == DefaultFieldAPIName.status.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            SingleSelectDropdownView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                updateSelectedItem: ticketDetaisViewModel.updateSelectedItem,
                validation: ticketDetaisViewModel.singleSelectValidation,
                selectedItem: field.selectedItem,
                fetchItems: ticketDetaisViewModel.getDropdownItems,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .top)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isDisabled: true,
                isValid: field.isValid ?? true,
                hideResetButton: true
            )
        }
        else if field.apiName == DefaultFieldAPIName.form.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            SingleSelectDropdownView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                updateSelectedItem: ticketDetaisViewModel.updateForm,
                validation: ticketDetaisViewModel.singleSelectValidation,
                selectedItem: field.selectedItem,
                fetchItems: ticketDetaisViewModel.getFormDropdownItems,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .top)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isDisabled: field.userCanEdit == false,
                isValid: field.isValid ?? true,
                hideResetButton: true
            )
        }
        else if (field.fieldControlName == FormFieldType.dropdown.value || field.fieldControlName == FormFieldType.lookup.value)
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            SingleSelectDropdownView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                updateSelectedItem: ticketDetaisViewModel.updateSelectedItem,
                validation: ticketDetaisViewModel.singleSelectValidation,
                selectedItem: field.selectedItem,
                fetchItems: ticketDetaisViewModel.getDropdownItems,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .top)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isDisabled: !(field.userCanEdit ?? true),
                isValid: field.isValid ?? true,
                hideResetButton: !(field.userCanEdit ?? true)
            )
        }
        else if field.fieldControlName == FormFieldType.multiselect.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            MultiSelectDropdownView(
                title: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                index: index,
                updateSelectedItem: ticketDetaisViewModel.updateSelectedItems,
                validation: ticketDetaisViewModel.multiSelectValidation,
                selectedItem: field.selectedItems ?? [],
                fetchItems: ticketDetaisViewModel.getDropdownItems,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .top)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true),
                hideResetButton: !(field.userCanEdit ?? true))
        }
        else if field.fieldControlName == FormFieldType.regex.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            TextFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding( // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        ticketDetaisViewModel.updatedEnteredText(index: index, text: newValue)
                    }
                             ),
                index : index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: ticketDetaisViewModel.textFieldValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true)
            )
        }
        else if field.fieldControlName == FormFieldType.url.value
                    && field.isVisibleInCustomerPortal ?? false
                    && field.isVisible ?? true {
            TextFieldView(
                label: field.labelForCustomerPortal ?? "",
                placeholder: field.placeholderForCustomerPortal,
                text: Binding( // Creating a Binding
                    get: { field.text ?? "" },
                    set: { newValue in
                        ticketDetaisViewModel.updatedEnteredText(index: index, text: newValue)
                    }
                             ),
                index : index,
                isRequired: field.isRequiredInCustomerPortal ?? false,
                validation: ticketDetaisViewModel.textFieldValidation,
                onTap: {
                    scrollToField(fieldID: index, proxy: proxy, pointer: .center)
                },
                noteMessage: field.noteMessageDisplayBelowField ?? false ? field.noteMessage : "",
                errorMessage: field.errorMessage ?? "",
                isValid: field.isValid ?? true,
                isDisabled: !(field.userCanEdit ?? true)
            )
        }
        else {
            EmptyView()
        }
    }
    func scrollToField(fieldID: Int?, proxy: ScrollViewProxy, pointer: UnitPoint) {
        if let id = fieldID {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation {
                    proxy.scrollTo(id, anchor: pointer)
                }
            }
        }
    }
}


