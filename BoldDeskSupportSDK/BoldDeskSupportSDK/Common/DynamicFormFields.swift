import SwiftUI
import UIKit
import Combine

import SwiftUI
import Combine

struct TextFieldView: View {
    var label : String
    var placeholder: String?
    @Binding var text: String
    var index : Int
    var isRequired: Bool
    var validation: ((Int, String) -> Bool)? = nil
    let onTap: (() -> Void)?
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var isFocused: Bool = false
    
    
    var body: some View {
        if(DeviceType.isPhone){
            VStack(alignment: .leading) {
                TextField("", text: $text, onEditingChanged: { isEditing in
                    isFocused = isEditing
                })
                .disabled(isDisabled)
                .textFieldStyle(CustomTextFieldMobileStyle(
                    label: label,
                    placeholder: placeholder ?? ResourceManager.localized("enterTextHere", comment: ""),
                    keyboardType: .default,
                    textIsNotEmpty: !text.isEmpty,
                    isEditing: isFocused,
                    isRequired: isRequired,
                    isValid: isValid,
                    isDisabled: isDisabled
                ))
                .id(index)
                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                
                .foregroundColor(Color.textPrimaryColor)
                .keyboardType(.default)
                .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                .padding(.horizontal, 12)
                .onChange(of: text) { newValue in
                    _ = validation?(index, newValue)
                }
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.horizontal, 20)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.xsmall, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                        .padding(.horizontal, 12)
                }
            }.padding(.bottom, 16)
        }
        else{
            VStack(alignment: .leading) {
                TextField("", text: $text, onEditingChanged: { isEditing in
                    isFocused = isEditing
                })
                .disabled(isDisabled)
                .textFieldStyle(CustomTextFieldTabletStyle(
                    placeholder: placeholder ?? ResourceManager.localized("enterTextHere", comment: ""),
                    keyboardType: .default,
                    textIsNotEmpty: !text.isEmpty,
                    isEditing: isFocused,
                    isRequired: isRequired,
                    label: label,
                    isValid: isValid
                ))
                .id(index)
                .padding(.horizontal, 20)
                .onChange(of: text) { newValue in
                   _ = validation?(index, newValue)
                }
                .onTapGesture {
                    onTap?()
                }
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.horizontal, 20)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                        .padding(.horizontal, 20)
                }
            }.padding(.bottom, 14)
        }
    }
}

struct NumericFieldView: View {
    var label : String
    var placeholder: String?
    @Binding var text: String
    var index : Int
    var isRequired: Bool
    var validation: ((Int, String) -> Bool)? = nil
    let onTap: (() -> Void)?
    let updateEnteredText: ((Int, String) -> Void)
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var isFocused: Bool = false

    var body: some View {
        if(DeviceType.isPhone){
            VStack(alignment: .leading){
                TextField("", text: $text, onEditingChanged: { isEditing in
                    isFocused = isEditing})
                .disabled(isDisabled)
                .textFieldStyle(CustomTextFieldMobileStyle(
                    label: label,
                    placeholder: placeholder ?? ResourceManager.localized("enterTextHere", comment: ""),
                    keyboardType: .numberPad,
                    textIsNotEmpty: !text.isEmpty,
                    isEditing: isFocused,
                    isRequired: isRequired,
                    isValid: isValid,
                    isDisabled: isDisabled
                ))
                .id(index)
                .keyboardType(.numberPad)
                .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                .padding(.horizontal, 12)
                .onChange(of: text) { newValue in
                    _ = validation?(index, newValue)
                }
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.horizontal, 20)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                        .padding(.horizontal, 20)
                }
            }.padding(.bottom, 16)
        }else{
            VStack(alignment: .leading){
                TextField("", text: $text, onEditingChanged: { isEditing in
                    isFocused = isEditing})
                .disabled(isDisabled)
                .textFieldStyle(CustomTextFieldTabletStyle(
                    placeholder: placeholder ?? ResourceManager.localized("enterTextHere", comment: ""),
                    keyboardType: .numberPad,
                    textIsNotEmpty: !text.isEmpty,
                    isEditing: isFocused,
                    isRequired: isRequired,
                    label: label,
                    isValid: isValid
                ))
                .id(index)
                .keyboardType(.numberPad)
                .padding(.horizontal, 20)
                .onChange(of: text) { newValue in
                     _ = validation?(index, newValue)
                }
                .onTapGesture {
                    onTap?()
                }
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.horizontal, 20)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                        .padding(.horizontal, 20)
                }
            }.padding(.bottom, 14)
        }
    }
}

