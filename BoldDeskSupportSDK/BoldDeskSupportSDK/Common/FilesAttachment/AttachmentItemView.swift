import SwiftUI
import Combine
import Foundation

struct AttachmentItemView: View {
    @Binding var selectedAttachment: Attachment?
    let attachment: Attachment
    var canDelete: Bool = true
    var dataToken: String? = nil
    
    var onDelete: (() -> Void)? = nil
    var onMoreTapped: (() -> Void)? = nil
    
    @StateObject private var downloadManager = DownloadManager.shared
    
    private var progress: Double {
        return downloadManager.activeDownloads[attachment.id] ?? 0.0
    }
    
    private var isDownloading: Bool {
        progress > 0 && progress < 1
    }
    
    private var extensionName: String {
        if let ext = attachment.extension.split(separator: ".").last {
            return String(ext)
        }
        return attachment.extension
    }
    
    var body: some View {
        
        Button(action: handleAttachmentTapped) {
            HStack(spacing: 12) {
                Text(extensionName.uppercased())
                    .font(FontFamily.customFont(size: FontSize.xxxsmall, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.textTeritiaryColor)
                    .cornerRadius(4)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(attachment.name)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                        .foregroundColor(.textSecondaryColor)
                        .lineLimit(1)
                        .truncationMode(.tail)
                    
                    Text(formattedSizeRounded(from: Int64(attachment.size)))
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        .foregroundColor(.textTeritiaryColor)
                    
                    if isDownloading {
                        HStack(spacing: 8) {
                            CapsuleProgressBar(progress: progress)
                                .frame(maxWidth: .infinity)
                            Text("\(Int(progress * 100))%")
                                .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
                                .foregroundColor(.textTeritiaryColor)
                        }
                        .padding(.top, 4)
                    }
                }
                
                Spacer()
                
                if !isDownloading {
                    if DeviceType.isPhone {
                        if canDelete {
                            Button(action: handleMoreTapped) {
                                AppIcon(icon: .contextMenuIcon)
                            }
                        } else {
                            Button(action: {
                                DownloadManager.shared.handleDownloadTapped(attachment: attachment, dataToken: dataToken)
                            }) {
                                AppIcon(icon: .download)
                            }
                            .disabled(isDownloading)
                        }
                    } else {
                        HStack(spacing: 16) {
                            Button(action: {
                                DownloadManager.shared.handleDownloadTapped(attachment: attachment, dataToken: dataToken)
                            }) {
                                AppIcon(icon: .download)
                            }
                            .disabled(isDownloading)
                            
                            if canDelete {
                                Button(action: handleDeleteTapped) {
                                    AppIcon(icon: .delete)
                                }
                            }
                        }
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .overlay(
                RoundedRectangle(cornerRadius: DeviceConfig.isIPhone ? 12 : 10)
                    .stroke(Color.borderSecondaryColor, lineWidth: 1)
            )
        }
    }
    
    private func handleMoreTapped() {
        selectedAttachment = attachment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onMoreTapped?()
        }
    }
    
    private func handleDeleteTapped() {
        selectedAttachment = attachment
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            onDelete?()
        }
    }
    
    private func handleAttachmentTapped() {
        if DownloadManager.shared.localFileURL(for: attachment) != nil {
            // Already downloaded → open file
            DownloadManager.shared.openDownloadedFile(attachment)
        } else {
            if [".jpg", ".jpeg", ".png", ".gif", ".bmp", "heic"].contains(attachment.extension.lowercased()) {
                // Preview image attachments
                NotificationCenter.default.post(name: .toggleOnlineImagePreview, object: nil)
                NavigationHelper.push(
                    OnlineImagePreviewerView(attachment: attachment, dataToken: AppConstant.fileToken)
                        .environmentObject(ToastManager.shared)
                )
            } else {
                ToastManager.shared.show(ResourceManager.localized("downloadFirstText"), type: .info)
            }
        }
    }

}


struct CapsuleProgressBar: View {
    var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.borderSecondaryColor.opacity(0.3))
                    .frame(height: 6)
                Capsule()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 6)
    }
}
