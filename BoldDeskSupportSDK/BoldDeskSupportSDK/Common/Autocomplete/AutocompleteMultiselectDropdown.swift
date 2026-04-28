import SwiftUI
import UIKit

struct AutoCompleteMultiSelectDropdown: View {
    var label: String
    var placeholder: String
    var isRequired: Bool
    var index: Int
    var updateSelectedItem: (Int, [DropdownItemModel]) -> Void
    var validation: ((Int, [DropdownItemModel]) -> Bool)? = nil
    var selectedItems: [DropdownItemModel]
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var onTap: (() -> Void)? = nil
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    var closeButtonNotVisible: Bool = false
    @State private var showPicker: Bool = false
    @StateObject var multiSelectViewModel: MultiSelectViewModel
    @State private var searchText: String = ""
    @State private var isFocused: Bool = false
    @State private var didChangedBackspace: Bool = true
    
    init(label: String, placeholder: String, isRequired: Bool, index: Int, updateSelectedItem: @escaping (Int, [DropdownItemModel]) -> Void, validation: ((Int, [DropdownItemModel]) -> Bool)? = nil, selectedItems: [DropdownItemModel], fetchItems: @escaping (Int, String) async -> [DropdownItemModel], onTap: (() -> Void)? = nil, noteMessage: String? = nil, errorMessage: String? = nil, isValid: Bool = true, isDisabled: Bool = false, closeButtonNotVisible: Bool = false) {
        self.label = label
        self.placeholder = placeholder
        self.isRequired = isRequired
        self.index = index
        self.updateSelectedItem = updateSelectedItem
        self.validation = validation
        self.selectedItems = selectedItems
        self.fetchItems = fetchItems
        self.onTap = onTap
        self.noteMessage = noteMessage
        self.errorMessage = errorMessage
        self.isValid = isValid
        self.isDisabled = isDisabled
        self.closeButtonNotVisible = closeButtonNotVisible
        _multiSelectViewModel = StateObject(wrappedValue: MultiSelectViewModel(fetchItemsAPI: fetchItems, tempSelectedItems: selectedItems))
    }
    