struct DecimalFieldView: View {
    var label : String
    var placeholder: String?
    @Binding var text: String
    var index : Int
    var isRequired: Bool
    var validation: ((Int, String) -> Bool)?  = nil
    let onTap: (() -> Void)?
    let updateEnteredText: ((Int, String) -> Void)
    var noteMessage: String?
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var isFocused: Bool = false
    
    var body: some View {
        if(DeviceType.isPhone){
            VStack(alignment:.leading){
                TextField("", text: $text, onEditingChanged: { isEditing in
                    isFocused = isEditing })
                .disabled(isDisabled)
                .textFieldStyle(CustomTextFieldMobileStyle(
                    label: label,
                    placeholder: placeholder ?? ResourceManager.localized("enterTextHere", comment: ""),
                    keyboardType: .decimalPad,
                    textIsNotEmpty: !text.isEmpty,
                    isEditing: isFocused,
                    isRequired: isRequired,
                    isValid: isValid,
                    isDisabled: isDisabled
                ))
                .id(index)
                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                
                .foregroundColor(Color.textPrimaryColor)
                .keyboardType(.decimalPad)
                .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                .padding(.horizontal, 12)
                .onChange(of: text) { newValue in
                    _ = validation?(index, newValue)
                }
                .onTapGesture {
                    onTap?()
                }
                .onChange(of: isFocused) { newFocus in
                    // Check if focus left this field
                    if !newFocus {
                        // Try to convert to decimal format
                        if let number = Double(text), !isDecimal(text) {
                            text = String(format: "%.2f", number)
                        }
                    }
                }
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.horizontal, 20)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                        .padding(.horizontal, 20)
                }
                
            }.padding(.bottom, 16)
        }else{
            VStack(alignment: .leading){
                TextField("", text: $text, onEditingChanged: { isEditing in
                    isFocused = isEditing })
                .disabled(isDisabled)
                .textFieldStyle(CustomTextFieldTabletStyle(
                    placeholder: placeholder ?? ResourceManager.localized("enterTextHere", comment: ""),
                    keyboardType: .decimalPad,
                    textIsNotEmpty: !text.isEmpty,
                    isEditing: isFocused,
                    isRequired: isRequired,
                    label: label,
                    isValid: isValid
                ))
                .id(index)
                .keyboardType(.decimalPad)
                .padding(.horizontal, 20)
                .onChange(of: text) { newValue in
                    _ = validation?(index, newValue)
                }
                .onChange(of: isFocused) { newFocus in
                    // Check if focus left this field
                    if !newFocus {
                        // Try to convert to decimal format
                        if let number = Double(text), !isDecimal(text) {
                            text = String(format: "%.2f", number)
                        }
                    }
                }
                .onTapGesture {
                    onTap?()
                }
                
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                        .padding(.horizontal, 20)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                        .padding(.horizontal, 20)
                }
                
            }.padding(.bottom, 14)
        }
    }
    
    func formatDecimal(input: String) -> String {
        let components = input.components(separatedBy: ".")
        
        // Limit before decimal
        var beforeDecimal = components.first ?? ""
        beforeDecimal = String(beforeDecimal.prefix(16))
        
        // Limit after decimal (if any)
        if components.count > 1 {
            var afterDecimal = components[1]
            afterDecimal = String(afterDecimal.prefix(2))
            return "\(beforeDecimal).\(afterDecimal)"
        }
        
        return beforeDecimal
    }
    
    func isDecimal(_ input: String) -> Bool {
        let regex = "^[0-9]+\\.[0-9]+$"
        let predicate = NSPredicate(format: "SELF MATCHES %@", regex)
        return predicate.evaluate(with: input)
    }
}

