import SwiftUI

struct PropertiesCardScreen: View {
    var ticketId: Int
    @StateObject private var ticketDetaisViewModel: TicketEditDetailsViewModel
    @EnvironmentObject var toastManager: ToastManager
    @Binding private var ensureCloseTicketActionRestriction : Bool
    let canEditDetails: Bool
    
    init(
        ticketId: Int,
        ensureCloseTicketActionRestriction: Binding<Bool>,
        canEditDetails: Bool
    ) {
        self.ticketId = ticketId
        self._ensureCloseTicketActionRestriction = ensureCloseTicketActionRestriction;
        _ticketDetaisViewModel = StateObject(
            wrappedValue: TicketEditDetailsViewModel(ticketId: String(ticketId))
        )
        self.canEditDetails = canEditDetails
    }
    
    var body: some View {
        if ticketDetaisViewModel.isLoading {
            CreateTicketShimmer()
        } else {
            ScrollView {
                PropertiesCardView(
                    ticketId: ticketId,
                    ticketDetaisViewModel: ticketDetaisViewModel,
                    ensureCloseTicketActionRestriction: $ensureCloseTicketActionRestriction,
                    canEditDetails: canEditDetails
                )
                .padding(.bottom, 74)
            }
        }
    }
}

struct PropertiesCardView: View {
    let ticketId: Int
    let ticketDetaisViewModel: TicketEditDetailsViewModel
    let canEditDetails: Bool
    
    @State private var isShow = false
    @State private var isRefreshPropertiesTab = false
    @Binding var ensureCloseTicketActionRestriction : Bool
    
    init(
        ticketId: Int,
        ticketDetaisViewModel: TicketEditDetailsViewModel,
        ensureCloseTicketActionRestriction: Binding<Bool>,
        canEditDetails: Bool
    ) {
        self.ticketId = ticketId
        self.ticketDetaisViewModel = ticketDetaisViewModel
        self._ensureCloseTicketActionRestriction = ensureCloseTicketActionRestriction
        self.canEditDetails = canEditDetails
    }
    
    private var canEdit: Bool {
        guard
            let requesterId =  ticketDetaisViewModel.ticketDetailsModel?.requester?.userId,
            let currentUserId = UserInfo.userId
        else {
            return false
        }
        
        return requesterId == currentUserId || (!GeneralSettings.isMyOrganizationViewDisabledInCustomerPortal && canEditDetails)
    }
    
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                if canEdit && ensureCloseTicketActionRestriction {
                    if DeviceConfig.isIPhone {
                        NavigationLink(
                            destination: TicketEditDetailsView(
                                ticketId: ticketId,
                                isRefreshPropertiesTab: $isRefreshPropertiesTab
                            ),
                            label: {
                                Text(ResourceManager.localized(
                                        "editText",
                                        comment: ""
                                    )
                                )
                                .font(
                                    FontFamily.customFont(
                                        size: FontSize.medium,
                                        weight: .semibold
                                    )
                                )
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .frame(maxHeight: 32)
                                .background(Color.backgroundPrimary)
                                .foregroundColor(Color.accentColor)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.accentColor, lineWidth: 1)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                            }
                        )
                    } else {
                        FilledButton(
                            title: ResourceManager.localized(
                                "editText",
                                comment: ""
                            ),
                            onClick: {
                                isShow = true
                            },
                            isSmall: true
                        )
                    }
                }
            }
            .sheet(isPresented: $isShow) {
                TicketEditDetailsView(
                    ticketId: ticketId,
                    isRefreshPropertiesTab: $isRefreshPropertiesTab
                )
                .background(Color.backgroundOverlayColor)
            }
            .padding(.vertical, 20)
            VStack(spacing: 0) {
                ForEach(
                    Array(ticketDetaisViewModel.formFieldModel.enumerated()),
                    id: \.element.id
                ) { _, field in
                    renderFieldView(for: field)
                    if field.isVisibleInCustomerPortal ?? false
                        && field.isVisible ?? true
                    {
                        Devider()
                    }
                }
            }
            .background(Color.cardBackgroundPrimary)
            .cornerRadius(10)
