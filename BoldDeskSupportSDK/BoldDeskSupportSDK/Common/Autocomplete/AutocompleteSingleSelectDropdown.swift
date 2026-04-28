import SwiftUI
import UIKit

struct AutoCompleteSingleSelectDropdown: View {
    
    var label: String
    var placeholder: String
    var isRequired: Bool
    var index: Int
    var updateSelectedItem: (Int, DropdownItemModel?) -> Void
    var validation: ((Int, DropdownItemModel?) -> Bool)? = nil
    var selectedItem: DropdownItemModel?
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var onTap: (() -> Void)? = nil
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    var closeButtonNotVisible: Bool = false
    @State private var showPicker: Bool = false
    @StateObject var singleSelectViewModel: SingleSelectViewModel
    @State private var searchText: String = ""
    @State private var isFocused: Bool = false
    @State private var didChangedBackspace: Bool = true
    @Environment(\.colorScheme) var colorScheme
    
    init(label: String, placeholder: String, isRequired: Bool, index: Int, updateSelectedItem: @escaping (Int, DropdownItemModel?) -> Void, validation: ((Int, DropdownItemModel?) -> Bool)? = nil, selectedItem: DropdownItemModel?, fetchItems: @escaping (Int, String) async -> [DropdownItemModel], onTap: (() -> Void)? = nil, noteMessage: String? = nil, errorMessage: String? = nil, isValid: Bool = true, isDisabled: Bool = false, closeButtonNotVisible: Bool = false) {
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.index = index
        self.updateSelectedItem = updateSelectedItem
        self.validation = validation
        self.selectedItem = selectedItem
        self.fetchItems = fetchItems
        self.onTap = onTap
        self.noteMessage = noteMessage
        self.errorMessage = errorMessage
        self.isValid = isValid
        self.isDisabled = isDisabled
        self.closeButtonNotVisible = closeButtonNotVisible
        _singleSelectViewModel = StateObject(wrappedValue: SingleSelectViewModel(fetchItemsAPI: fetchItems, selectedItem: selectedItem))
    }
    
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 0) {
                Text(label)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .medium)) // ✅ apply to this
                
                    .foregroundColor(.textPrimaryColor)
                
                if isRequired {
                    Text(" *")
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .bold)) // ✅ also here
                    
                        .foregroundColor(.textErrorPrimary)
                }
            }.padding(.bottom, 10)
            ZStack(alignment: .leading) {
                if singleSelectViewModel.selectedItem == nil && searchText.isEmpty {
                    Text(placeholder)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                    
                        .foregroundColor(.textSecondaryPlaceHolderColor)
                }
                
                VStack {
                    HStack {
                        if let item = singleSelectViewModel.selectedItem {
                            if !item.displayName.isEmpty{
                                HStack(spacing: 4) {
                                    Text(item.displayName)
                                        .padding(.trailing, 2)
                                        .frame(height: 28)
                                        .lineLimit(1)
                                    if !closeButtonNotVisible {
                                        Button(action: {
                                            updateSelectedItem(index, nil)
                                        }) {
                                            AppIcon(icon: .close)
                                        }
                                    }
                                }
                                .onTapGesture {
                                    if !isDisabled {
                                        isFocused = true
                                    }
                                }
                                .padding(.leading, 3)
                                .padding(.horizontal, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(12)
                            }
                            else{
                                Text("--")
                                    .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                                
                                    .foregroundColor(Color.textPrimaryColor)
                            }
                        }
                        HStack{
                            UIKitTextField(
                                text: $searchText,
                                focus: $isFocused,
                                placeholder: "",
                                onEditingChanged: { isEditing in
                                    withAnimation {
                                        DispatchQueue.main.async {
                                            isFocused = isEditing
                                        }
                                    }
                                },
                                onTextChanged: { text in
                                    guard isFocused else { return }
                                    didChangedBackspace = false
                                    Task {
                                        await singleSelectViewModel.loadItems(index: index, search: text)
                                    }
                                },
                                onKeyPress: { key in
                                    if searchText.isEmpty && didChangedBackspace {
                                        print(searchText + " searchtext")
                                        print( "didchanged \(didChangedBackspace)")
                                        print(singleSelectViewModel.selectedItem == nil)
                                        if  key == "\u{8}" && singleSelectViewModel.selectedItem != nil {
                                            print("backspace pressed")
                                            updateSelectedItem(index, nil)
                                            didChangedBackspace = true
                                        }
                                    }else{
                                        didChangedBackspace = true                                }
                                }
                                
                            )
                            .disabled(isDisabled)
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                onTap?()
                            }
                            if !isDisabled {
                                LoadingDownIcon(isLoading: singleSelectViewModel.isLoading)
                                    .onTapGesture {
                                        if !isDisabled && !isFocused {
                                            isFocused = true
                                        } else if !isDisabled && isFocused {
                                            UIApplication.shared.endEditing()
                                        }
                                    }
                            }
                        }
                    }
                }
            }
            .onChange(of: isFocused) { newValue in
                if newValue {
                    Task {
                        await singleSelectViewModel.loadItems(index: index, search: searchText)
                        onTap?()
                    }
                }
                searchText = ""
            }
            .onChange(of: selectedItem) { newValue in
                _ = validation?(index, newValue)
                singleSelectViewModel.selectedItem = newValue
            }
            Rectangle()
                .frame(height: 1)
                .foregroundColor(!isValid
                                 ? Color.textErrorPrimary
                                 : (isFocused ? .accentColor : .borderSecondaryColor))
                .padding(.top, 10)
            if isFocused {
                Group {
                    if singleSelectViewModel.isLoading {
                        EmptyView()
                    }
                    else if singleSelectViewModel.items.isEmpty {
                        VStack {
                            Text(ResourceManager.localized("noRecordsFoundText"))
                                .foregroundColor(Color.textPrimary)
                                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                            
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        dropdownView()
                    }
                }
                .frame(maxHeight: 200)
                .background(Color.backgroundPrimary)
                .cornerRadius(8)
                .shadow(radius: 4)
                .padding(.top, 2)
            }
            if let note = noteMessage, !note.isEmpty {
                Text(note)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                
                    .foregroundColor(.textSecondaryColor)
            }
            if !isFocused && !isValid {
                Text(errorMessage ?? "")
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                
                    .foregroundColor(.textErrorPrimary)
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .id(index)
        
    }
    
    private func dropdownView() -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(singleSelectViewModel.items, id: \.self) { item in
                    itemButton(item: item)
                }
            }
        }
    }
    
    private func itemButton(item: DropdownItemModel) -> some View {
        Button(action: {
            if singleSelectViewModel.selectedItem?.id != item.id {
                updateSelectedItem(index, item)
            }
            
            searchText = ""
            isFocused = false
            // Hide the keyboard
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }) {
            VStack {
                Text(item.displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(.textPrimaryColor)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                if item.subtitle.isEmpty == false {
                    Text(item.subtitle)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundColor(Color.textSecondaryColor)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(item.id == singleSelectViewModel.selectedItem?.id ? colorScheme == .dark ? Color.backgroundPrimary : Color.accentColor.opacity(0.1)
                        : Color.cardBackgroundPrimary)
        }
    }
}
