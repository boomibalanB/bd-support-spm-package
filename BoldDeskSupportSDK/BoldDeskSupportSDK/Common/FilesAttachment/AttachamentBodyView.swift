import SwiftUI

struct AttachmentBodyContent: View {

    @ObservedObject var manager: UploadManager
    @EnvironmentObject var toastManager: ToastManager
    var onTap: () -> Void
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showFileImporter = false

    @State private var showPicker = false

    var body: some View {
        VStack {
            HStack(spacing: 0) {
                Spacer()

                Button(action: {
                    showCameraPicker = true
                }) {
                    VStack {
                        AppIcon(icon: .startRecord)
                            .padding(16)
                            .font(
                                FontFamily.customFont(
                                    size: FontSize.semilarge,
                                    weight: .regular
                                )
                            )

                            .foregroundColor(Color.iconBackgroundColor)
                            .background(Color.attachmentIconBackgroundColor)
                            .cornerRadius(8)

                        Text(
                            ResourceManager.localized("cameraText", comment: "")
                        )
                        .font(
                            FontFamily.customFont(
                                size: FontSize.xsmall,
                                weight: .regular
                            )
                        )

                        .foregroundColor(Color.textSecondaryColor)
                    }
                }

                Spacer()

                Button(action: {
                    showImagePicker = true
                }) {
                    VStack {
                        AppIcon(icon: .image)
                            .padding(16)
                            .foregroundColor(Color.iconBackgroundColor)
                            .background(Color.attachmentIconBackgroundColor)
                            .cornerRadius(8)

                        Text(ResourceManager.localized("gallery", comment: ""))
                            .font(
                                FontFamily.customFont(
                                    size: FontSize.xsmall,
                                    weight: .regular
                                )
                            )

                            .foregroundColor(Color.textSecondaryColor)
                    }
                }

                Spacer()

                Button(action: {
                    showFileImporter = true
                }) {
                    VStack {
                        AppIcon(icon: .file)
                            .padding(16)
                            .foregroundColor(Color.iconBackgroundColor)
                            .background(Color.attachmentIconBackgroundColor)
                            .cornerRadius(8)

                        Text(ResourceManager.localized("files", comment: ""))
                            .font(
                                FontFamily.customFont(
                                    size: FontSize.xsmall,
                                    weight: .regular
                                )
                            )

                            .foregroundColor(Color.textSecondaryColor)
                    }
                }

                Spacer()
            }

        }
        .padding(.vertical, DeviceType.isTablet ? 12 : 16)
        .sheet(isPresented: $showCameraPicker) {
            CameraPicker(isPresented :$showCameraPicker , onMediaPicked: { pickedFile in
                if let file = pickedFile {
                    let totalSize = Int(bytesToMegabytes(manager.totalFileSizeInBytes + file.fileSizeInBytes))
                    if totalSize <= AppConstant.maxFileSizeInMB
                    {
                        manager.totalFileSizeInBytes += file.fileSizeInBytes
                        manager.pickedItems.append(file)
                    }
                    else{
                        ToastManager.shared.show(
                            "\(ResourceManager.localized("fileSizeExceedText", comment: "")) \(AppConstant.maxFileSizeInMB) MB Limit",
                            type: .error
                        )
                    }
                }
                onTap()
            })
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePicker(isPresented: $showImagePicker) { pickedFile in
                if let file = pickedFile {
                    let totalSize = Int(bytesToMegabytes(manager.totalFileSizeInBytes + file.fileSizeInBytes))
                    if totalSize <= AppConstant.maxFileSizeInMB
                    {
                        manager.totalFileSizeInBytes += file.fileSizeInBytes
                        manager.pickedItems.append(file)
                    }
                    else{
                        ToastManager.shared.show(
                            "\(ResourceManager.localized("fileSizeExceedText", comment: "")) \(AppConstant.maxFileSizeInMB) MB Limit",
                            type: .error
                        )
                    }
                }
                onTap()
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.item]
        ) { result in
            switch result {
            case .success(let url):
                let isAccessing = url.startAccessingSecurityScopedResource()
                defer {
                    if isAccessing {
                        url.stopAccessingSecurityScopedResource()
                    }
                }

                let fileExtension = url.pathExtension
                var fileSize: Int64 = 0
                if let fileAttributes = try? FileManager.default.attributesOfItem(atPath: url.path),
                   let size = fileAttributes[.size] as? Int64 {
                    fileSize = size
                }

                let totalSize = Int(bytesToMegabytes(manager.totalFileSizeInBytes + fileSize))

                // Always run UI updates on the main actor
                Task { @MainActor in
                    if totalSize <= AppConstant.maxFileSizeInMB {
                        manager.totalFileSizeInBytes += fileSize
                        let picked = PickedMediaInfo(
                            image: nil,
                            file: url,
                            name: url.lastPathComponent,
                            fileExtension: fileExtension,
                            fileSizeInBytes: fileSize
                        )
                        manager.pickedItems.append(picked)
                    } else {
                        // Toast will now appear reliably
                        ToastManager.shared.show(
                            "\(ResourceManager.localized("fileSizeExceedText", comment: "")) \(AppConstant.maxFileSizeInMB) MB Limit",
                            type: .error
                        )
                    }

                    onTap()
                }

            case .failure(let error):
                Task { @MainActor in
                    ToastManager.shared.show(error.localizedDescription, type: .error)
                    onTap()
                }
            }
        }
        .onChange(of: showFileImporter) { isPresented in
            if !isPresented {
                onTap()
            }
        }
        .background(Color.backgroundPrimary)
    }
}
