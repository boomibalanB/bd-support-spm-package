import SwiftUI
import UIKit

struct CCTextfieldView: View {
    var title: String
    var placeholder: String
    var isRequired: Bool
    var index: Int
    @Binding var selectedItems: [String]
    var noteMessage: String? = nil
    var errorMessage: String? = nil
    var isValid: Bool = true
    var isDisabled: Bool = false
    @State private var text = ""
    @State private var isFocused: Bool = false

    var floatingLabel: Text {
        var label = Text("CC")
        if isRequired {
            label = label + Text(" *").foregroundColor(.textErrorPrimary)
        }
        return label
    }

    var body: some View {
        if DeviceType.isPhone {
            VStack(alignment: .leading, spacing: 0) {
                if !selectedItems.isEmpty {
                    floatingLabel
                        .foregroundColor(Color.textPlaceHolderColor)

                        .font(
                            FontFamily.customFont(
                                size: FontSize.xsmall,
                                weight: .regular
                            )
                        )
                        .background(
                            isDisabled
                                ? Color.disabledColor : Color.backgroundPrimary
                        )
                        .padding(.leading, 12)
                        .padding(.bottom, 4)
                }
                ZStack(alignment: .topTrailing) {
                    // Tags field
                    TagsFieldUIKitRepresentable(
                        tags: $selectedItems,
                        isFocused: $isFocused,
                        placeholder: selectedItems.isEmpty ? "CC" : "",
                        isDisabled: isDisabled
                    )
                    .padding(.leading, 8)
                    .padding(.trailing, 30)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                    // Clear All button
                    if !selectedItems.isEmpty && !isDisabled {
                        Button(action: {
                            selectedItems.removeAll()
                            isFocused = false
                        }) {
                            AppIcon(
                                icon: .close,
                                size: 24,
                                color: Color.iconBackgroundColor
                            )
                        }
                        .padding(.top, 12)
                        .padding(.trailing, 10)
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            (errorMessage?.isEmpty == false)
                                ? Color.textErrorPrimary
                                : (isFocused
                                    ? .accentColor : .borderSecondaryColor),
                            lineWidth: 1
                        )
                )
                .background(
                    isDisabled
                        ? Color.disabledColor : Color.backgroundPrimary
                )

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
            .disabled(isDisabled)
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        } else {
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text(title)
                        .font(
                            FontFamily.customFont(
                                size: FontSize.large,
                                weight: .medium
                            )
                        )
                        .foregroundColor(.textPrimaryColor)

                    if isRequired {
                        Text(" *")
                            .font(
                                FontFamily.customFont(
                                    size: FontSize.medium,
                                    weight: .bold
                                )
                            )
                            .foregroundColor(.textErrorPrimary)
                    }
                }

                ZStack(alignment: .topTrailing) {
                    TagsFieldUIKitRepresentable(
                        tags: $selectedItems,
                        isFocused: $isFocused,
                        placeholder: selectedItems.isEmpty
                            ? ResourceManager.localized("enterEmailText") : "",
                        isDisabled: isDisabled
                    )
                    .padding(.trailing, 50)

                    // Clear All button
                    if !selectedItems.isEmpty && !isDisabled {
                        Button(action: {
                            selectedItems.removeAll()
                            isFocused = false
                        }) {
                            AppIcon(
                                icon: .close,
                                size: 20,
                                color: Color.iconBackgroundColor
                            )
                        }
                        .padding(.top, 8)
                        .padding(.trailing, 20)
                    }
                }

                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(
                        (errorMessage?.isEmpty == false)
                            ? Color.textErrorPrimary
                            : (isFocused ? .accentColor : .borderSecondaryColor)
                    )

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
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            .id(index)
            .disabled(isDisabled)
        }
    }
}

// MARK: - SwiftUI Wrapper
struct TagsFieldUIKitRepresentable: UIViewRepresentable {
    @Binding var tags: [String]
    @Binding var isFocused: Bool

    var placeholder: String = "CC"
    var isDisabled: Bool = false

    func makeUIView(context: Context) -> CustomTagsField {
        let tagsField = CustomTagsField()
        tagsField.placeholder = placeholder
        tagsField.isDisabled = isDisabled
        tagsField.delegate = context.coordinator
        return tagsField
    }

