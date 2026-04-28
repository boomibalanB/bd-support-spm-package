//
//  CustomTextFieldStyle.swift
//  CustomTextField
//
//  Created by Abdelrahman Talaat on 12/01/2023.
//

import SwiftUI

struct CustomTextFieldMobileStyle: TextFieldStyle {
    let label : String
    let placeholder: String
    let keyboardType: UIKeyboardType
    var textIsNotEmpty : Bool
    var isEditing: Bool
    var isRequired: Bool
    var isValid: Bool = true
    var isDisabled: Bool = false
    
    func _body(configuration: TextField<_Label>) -> some View {
        ZStack (alignment: .leading) {
            (Text(label) + (isRequired ? Text(" *")
                .foregroundColor(.textErrorPrimary)
                .font(FontFamily.customFont(size:  self.isEditing || textIsNotEmpty ? FontSize.xsmall : FontSize.large , weight: .regular))
                
                : Text("")))
                .foregroundColor(Color.textPlaceHolderColor)
                .font(FontFamily.customFont(size: self.isEditing || textIsNotEmpty ? FontSize.xsmall : FontSize.large, weight: .regular))
                
                .padding(.horizontal,  self.isEditing || textIsNotEmpty ? 2 : 0)
                .padding(.bottom,  self.isEditing || textIsNotEmpty ? 2 : 0)
                .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                .offset(y: self.isEditing || textIsNotEmpty ? -28 : 0)
                .scaleEffect(self.isEditing || textIsNotEmpty ? 0.9 : 1, anchor: .leading)
            if !textIsNotEmpty && isEditing {
                Text(placeholder)
                    .foregroundColor(Color.textPlaceHolderColor)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                    
            }
            configuration
                .font(FontFamily.customFont(size: FontSize.large, weight: .regular)) // ✅ Apply font here
                
                .foregroundColor(.textPrimaryColor)
        }
        .animation(.easeOut, value:  isEditing || textIsNotEmpty)
        .keyboardType(keyboardType)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .stroke(!isValid
                        ? Color.textErrorPrimary
                        : (isEditing ? .accentColor : .borderSecondaryColor), lineWidth: 1)
        )
    }
}


struct CustomTextFieldTabletStyle: TextFieldStyle {
    let placeholder: String
    let keyboardType: UIKeyboardType
    var textIsNotEmpty: Bool
    var isEditing: Bool
    var isRequired: Bool
    var label : String
    var isValid: Bool = true
    
    func _body(configuration: TextField<_Label>) -> some View {
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
            }
            .padding(.bottom, 10)
            
            ZStack(alignment: .leading) {
                if !textIsNotEmpty {
                    Text(placeholder)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        
                        .foregroundColor(.textSecondaryPlaceHolderColor)
                }

                configuration
                    .font(FontFamily.customFont(size: FontSize.large, weight: .regular)) // ✅ Apply font here
                    
                    .foregroundColor(.textPrimaryColor)
            }
            
            Rectangle()
                .frame(height: 1)
                .foregroundColor(!isValid
                                  ? Color.textErrorPrimary
                                 : (isEditing ? Color.accentColor : .borderSecondaryColor))
                .padding(.top,10)
        }
        .keyboardType(keyboardType)
    }
}