//            .shadow(color: Color.black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .onChange(of: isRefreshPropertiesTab) { refresh in
            if refresh {
                Task {
                    await ticketDetaisViewModel.getFieldsAndApplyCondition()
                }
            }
        }
        .ignoresSafeArea()
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .background(Color.backgroundPrimary)
    }

    @ViewBuilder
    func renderFieldView(for field: FormFieldModel) -> some View {
        if ((field.fieldControlName == FormFieldType.singleLineTextBox.value && field.apiName != "cc")
            || field.fieldControlName == FormFieldType.email.value
            || field.fieldControlName == FormFieldType.multiLineTextBox.value
            || field.fieldControlName == FormFieldType.description.value
            || field.fieldControlName == FormFieldType.numeric.value
            || field.fieldControlName == FormFieldType.decimal.value
            || field.fieldControlName == FormFieldType.regex.value
            || field.fieldControlName == FormFieldType.url.value
            || (field.apiName == "cc" && GeneralSettings.ccConfiguration?.isCcEnabled ?? false))
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            PropertyRow(
                title: field.labelForCustomerPortal ?? "",
                subtitle: field.text?.isEmpty == false ? field.text! : "--"
            )
        } else if field.fieldControlName == FormFieldType.date.value
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            PropertyRow(
                title: field.labelForCustomerPortal ?? "",
                subtitle: field.selectedDate?.isEmpty == false
                    ? field.selectedDate! : "--"
            )
        } else if field.fieldControlName == FormFieldType.datetime.value
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            PropertyRow(
                title: field.labelForCustomerPortal ?? "",
                subtitle: field.selectedDateTime?.isEmpty == false
                    ? field.selectedDateTime! : "--"
            )
        } else if (field.apiName == DefaultFieldAPIName.status.value
            || field.apiName == DefaultFieldAPIName.agent.value
            || field.apiName == DefaultFieldAPIName.form.value
            || field.fieldControlName == FormFieldType.dropdown.value
            || field.fieldControlName == FormFieldType.lookup.value)
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            PropertyRow(
                title: field.labelForCustomerPortal ?? "",
                subtitle: field.selectedItem?.displayName.isEmpty == false
                ? field.selectedItem!.displayName : field.apiName == DefaultFieldAPIName.agent.value ? ResourceManager.localized("notYetAssignedText", comment: "") : "--"
            )
        } else if field.fieldControlName == FormFieldType.multiselect.value
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            MultiselectPropertyRow(
                title: field.labelForCustomerPortal ?? "",
                dropdownItems: field.selectedItems ?? []
            )
        } else if field.fieldControlName == FormFieldType.checkBox.value
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            CheckboxWithLabel(
                title: field.labelForCustomerPortal ?? "",
                showInfoButton: false,
                isChecked: field.isChecked ?? false,
                index: 0,
                isRequired: false,
                updateCheckBox: ticketDetaisViewModel.updateRadioCheckBox,
                validation: ticketDetaisViewModel.checkBoxValidation,
                isValid: field.isValid ?? true,
                isDisabled: true
            )
            .padding(.top, 14)
        } else if field.fieldControlName == FormFieldType.radioButton.value
            && field.isVisibleInCustomerPortal ?? false
            && field.isVisible ?? true
        {
            RadioButtonsView(
                label: field.labelForCustomerPortal ?? "",
                selectedOption: field.isChecked ?? true,
                options: ticketDetaisViewModel.radioOption,
                index: 1,
                isRequired: false,
                validation: ticketDetaisViewModel.checkBoxValidation,
                infoButtonVisible: false,
                updateSelectedRadioButton: ticketDetaisViewModel
                    .updateRadioCheckBox,
                isValid: field.isValid ?? true,
                isDisabled: true
            )
            .padding(.top, 14)
        } else {
            EmptyView()
        }
    }
}

struct PropertyRow: View {
    var title: String
    var subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(
                    FontFamily.customFont(
                        size: FontSize.medium,
                        weight: .medium
                    )
                )

                .foregroundColor(Color.textPrimaryColor)

            Text(subtitle)
                .font(
                    FontFamily.customFont(
                        size: FontSize.medium,
                        weight: .regular
                    )
                )
                .foregroundColor(
                    Color.textSecondaryColor
                )
        }
        .padding(.all, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct MultiselectPropertyRow: View {
    var title: String
    var dropdownItems: [DropdownItemModel]
    let itemsToShow: ArraySlice<DropdownItemModel>
    let remainingCount: Int
    init(title: String, dropdownItems: [DropdownItemModel]) {
        self.title = title
        self.dropdownItems = dropdownItems
        itemsToShow = dropdownItems.prefix(1)
        remainingCount = dropdownItems.count - itemsToShow.count
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(
                    FontFamily.customFont(
                        size: FontSize.medium,
                        weight: .medium
                    )
                )
                .foregroundColor(Color.textPrimaryColor)

            if let firstItem = itemsToShow.first {
                Text(
                    "\(firstItem.displayName)\(remainingCount > 0 ? " +\(remainingCount) more" : "")"
                )
                .font(
                    FontFamily.customFont(
                        size: FontSize.medium,
                        weight: .regular
                    )
                )
                .foregroundColor(Color.textSecondaryColor)
            } else {
                Text("--")
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .regular
                        )
                    )
                    .foregroundColor(Color.textSecondaryColor)

            }
        }
        .padding(.all, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    final class PropertiesCardViewModel: ObservableObject {
        @Published var isLoading = true

        init() {
            loadData()
        }

        private func loadData() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                self.isLoading = false
            }
        }
    }
}
