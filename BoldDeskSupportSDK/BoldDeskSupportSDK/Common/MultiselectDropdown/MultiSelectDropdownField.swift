import SwiftUI

struct MultiSelectDropdownField: View {
    var title: String
    var placeholder: String
    var isRequired: Bool
    var index: Int
    var updateSelectedItem: (Int, [DropdownItemModel]) -> Void
    var validation: ((Int, [DropdownItemModel]) -> Bool)? = nil
    var selectedItems: [DropdownItemModel]
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var showPicker: Bool = false
    @StateObject var multiSelectViewModel: MultiSelectViewModel
    @State private var hasUserInteracted = false

    init(title: String, placeholder: String, isRequired: Bool, index: Int, updateSelectedItem: @escaping (Int, [DropdownItemModel]) -> Void, validation: ((Int, [DropdownItemModel]) -> Bool)? = nil, selectedItems: [DropdownItemModel], fetchItems: @escaping (Int, String) async -> [DropdownItemModel], noteMessage: String? = nil,
                 errorMessage: String? = nil, isValid: Bool = true, isDisabled: Bool = false) {
        self.title = title
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.index = index
        self.updateSelectedItem = updateSelectedItem
        self.validation = validation
        self.selectedItems = selectedItems
        self.fetchItems = fetchItems
        self.noteMessage = noteMessage
        self.errorMessage = errorMessage
        self.isValid = isValid
        self.isDisabled = isDisabled
        _multiSelectViewModel = StateObject(wrappedValue: MultiSelectViewModel(fetchItemsAPI: fetchItems, tempSelectedItems: selectedItems))
    }
    
    var displayText: String {
        if selectedItems.isEmpty {
            return ""
        } else if selectedItems.count == 1 {
            return selectedItems.first?.displayName ?? ""
        } else {
            return "\(selectedItems.first?.displayName ?? "") +\(selectedItems.count - 1)"
        }
    }
    var floatingLabel: Text {
        var label = Text(title)
        
        if isRequired {
            label = label + Text(" *").foregroundColor(.textErrorPrimary)
        }
        return label
    }
    
    var body: some View {
        VStack(alignment: .leading){
            ZStack(alignment: .leading) {
                floatingLabel
                    .foregroundColor(Color.textPlaceHolderColor)
                    
                    .font(FontFamily.customFont(size: selectedItems.isEmpty ? FontSize.large : FontSize.xsmall, weight: .regular))
                    .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                    .padding(.horizontal, selectedItems.isEmpty ? 0 : 2)
                    .offset(y: selectedItems.isEmpty ? 0 : -28)
                    .scaleEffect(selectedItems.isEmpty ? 1 : 0.9, anchor: .leading)
                // Main dropdown content
                HStack {
                    Text(displayText)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        
                        .foregroundColor(Color.textPrimaryColor)
                    Spacer()
                    if !isDisabled {
                        AppIcon(icon: .chevronDown)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke((errorMessage?.isEmpty == false)
                            ? Color.textErrorPrimary
                            : .borderSecondaryColor, lineWidth: 1)
            )
            .contentShape(Rectangle())
            .onTapGesture {
                    showPicker = true
                    multiSelectViewModel.tempSelectedItems = selectedItems
                    multiSelectViewModel.loadItems(index: index, search: "")
            }
            .disabled(isDisabled)
            .animation(.easeOut, value: selectedItems)
            .onChange(of: selectedItems) { newValue in
                if hasUserInteracted {
                       _ = validation?(index, newValue)
                   } else {
                       hasUserInteracted = true
                   }
            }
            .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
            .sheet(isPresented: $showPicker) {
                BottomSheetMultiPicker(
                    title: title,
                    index: index,
                    updateSelectedItem: updateSelectedItem,
                    selectedItems: selectedItems,
                    isPresented: $showPicker,
                    multiSelectViewModel: multiSelectViewModel
                )
            }
            if let note = noteMessage, !note.isEmpty {
                Text(note)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textSecondaryColor)
            }
            if !isValid {
                Text(errorMessage ?? "")
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textErrorPrimary)
            }
        }.padding(.horizontal, 12)
            .padding(.bottom, 16)
    }
}
