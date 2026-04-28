import SwiftUI
import UIKit

struct MultilineTextEditor: UIViewRepresentable {
    @Binding var text: String
    @Binding var isFocused: Bool
    var font: UIFont
    var lineHeight: CGFloat? = nil
    var isEditable: Bool = true
    var autoFocus: Bool = false
    var restrictNewLine: Bool = false
    var onChange: ((String) -> Void)? = nil
    var onFocusIn: (() -> Void)? = nil
    var onFocusOut: (() -> Void)? = nil
    var textColor: UIColor = UIColor(Color.textPrimary)
    
    func makeCoordinator() -> Coordinator { Coordinator(self) }
    
    func makeUIView(context: Context) -> UITextView {
        let tv = UITextView()
        tv.delegate = context.coordinator
        tv.isEditable = isEditable
        tv.backgroundColor = .clear
        tv.isScrollEnabled = true
        tv.alwaysBounceVertical = true
        tv.textContainer.lineFragmentPadding = 0
        tv.textContainerInset = .zero
        tv.adjustsFontForContentSizeCategory = true
        applyAttributes(to: tv, text: text)
        return tv
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        if (autoFocus || isFocused),
           !uiView.isFirstResponder,
           !context.coordinator.didAutofocus {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
                context.coordinator.didAutofocus = true
            }
        }
        
        uiView.isEditable = isEditable
        
        if isFocused, !uiView.isFirstResponder {
            uiView.becomeFirstResponder()
        } else if !isFocused, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
        
        if uiView.text != text || context.coordinator.needsRestyle(font: font, lineHeight: lineHeight) {
            let selected = uiView.selectedRange
            applyAttributes(to: uiView, text: text)
            uiView.selectedRange = NSRange(
                location: min(selected.location, (uiView.text as NSString).length),
                length: min(selected.length, max(0, (uiView.text as NSString).length - selected.location))
            )
        }
        
        context.coordinator.lastFont = font
        context.coordinator.lastLineHeight = lineHeight
    }
    
    private func attributedString(for text: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        if let lh = lineHeight, lh > 0 {
            paragraph.minimumLineHeight = lh
            paragraph.maximumLineHeight = lh
        }
        
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor,
            .paragraphStyle: paragraph
        ]
        
        if let lh = lineHeight, lh > 0 {
            let delta = lh - font.lineHeight
            attrs[.baselineOffset] = delta > 0 ? delta / 2 : 0
        }
        
        return NSAttributedString(string: text, attributes: attrs)
    }
    
    private func applyAttributes(to textView: UITextView, text: String) {
        let attr = attributedString(for: text)
        textView.attributedText = attr
        
        // Match typing attributes
        var typing = [NSAttributedString.Key: Any]()
        typing[.font] = font
        typing[.foregroundColor] = textColor
        
        // Use a default paragraph style if the attributed string is empty
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        if let lh = lineHeight, lh > 0 {
            paragraph.minimumLineHeight = lh
            paragraph.maximumLineHeight = lh
            let delta = lh - font.lineHeight
            typing[.baselineOffset] = delta > 0 ? delta / 2 : 0
        }
        typing[.paragraphStyle] = paragraph
        
        textView.typingAttributes = typing
    }
    
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: MultilineTextEditor
        var didAutofocus = false
        var lastFont: UIFont
        var lastLineHeight: CGFloat?
        
        init(_ parent: MultilineTextEditor) {
            self.parent = parent
            self.lastFont = parent.font
            self.lastLineHeight = parent.lineHeight
        }
        
        func needsRestyle(font: UIFont, lineHeight: CGFloat?) -> Bool {
            !lastFont.isEqual(font) || lastLineHeight != lineHeight
        }
        
        func textViewDidChange(_ textView: UITextView) {
            parent.text = textView.text
            parent.onChange?(textView.text)
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
                self.parent.onFocusIn?()
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
                self.parent.onFocusOut?()
            }
        }
        
        func textView(_ textView: UITextView,
                      shouldChangeTextIn range: NSRange,
                      replacementText text: String) -> Bool {
            if parent.restrictNewLine && text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        }
    }
}
