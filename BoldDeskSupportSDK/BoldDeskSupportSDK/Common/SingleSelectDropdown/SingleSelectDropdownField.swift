import SwiftUI

struct SingleSelectDropdownField: View {
    var title: String
    var placeholder: String
    var isRequired: Bool
    var index: Int
    var updateSelectedItem: (Int, DropdownItemModel?) -> Void
    var validation: ((Int, DropdownItemModel?) -> Bool)? = nil
    var selectedItem: DropdownItemModel?
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    var hideResetButton: Bool = false
    @State private var showPicker: Bool = false
    @StateObject var singleSelectViewModel: SingleSelectViewModel
    @State private var hasUserInteracted = false

    public init(
        title: String,
        placeholder: String,
        isRequired: Bool,
        index: Int,
        updateSelectedItem: @escaping (Int, DropdownItemModel?) -> Void,
        validation: ((Int, DropdownItemModel?) -> Bool)? = nil,
        selectedItem: DropdownItemModel? = nil,
        fetchItems: @escaping (Int, String) async -> [DropdownItemModel],
        noteMessage: String? = nil,
        errorMessage: String? = nil,
        isValid: Bool = true,
        isDisabled: Bool = false,
        hideResetButton: Bool = false
    ) {
        self.title = title
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.index = index
        self.updateSelectedItem = updateSelectedItem
        self.validation = validation
        self.selectedItem = selectedItem
        self.fetchItems = fetchItems
        self.noteMessage = noteMessage
        self.errorMessage = errorMessage
        self.isValid = isValid
        self.isDisabled = isDisabled
        self.hideResetButton = hideResetButton
        _singleSelectViewModel = StateObject(
            wrappedValue: SingleSelectViewModel(
                fetchItemsAPI: fetchItems,
                selectedItem: selectedItem
            )
        )
    }

    var floatingLabel: Text {
        var label = Text(title)

        if isRequired {
            label = label + Text(" *").foregroundColor(.textErrorPrimary)
        }
        return label
    }

    var body: some View {
        VStack(alignment: .leading) {
            ZStack(alignment: .leading) {
                // Floating placeholder
                floatingLabel
                    .foregroundColor(Color.textPlaceHolderColor)

                    .font(
                        FontFamily.customFont(
                            size: selectedItem == nil
                                ? FontSize.large : FontSize.xsmall,
                            weight: .regular
                        )
                    )
                    .background(
                        isDisabled
                            ? Color.disabledColor : Color.backgroundPrimary
                    )
                    .padding(.horizontal, selectedItem == nil ? 0 : 2)
                    .offset(y: selectedItem == nil ? 0 : -30)
                    .scaleEffect(
                        selectedItem == nil ? 1 : 0.9,
                        anchor: .leading
                    )

                // Main dropdown content
                HStack {
                    if let displayName = selectedItem?.displayName {
                        Text(displayName.isEmpty ? "--" : displayName)
                            .font(
                                FontFamily.customFont(
                                    size: FontSize.large,
                                    weight: .regular
                                )
                            )

                            .foregroundColor(Color.textPrimaryColor)
                    } else {
                        Text("")
                            .foregroundColor(.textPrimaryColor)
                    }
                    Spacer()
                    if !isDisabled {
                        AppIcon(icon: .chevronDown)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(
                        (errorMessage?.isEmpty == false)
                            ? Color.textErrorPrimary
                            : .borderSecondaryColor,
                        lineWidth: 1
                    )
            )
            .contentShape(Rectangle())  // Make entire area tappable
            .onTapGesture {
                Task {
                    showPicker = true
                    singleSelectViewModel.selectedItem = selectedItem
                    await singleSelectViewModel.loadItems(
                        index: index,
                        search: ""
                    )
                }
            }
            .disabled(isDisabled)
            .onChange(of: selectedItem) { newValue in
                if hasUserInteracted {
                    _ = validation?(index, newValue)
                } else {
                    hasUserInteracted = true
                }
            }
            .animation(.easeOut, value: selectedItem)
            .background(
                isDisabled ? Color.disabledColor : Color.backgroundPrimary
            )
            .sheet(isPresented: $showPicker) {
                BottomSheetSinglePicker(
                    title: title,
                    index: index,
                    hideResetButton: hideResetButton,
                    updateSeelectedItem: updateSelectedItem,
                    selectedItem: selectedItem,
                    isPresented: $showPicker,
                    singleSelectViewModel: singleSelectViewModel
                )
            }
            if let note = noteMessage, !note.isEmpty {
                Text(note)
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .regular
                        )
                    )

                    .foregroundColor(.textSecondaryColor)
            }
            if !isValid {
                Text(errorMessage ?? "")
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .regular
                        )
                    )

                    .foregroundColor(.textErrorPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 16)
    }
}
