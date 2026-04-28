import SwiftUI

struct CustomTextEditor: View {
    var label : String
    var placeholder: String?
    @Binding var text: String
    var index : Int
    var isRequired: Bool
    var requiredFieldValidation: ((String) -> String?)?
    var validations: ((Int, String) -> Bool)?  = nil
    let onTap: (() -> Void)?
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var isFocused: Bool = false
    
    var body: some View {
        if DeviceType.isPhone{
            VStack(alignment: .leading) {
                ZStack(alignment: .topLeading) {
                    (Text(label) + (isRequired ? Text(" *")
                        .foregroundColor(.textErrorPrimary)
                        
                        .font(FontFamily.customFont(size: isFocused || !text.isEmpty ?  FontSize.xsmall : FontSize.large , weight: .regular)) : Text("")))
                        
                        .font(FontFamily.customFont(size: isFocused || !text.isEmpty ? FontSize.xsmall : FontSize.large, weight: .regular))
                        .foregroundColor(Color.textPlaceHolderColor)
                        .padding(.horizontal, (isFocused || !text.isEmpty) ? 2 : 0)
                        .padding(.bottom, (isFocused || !text.isEmpty) ? 2 : 0)
                        .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                        .offset(x: (isFocused || !text.isEmpty) ? 4 : 0, y: (isFocused || !text.isEmpty) ? -20 : 0)
                        .scaleEffect((isFocused || !text.isEmpty) ? 0.9 : 1, anchor: .leading)
                    if text.isEmpty && isFocused {
                        Text(placeholder ?? ResourceManager.localized("enterTextHere", comment: ""))
                            .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                            
                            .foregroundColor(Color.textPlaceHolderColor)
                            .padding(.top, 6)
                            .padding(.leading, 3)
                    }
                    // Use UITextViewWrapper directly
                    UITextViewWrapper(
                        text: $text,
                        isFocused: $isFocused,
                        onFocusChange:{ focused in
                            if focused {
                                onTap?()
                            }
                        }
                    )
                    .disabled(isDisabled)
                }
                .id(index)
                .animation(.easeOut, value: isFocused || !text.isEmpty)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: text) { newValue in
                    _ = validations?(index, newValue)
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(!isValid
                                ? Color.textErrorPrimary
                                : (isFocused ? .accentColor : .borderSecondaryColor), lineWidth: 1)
                )
                
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                }
            }
            //            .onAppear(){
            //                focusedFieldID = index
            //            }
            .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
            .frame(height: 200)
        }else{
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
                } .id(index)
                    .padding(.bottom, 10)
                
                ZStack(alignment: .topLeading){
                    if(text.isEmpty){
                        Text(placeholder ?? ResourceManager.localized("enterTextHere", comment: ""))
                            .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                            
                            .foregroundColor(.textSecondaryPlaceHolderColor)
                        
                    }
                    UITextViewWrapper(
                        text: $text,
                        isFocused: $isFocused,
                        onFocusChange:{ focused in
                            if focused {
                                onTap?()
                            }
                        }
                    )
                    .disabled(isDisabled)
                    .onChange(of: text) { newValue in
                        _ = validations?(index, newValue)
                    }
                    .padding(.top, -8)
                    .padding(.leading, -4)
                }
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(!isValid
                                     ? Color.textErrorPrimary
                                     : (isFocused ? .accentColor : .borderSecondaryColor))
                    .padding(.top,10)
                if let note = noteMessage, !note.isEmpty {
                    Text(note)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textSecondaryColor)
                }
                if let error = errorMessage, !error.isEmpty {
                    Text(error)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .foregroundColor(.textErrorPrimary)
                }
            }
            //            .onAppear(){
            //                focusedFieldID = index
            //            }
            .padding(.horizontal, 20)
            .frame(height: 200)
            .padding(.bottom, 14)
            
        }
    }
}

struct UITextViewWrapper: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    
    var onFocusChange: ((Bool) -> Void)? = nil
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.font = FontFamily.customUIFont(size: FontSize.large, weight: .regular)
        textView.textColor = UIColor(Color.textPrimaryColor)
        textView.text = text
        
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: context.coordinator,
            action: #selector(context.coordinator.dismissKeyboard)
        )
        doneButton.tintColor = UIColor(Color.accentColor) // 👈 Set the color here
        
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        toolbar.setItems([
            UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil),
            doneButton
        ], animated: false)
        
        textView.inputAccessoryView = toolbar
        
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        // Avoid directly modifying `text` or `isFocused` during view update
        DispatchQueue.main.async {
            if uiView.text != text {
                uiView.text = text
            }
            
            if isFocused && !uiView.isFirstResponder {
                uiView.becomeFirstResponder()
            } else if !isFocused && uiView.isFirstResponder {
                uiView.resignFirstResponder()
            }
        }
    }
    
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: UITextViewWrapper
        
        init(_ parent: UITextViewWrapper) {
            self.parent = parent
        }
        
        @objc func dismissKeyboard() {
            parent.isFocused = false
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            parent.isFocused = true
            parent.onFocusChange?(true)
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            parent.isFocused = false
            parent.onFocusChange?(false)
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
        }
    }
}