    var body: some View {
        VStack(alignment: .leading){
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
                if multiSelectViewModel.tempSelectedItems.isEmpty && searchText.isEmpty {
                    Text(placeholder)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        .foregroundColor(.textSecondaryPlaceHolderColor)
                }
                VStack{
                    HStack() {
                        HStack() {
                            ForEach(multiSelectViewModel.tempSelectedItems.prefix(2), id: \.self) { item in
                                HStack(spacing: 4) {
                                    Text(item.displayName)
                                        .padding(.trailing, 2)
                                        .lineLimit(1)
                                    if !closeButtonNotVisible {
                                        Button(action: {
                                            if let selectedIndex = multiSelectViewModel.tempSelectedItems.firstIndex(where: { $0.id == item.id }) {
                                                multiSelectViewModel.tempSelectedItems.remove(at: selectedIndex)
                                                updateSelectedItem(index, multiSelectViewModel.tempSelectedItems)
                                            }
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
                                .frame(height: 28)
                                .padding(.horizontal, 4)
                                .padding(.leading, 4)
                                .background(Color.accentColor.opacity(0.2))
                                .cornerRadius(12)
                            }
                            if multiSelectViewModel.tempSelectedItems.count > 2 {
                                Text("+\(multiSelectViewModel.tempSelectedItems.count - 2) more")
                                    .padding(.horizontal, 8)
                                    .frame(height: 28)
                                    .padding(.leading, 2)
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(12)
                            }
                        }
                        
                        HStack() {
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
                                    multiSelectViewModel.loadItems(index: index, search: text)
                                },
                                onKeyPress: { key in
                                    if didChangedBackspace && searchText.isEmpty {
                                        if key == "\u{8}"  && !multiSelectViewModel.tempSelectedItems.isEmpty{
                                            multiSelectViewModel.tempSelectedItems.removeLast()
                                            updateSelectedItem(index, multiSelectViewModel.tempSelectedItems)
                                            didChangedBackspace = true
                                        }
                                    } else{
                                        didChangedBackspace = true
                                    }
                                }
                            )
                            .disabled(isDisabled)
                            .frame(maxWidth: .infinity)
                            if !isDisabled {
                                LoadingDownIcon(isLoading: multiSelectViewModel.isLoading)
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
                .onChange(of: selectedItems) { newValue in
                    multiSelectViewModel.tempSelectedItems = newValue
                    _ = validation?(index, newValue)
                }
                .onChange(of: isFocused) { newValue in
                    if newValue {
                        multiSelectViewModel.loadItems(index: index, search: searchText)
                        onTap?()
                    }
                    searchText = ""
                }
            }
            Rectangle()
                .frame(height: 1)
                .foregroundColor(!isValid
                                 ? Color.textErrorPrimary
                                 : (isFocused ? .accentColor : .borderSecondaryColor))
                .padding(.top, 10)
            
            if isFocused {
                Group {
                    if multiSelectViewModel.isLoading {
                        EmptyView()
                    } else if multiSelectViewModel.displayedItems.isEmpty {
                        // Only show "no results" AFTER loading completes
                        VStack {
                            Text(ResourceManager.localized("noRecordsFoundText"))
                                .foregroundColor(Color.textPrimary)
                                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        // Show dropdown list
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
                    .frame(alignment: .leading)
            }
            if !isFocused && !isValid {
                Text(errorMessage ?? "")
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                
                    .foregroundColor(.textErrorPrimary)
            }
        }
        .id(index)
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
    }
    
    private func dropdownView() -> some View {
        VStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(multiSelectViewModel.displayedItems, id: \.id) { item in
                        itemButton(item: item)
                    }
                }
            }
        }
    }
    
    private func itemButton(item: DropdownItemModel) -> some View {
        Button(action: {
            if multiSelectViewModel.tempSelectedItems.contains(item) {
                multiSelectViewModel.tempSelectedItems.removeAll { $0 == item }
                updateSelectedItem(index, multiSelectViewModel.tempSelectedItems)
            } else {
                multiSelectViewModel.tempSelectedItems.append(item)
                updateSelectedItem(index, multiSelectViewModel.tempSelectedItems)
            }
        }) {
            HStack {
                FormCheckBox(isChecked: multiSelectViewModel.tempSelectedItems.contains(item))
                    .foregroundColor(multiSelectViewModel.tempSelectedItems.contains(item) ? .accentColor : .buttonSecondaryBorderColor)
                Text(item.displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.textPrimary)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                
                    .padding(.leading, 8)
                Spacer()
            }
            .padding(16)
        }
    }
}

struct UIKitTextField: UIViewRepresentable {
    @Binding var text: String
    @Binding var focus: Bool
    var placeholder: String
    var onEditingChanged: ((Bool) -> Void)? = nil
    var onTextChanged: ((String) -> Void)? = nil
    var onKeyPress: ((String) -> Void)? = nil // change to String for general keys
    var onSubmit: (() -> Void)? = nil
    
    func makeUIView(context: Context) -> UITextField {
        let textField = KeyAwareTextField()
        textField.placeholder = placeholder
        textField.font = FontFamily.customUIFont(size: FontSize.large, weight: .regular)
        textField.textColor = UIColor.label
        textField.delegate = context.coordinator
        textField.onKeyPress = context.coordinator.keyPressed // hook key handler
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textChanged), for: .editingChanged)
        
        // ✅ Add Done button
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        let flexSpace = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: .done, target: context.coordinator, action: #selector(Coordinator.doneTapped))
        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text
        if focus && !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !focus && uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(
            text: $text,
            focus: $focus,
            onEditingChanged: onEditingChanged,
            onTextChanged: onTextChanged,
            onKeyPress: onKeyPress,
            onSubmit: onSubmit
        )
    }
    
    // MARK: - Custom UITextField that handles key presses
    class KeyAwareTextField: UITextField {
        var onKeyPress: ((String) -> Void)?
        
        override func deleteBackward() {
            super.deleteBackward()
            onKeyPress?("\u{8}") // backspace
        }
        
        // Optionally override insertText if needed
        override func insertText(_ text: String) {
            super.insertText(text)
            onKeyPress?(text)
        }
    }
    
    // MARK: - Coordinator
    class Coordinator: NSObject, UITextFieldDelegate {
        @Binding var text: String
        @Binding var focus: Bool
        var onEditingChanged: ((Bool) -> Void)?
        var onTextChanged: ((String) -> Void)?
        var onKeyPress: ((String) -> Void)?
        var onSubmit: (() -> Void)?
        
        init(text: Binding<String>, focus: Binding<Bool>, onEditingChanged: ((Bool) -> Void)? = nil, onTextChanged: ((String) -> Void)? = nil, onKeyPress: ((String) -> Void)? = nil, onSubmit: (() -> Void)? = nil) {
            _text = text
            _focus = focus
            self.onEditingChanged = onEditingChanged
            self.onTextChanged = onTextChanged
            self.onKeyPress = onKeyPress
            self.onSubmit = onSubmit
        }
        
        func textFieldDidBeginEditing(_ textField: UITextField) {
            onEditingChanged?(true)
        }
        
        func textFieldDidEndEditing(_ textField: UITextField) {
            onEditingChanged?(false)
            DispatchQueue.main.async {
                self.focus = false
            }
            onSubmit?()
        }
        
        @objc func textChanged(_ textField: UITextField) {
            text = textField.text ?? ""
            onTextChanged?(text)
        }
        
        @objc func doneTapped() {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
            DispatchQueue.main.async {
                self.focus = false
            }
        }
        
        func keyPressed(_ key: String) {
            onKeyPress?(key)
        }
        
        // OPTIONAL: Handle before text changes
        func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
            keyPressed(string)
            return true
        }
    }
}
