import SwiftUI
import UIKit

struct FloatingLabelDateField: View {
    var label: String
    var placeholder: String?
    var selectedDate: String?
    var index : Int
    var isRequired: Bool
    var updateSelectedDate : ((Int, String?) -> Void)
    var validation: ((Int, String?) -> Bool)? = nil
    let onTap: (() -> Void)?
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var isFocused: Bool = false
    
    var body: some View {
        if(DeviceType.isPhone){
            VStack(alignment: .leading){
                ZStack(alignment: .leading) {
                    if isFocused || selectedDate != nil {
                        (Text(label) + (isRequired ? Text(" *")
                            .foregroundColor(.textErrorPrimary)
                                        
                            .font(FontFamily.customFont(size: FontSize.xsmall, weight: .regular)) :
                                            Text("")))
                        .foregroundColor(Color.textPlaceHolderColor)
                        .padding(.horizontal, selectedDate != nil ? 2 : 0)
                        .padding(.bottom, selectedDate != nil ? 2 : 0)
                        .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        
                        .offset(y:selectedDate != nil || isFocused ? -32 : 0)
                        .scaleEffect(selectedDate != nil || isFocused ? 0.8 : 1.0, anchor: .leading)
                        .animation(.easeOut(duration: 0.2), value:selectedDate != nil || isFocused)
                    }
                    if(selectedDate == nil){
                        (Text(isFocused ? placeholder ?? ResourceManager.localized("selectDateText", comment: "") : label) + (!isFocused && isRequired ? Text(" *")
                            .foregroundColor(.textErrorPrimary)
                                                                                                                              
                            .font(FontFamily.customFont(size: FontSize.large, weight: .regular)) : Text("")))
                        .foregroundColor(Color.textPlaceHolderColor)
                        .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        
                    }
                    
                    HStack{
                        DateFieldUIKit(
                            selectedDate: selectedDate != nil && selectedDate!.isEmpty ? "--" : selectedDate,
                            isFocused: $isFocused,
                            index: index,
                            updateSelectedDate: updateSelectedDate
                        )
                        .disabled(isDisabled)
                        .onChange(of: selectedDate) { newValue in
                            _ = validation?(index, newValue)
                        }
                        Spacer()
                        if selectedDate != nil && !isDisabled {
                            Button(action: {
                                updateSelectedDate(index, nil)
                            }) {
                                AppIcon(icon: AppIcons.close)
                            }
                        }
                    }
                    
                }
                .id(index)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke((errorMessage?.isEmpty == false)
                                ? Color.textErrorPrimary
                                : (isFocused ? .accentColor : .borderSecondaryColor), lineWidth: 1)
                )
                .animation(.easeOut(duration: 0.2), value:selectedDate != nil || isFocused)
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
            }
            .background(isDisabled ? Color.disabledColor : Color.backgroundPrimary)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        } else{
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
                
                ZStack(alignment: .leading){
                    if(selectedDate == nil){
                        Text(placeholder ?? ResourceManager.localized("selectDateText", comment: "") )
                            .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                        
                            .foregroundColor(.textSecondaryPlaceHolderColor)
                        
                    }
                    HStack{
                        DateFieldUIKit(
                            selectedDate: selectedDate != nil && selectedDate!.isEmpty ? "--" : selectedDate,
                            isFocused: $isFocused,
                            index : index,
                            updateSelectedDate: updateSelectedDate
                        )
                        .disabled(isDisabled)
                        .onChange(of: selectedDate) { newValue in
                            _ = validation?(index, newValue)
                        }
                        .onTapGesture {
                            onTap?()
                        }
                        .padding(.top, -3)
                        Spacer()
                        if selectedDate != nil && !isDisabled {
                            Button(action: {
                                updateSelectedDate(index, nil)
                            }) {
                                AppIcon(icon: AppIcons.close)
                            }
                            .padding(.trailing, 22)
                        }
                    }
                }
                
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor((errorMessage?.isEmpty == false)
                                     ? Color.textErrorPrimary
                                     : (isFocused ? .accentColor : .borderSecondaryColor))
                    .padding(.top,10)
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
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            .id(index)
        }
    }
}

// UIKit DateField inside SwiftUI
struct DateFieldUIKit: UIViewRepresentable {
    var selectedDate: String?
    @Binding var isFocused: Bool
    var isDatePicker: Bool = true
    var index: Int
    var updateSelectedDate: ((Int, String?) -> Void)
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField()
        textField.delegate = context.coordinator
        textField.tintColor = .clear
        textField.font = FontFamily.customUIFont(size: FontSize.large, weight: .regular)
        
        context.coordinator.setup(textField: textField)
        
        return textField
    }
    
    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = selectedDate
        
        if let dateStr = selectedDate, let date = dateStr.toDate() {
            context.coordinator.datePicker.date = date
        }
    }
    
    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: DateFieldUIKit
        let datePicker = UIDatePicker()
        weak var textField: UITextField?
        
        init(_ parent: DateFieldUIKit) {
            self.parent = parent
            super.init()
        }
        
        func setup(textField: UITextField) {
            self.textField = textField
            if #available(iOS 13.4, *) {
                datePicker.preferredDatePickerStyle = .wheels
            }
            datePicker.datePickerMode = .date
            if let date = parent.selectedDate?.toDate() {
                datePicker.date = date
            }
            else{
                datePicker.date = Date()
            }
            
            textField.inputView = datePicker
            textField.inputAccessoryView = makeToolbar()
            textField.addTarget(self, action: #selector(textFieldEditingDidBegin), for: .editingDidBegin)
            textField.addTarget(self, action: #selector(textFieldEditingDidEnd), for: .editingDidEnd)
        }
        
        func makeToolbar() -> UIToolbar {
            let toolbar = UIToolbar()
            toolbar.sizeToFit()
            let clear = UIBarButtonItem(title: "Clear", style: .plain, target: self, action: #selector(clearTapped))
            clear.tintColor = UIColor(Color.accentColor)
            let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
            let done = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(doneTapped))
            done.tintColor = UIColor(Color.accentColor)
            toolbar.items = [clear, spacer, done]
            return toolbar
        }
        
        @objc func clearTapped() {
            parent.updateSelectedDate(parent.index, nil)
            UIApplication.shared.endEditing()
        }
        
        @objc func doneTapped() {
            updateText(with: datePicker.date)
            UIApplication.shared.endEditing()
        }
        
        func updateText(with date: Date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            let formattedDate = formatter.string(from: date)
            parent.updateSelectedDate(parent.index, formattedDate)
        }
        
        @objc func textFieldEditingDidBegin() {
            parent.isFocused = true
        }
        
        @objc func textFieldEditingDidEnd() {
            parent.isFocused = false
        }
    }
}

// Helper to convert String to Date
extension String {
    func toDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: self)
    }
}