struct RadioButtonsView: View {
    var label:String
    var selectedOption: Bool
    var options : [String]
    var index: Int
    var isRequired: Bool
    var validation: ((Int, Bool) -> Bool)? = nil
    var infoButtonVisible: Bool
    var updateSelectedRadioButton: ((Int,Bool) -> Void)
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false

    var body: some View {
        VStack(alignment: .leading) {
            (Text(label) + (isRequired ? Text(" *").foregroundColor(.textErrorPrimary) : Text("")))
                .font(DeviceType.isPhone ? FontFamily.customFont(size: FontSize.medium, weight: .regular) : FontFamily.customFont(size: FontSize.large, weight: .medium))
                //.fontWeight(DeviceType.isPhone ? .regular : .medium)
                .foregroundColor(DeviceType.isPhone ? .textPlaceHolderColor: .textPrimaryColor)
                .padding(.bottom, 8)
            HStack() {
                radioButton(option: options[0], isSelected: selectedOption, infoButtonVisible: infoButtonVisible)
                radioButton(option: options[1],  isSelected: !selectedOption, infoButtonVisible: infoButtonVisible)
            }.frame(maxWidth: .infinity, alignment: .leading)
                .onChange(of: selectedOption) { newValue in
                   _ = validation?(index, newValue)
                }
            if let note = noteMessage, !note.isEmpty {
                Text(note)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textSecondaryColor)
            }
            if let error = errorMessage, !error.isEmpty, !isValid {
                Text(error)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textErrorPrimary)
            }
        }.disabled(isDisabled)
        .padding(.bottom , 16)
            .padding(.horizontal ,DeviceType.isPhone ? 12 : 20)
    }
    
    @ViewBuilder
    private func radioButton(option: String, isSelected: Bool, infoButtonVisible: Bool = false) -> some View {
        HStack() {
            Circle()
                .stroke(isSelected ? Color.accentColor : .buttonSecondaryBorderColor, lineWidth: 2)
                .frame(width: 20, height: 20)
                .overlay(
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 10, height: 10)
                        .opacity(isSelected ? 1 : 0)
                )
                .onTapGesture {
                    updateSelectedRadioButton(index, selectedOption)
                }
            Text(option)
                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                
                .foregroundColor(.textPrimaryColor)
                .onTapGesture {
                    updateSelectedRadioButton(index, selectedOption)
                }
            if(infoButtonVisible){
                infoButton()
            }
        }
    }
    
    private func infoButton() -> some View {
        AppIcon(icon: .info, size: 14, color: Color.isDarkColor() ? .backgroundPrimary : .textSecondaryColor)
    }
}

struct CheckboxWithLabel: View {
    let title: String
    let showInfoButton: Bool
    var isChecked: Bool
    var index: Int
    var isRequired: Bool
    var updateCheckBox: ((Int,Bool) -> Void)
    var onInfoTap: (() -> Void)? = nil
    var validation: ((Int, Bool) -> Bool)?  = nil
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                HStack (alignment: .top){
                    FormCheckBox(isChecked: isChecked)
                        .padding(.trailing, 4)
                    (
                        Text(title)
                            .foregroundColor(.textPrimaryColor)
                        +
                        (isRequired ? Text(" *").foregroundColor(.textErrorPrimary) : Text(""))
                    )
                    .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                    
                }.onTapGesture {
                    updateCheckBox(index ,isChecked)
                }
                .onChange(of: isChecked) { newValue in
                   _ = validation?(index, newValue)
                }
                if showInfoButton {
                    Button(action: {
                        onInfoTap?()
                    }) {
                        AppIcon(icon: .info, size: 14, color: Color.isDarkColor() ? .backgroundPrimary : .textSecondaryColor)
                    }
                }
                