    func updateUIView(_ uiView: CustomTagsField, context: Context) {
        if uiView.tags != tags {
            uiView.tags.forEach { uiView.removeTag($0) }
            tags.forEach { uiView.addTag($0) }
        }
        uiView.isDisabled = isDisabled
        uiView.placeholder = placeholder
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, CustomTagsFieldDelegate {
        var parent: TagsFieldUIKitRepresentable

        init(_ parent: TagsFieldUIKitRepresentable) {
            self.parent = parent
        }

        func tagsFieldDidChange(_ tagsField: CustomTagsField, tags: [String]) {
            DispatchQueue.main.async {
                self.parent.tags = tags
            }
        }

        func tagsFieldDidBeginEditing(_ tagsField: CustomTagsField) {
            DispatchQueue.main.async {
                self.parent.isFocused = true
            }
        }

        func tagsFieldDidEndEditing(_ tagsField: CustomTagsField) {
            DispatchQueue.main.async {
                self.parent.isFocused = false
            }
        }
    }
}

// MARK: - Delegate Protocol
internal protocol CustomTagsFieldDelegate: AnyObject {
    func tagsFieldDidChange(_ tagsField: CustomTagsField, tags: [String])
    func tagsFieldDidBeginEditing(_ tagsField: CustomTagsField)
    func tagsFieldDidEndEditing(_ tagsField: CustomTagsField)
}

// MARK: - Custom TextField to detect backspace
class BackspaceDetectingTextField: UITextField {
    var onBackspace: (() -> Void)?

    override func deleteBackward() {
        if let text = text, !text.isEmpty {
            // If you want to delete last character instead of tag
            super.deleteBackward()
        } else {
            onBackspace?()  // delete last tag when text field is empty
        }
    }
}

// MARK: - Custom Tags Field
class CustomTagsField: UIView {

    // MARK: - Public Properties
     var placeholder: String = "Enter CC" {
        didSet { textField.placeholder = placeholder }
    }

    var isDisabled: Bool = false {
        didSet {
            textField.isEnabled = !isDisabled
            updateTagColors()
        }
    }

    private(set) var tags: [String] = []
    weak var delegate: CustomTagsFieldDelegate?

    // MARK: - Private Properties
    private let scrollView = UIScrollView()
    private let textField = BackspaceDetectingTextField()
    private var tagButtons: [UIButton] = []

