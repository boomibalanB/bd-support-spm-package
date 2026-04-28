import SwiftUI

final class AttachmentOptionsProvider {
    
    static func attachmentOptionsView(
        attachmentName: String,
        isPresented: Binding<Bool>,
        onDownload: @escaping () -> Void,
        onDelete: @escaping () -> Void,
        dismiss: (() -> Void)? = nil
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            BottomSliderTitle(titleText: attachmentName)
            
            // Download option
            Button {
                onDownload()
                isPresented.wrappedValue = false
                dismiss?()
            } label: {
                HStack(spacing: 12) {
                    AppIcon(icon: .download, size: 22, color: .textQuarteraryColor)
                    Text(ResourceManager.localized("downloadText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                        .foregroundColor(.textSecondaryColor)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            
            // Delete option
            Button {
                onDelete()
                isPresented.wrappedValue = false
                dismiss?()
            } label: {
                HStack(spacing: 12) {
                    AppIcon(icon: .delete, size: 22, color: .textQuarteraryColor)
                    Text(ResourceManager.localized("deleteText", comment: ""))
                        .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                        .foregroundColor(.textSecondaryColor)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
        }
    }
    
    
    @ViewBuilder
    static func deleteAttachmentDialog(
        attachmentName: String,
        isPresented: Binding<Bool>,
        onDeleteConfirm: @escaping () -> Void
    ) -> some View {
        
        let truncatedName: String = {
            if attachmentName.count > 100 {
                let index = attachmentName.index(attachmentName.startIndex, offsetBy: 100)
                return String(attachmentName[..<index]) + "..."
            }
            return attachmentName
        }()
        Group {
            if isPresented.wrappedValue {
                ConfirmationDialog(
                    title: ResourceManager.localized("deleteFileTitleText"),
                    message: String(format: ResourceManager.localized("deleteFileConfirmationText"), truncatedName),
                    confirmButtonText: ResourceManager.localized("deleteDescriptionConfirm"),
                    cancelButtonText: ResourceManager.localized("cancelText"),
                    onConfirm: {
                        onDeleteConfirm()
                        isPresented.wrappedValue = false
                    },
                    onCancel: {
                        isPresented.wrappedValue = false
                    },
                    icon: .delete1,
                    isRed: true
                )
                .zIndex(1)
            }
        }
    }
}