                Spacer()
            }
            if let note = noteMessage, !note.isEmpty {
                Text(note)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textSecondaryColor)
            }
            if let error = errorMessage, !error.isEmpty, !isValid {
                Text(error)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textErrorPrimary)
            }
        }
        .disabled(isDisabled)
        .padding(.horizontal,DeviceType.isPhone ? 12 : 20)
        .padding(.bottom, DeviceType.isPhone ? 16 : 14)
    }
}

struct SingleSelectDropdownView : View {
    var title: String
    var placeholder: String?
    var isRequired: Bool
    var index : Int
    var updateSelectedItem: (Int, DropdownItemModel?) -> Void
    var validation: ((Int, DropdownItemModel?) -> Bool)? = nil
    var selectedItem: DropdownItemModel?
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var onTap: (() -> Void)? = nil
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isDisabled: Bool = false
    var isValid: Bool = true
    var hideResetButton: Bool = false
    
    var body: some View{
        if DeviceType.isPhone {
            SingleSelectDropdownField(
                title: title,
                placeholder: placeholder ?? ResourceManager.localized("selectText", comment: ""),
                isRequired: isRequired,
                index: index,
                updateSelectedItem: updateSelectedItem,
                validation: validation,
                selectedItem: selectedItem,
                fetchItems: fetchItems,
                noteMessage: noteMessage,
                errorMessage: errorMessage,
                isValid: isValid,
                isDisabled: isDisabled,
                hideResetButton: hideResetButton
            )
        }
        else{
            AutoCompleteSingleSelectDropdown(
                label: title,
                placeholder: placeholder ?? ResourceManager.localized("selectText", comment: ""),
                isRequired: isRequired,
                index: index,
                updateSelectedItem: updateSelectedItem,
                validation: validation,
                selectedItem: selectedItem,
                fetchItems: fetchItems,
                onTap: onTap,
                noteMessage: noteMessage,
                errorMessage: errorMessage,
                isValid: isValid,
                isDisabled: isDisabled,
                closeButtonNotVisible: hideResetButton
            )
        }
        
    }
}

struct MultiSelectDropdownView : View {
    var title: String
    var placeholder: String?
    var isRequired: Bool
    var index : Int
    var updateSelectedItem: (Int, [DropdownItemModel]) -> Void
    var validation: ((Int, [DropdownItemModel]) -> Bool)? = nil
    var selectedItem: [DropdownItemModel]
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var onTap: (() -> Void)? = nil
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    var hideResetButton: Bool = false
    
    var body: some View{
        if DeviceType.isPhone {
            MultiSelectDropdownField(
                title: title,
                placeholder: placeholder ?? ResourceManager.localized("selectText", comment: ""),
                isRequired: isRequired,
                index: index,
                updateSelectedItem: updateSelectedItem,
                validation: validation,
                selectedItems: selectedItem,
                fetchItems: fetchItems,
                noteMessage: noteMessage,
                errorMessage: errorMessage,
                isValid: isValid,
                isDisabled: isDisabled
            )
        }
        else{
            AutoCompleteMultiSelectDropdown(
                label: title,
                placeholder: placeholder ?? ResourceManager.localized("selectText", comment: ""),
                isRequired: isRequired,
                index: index,
                updateSelectedItem: updateSelectedItem,
                validation: validation,
                selectedItems: selectedItem,
                fetchItems: fetchItems,
                onTap: onTap,
                noteMessage: noteMessage,
                errorMessage: errorMessage,
                isValid: isValid,
                isDisabled: isDisabled,
                closeButtonNotVisible: hideResetButton
            )
        }
        
    }
}