    private let tagSpacing: CGFloat = 8
    private let lineSpacing: CGFloat = 8
    private let tagHeight: CGFloat = 28
    private let textFieldHeight: CGFloat = 28
    private let padding: CGFloat = 4
    private let minTextFieldWidth: CGFloat = 60

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
        ])

        textField.placeholder = placeholder
        textField.borderStyle = .none
        textField.delegate = self
        textField.autocorrectionType = .no
        scrollView.addSubview(textField)
        textField.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .foregroundColor: UIColor(
                    DeviceConfig.isIPhone
                        ? Color.textPlaceHolderColor
                        : Color.textSecondaryPlaceHolderColor
                ),
                .font: FontFamily.customUIFont(
                    size: FontSize.large,
                    weight: .regular
                ),
            ]
        )
        addDoneButtonOnKeyboard()
        // Backspace callback
        textField.onBackspace = { [weak self] in
            self?.handleBackspace()
        }
    }

    private func updateTagColors() {
        for button in tagButtons {
            button.backgroundColor = UIColor(Color.accentColor.opacity(0.2))
            button.setTitleColor(UIColor(Color.textPrimary), for: .normal)
            button.isUserInteractionEnabled = !isDisabled
        }
        textField.isEnabled = !isDisabled
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        layoutTagsAndTextField()
    }

    private func addDoneButtonOnKeyboard() {
        let toolbar = UIToolbar()
        toolbar.sizeToFit()

        let flexSpace = UIBarButtonItem(
            barButtonSystemItem: .flexibleSpace,
            target: nil,
            action: nil
        )
        let doneButton = UIBarButtonItem(
            title: "Done",
            style: .plain,
            target: self,
            action: #selector(doneButtonTapped)
        )
        doneButton.tintColor = UIColor(Color.accentColor)

        toolbar.items = [flexSpace, doneButton]
        textField.inputAccessoryView = toolbar
    }

    @objc private func doneButtonTapped() {
        addTag(textField.text ?? "")
        DispatchQueue.main.async {
            self.textField.text = ""
            self.textField.resignFirstResponder()
            self.delegate?.tagsFieldDidEndEditing(self)
        }
    }

    private func layoutTagsAndTextField() {
        var x = padding
        var y = padding

        // Layout tag buttons
        for button in tagButtons {
            let size = button.intrinsicContentSize
            let buttonWidth = size.width + 16
            if x + buttonWidth + padding > bounds.width {
                x = padding
                y += tagHeight + lineSpacing
            }
            button.frame = CGRect(
                x: x,
                y: y,
                width: buttonWidth,
                height: tagHeight
            )
            x += buttonWidth + tagSpacing
        }

        // Layout text field at the end
        let remainingWidth = bounds.width - x - padding
        var textFieldX = x
        var textFieldY = y
        var textFieldWidth = max(minTextFieldWidth, remainingWidth)

        if remainingWidth < minTextFieldWidth {
            // Wrap to next line
            textFieldX = padding
            textFieldY += tagHeight + lineSpacing
            textFieldWidth = bounds.width - 2 * padding
        }

        textField.frame = CGRect(
            x: textFieldX,
            y: textFieldY,
            width: textFieldWidth,
            height: textFieldHeight
        )

        // Update scrollView content size
        scrollView.contentSize = CGSize(
            width: bounds.width,
            height: textFieldY + textFieldHeight + padding
        )
        invalidateIntrinsicContentSize()
    }

    override var intrinsicContentSize: CGSize {
        var rows: CGFloat = 1
        var x: CGFloat = padding

        for button in tagButtons {
            let width = button.intrinsicContentSize.width + 16
            if x + width + padding > bounds.width {
                rows += 1
                x = padding
            }
            x += width + tagSpacing
        }

        // Check if text field needs a new row
        if x + minTextFieldWidth + padding > bounds.width {
            rows += 1
        }

        return CGSize(
            width: UIView.noIntrinsicMetric,
            height: rows * (tagHeight + lineSpacing) + padding
        )
    }

    // MARK: - Tag Management
    func addTag(_ text: String) {
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let button = UIButton(type: .custom)
        button.setTitle(text, for: .normal)
        button.titleLabel?.font = FontFamily.customUIFont(
            size: FontSize.large,
            weight: .regular
        )
        button.layer.cornerRadius = 12
        button.clipsToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(
            top: 4,
            left: 4,
            bottom: 4,
            right: isDisabled ? 4 : 20
        )
        button.backgroundColor = UIColor(Color.accentColor.opacity(0.2))
        button.tintColor = UIColor(
            DeviceConfig.isIPhone
                ? Color.textPlaceHolderColor
                : Color.textSecondaryPlaceHolderColor
        )

        // Close button
        let closeButton = UIButton(type: .custom)
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.tintColor = UIColor(Color.gray)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.addTarget(
            self,
            action: #selector(tagRemoveTapped(_:)),
            for: .touchUpInside
        )
        button.addSubview(closeButton)
        closeButton.isHidden = isDisabled
        NSLayoutConstraint.activate([
            closeButton.centerYAnchor.constraint(equalTo: button.centerYAnchor),
            closeButton.trailingAnchor.constraint(
                equalTo: button.trailingAnchor,
                constant: -4
            ),
            closeButton.widthAnchor.constraint(equalToConstant: 16),
            closeButton.heightAnchor.constraint(equalToConstant: 16),
        ])

        // Tap to focus text field
        let tapGesture = UITapGestureRecognizer(
            target: self,
            action: #selector(tagTapped(_:))
        )
        button.addGestureRecognizer(tapGesture)

        scrollView.addSubview(button)
        tagButtons.append(button)
        tags.append(text)
        delegate?.tagsFieldDidChange(self, tags: tags)
        textField.text = ""
        setNeedsLayout()
    }

    func removeTag(_ text: String) {
        for (index, button) in tagButtons.enumerated() {
            if button.currentTitle == text {
                button.removeFromSuperview()
                tagButtons.remove(at: index)
                if let tagIndex = tags.firstIndex(of: text) {
                    tags.remove(at: tagIndex)
                }
                break
            }
        }
        delegate?.tagsFieldDidChange(self, tags: tags)
        setNeedsLayout()
    }

    // MARK: - Backspace
    private func handleBackspace() {
        if let lastTag = tags.last {
            removeTag(lastTag)
        }
    }

    @objc private func textFieldDidChange() {
        if let text = textField.text, text.contains(",") {
            let components = text.components(separatedBy: ",").map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            for component in components where !component.isEmpty {
                addTag(component)
            }
            textField.text = ""
        }
    }

    @objc private func tagRemoveTapped(_ sender: UIButton) {
        guard let tagButton = sender.superview as? UIButton,
            let text = tagButton.currentTitle
        else { return }
        removeTag(text)
    }

    @objc private func tagTapped(_ sender: UITapGestureRecognizer) {
        textField.becomeFirstResponder()
    }
}

// MARK: - UITextFieldDelegate
extension CustomTagsField: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        delegate?.tagsFieldDidBeginEditing(self)
    }

    func textFieldDidEndEditing(_ textField: UITextField) {
        delegate?.tagsFieldDidEndEditing(self)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if let text = textField.text, !text.isEmpty {
            addTag(text)
        }
        return true
    }
}
