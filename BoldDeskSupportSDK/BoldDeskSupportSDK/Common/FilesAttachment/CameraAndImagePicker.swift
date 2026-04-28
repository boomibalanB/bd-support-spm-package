import SwiftUI
import UIKit
import PhotosUI
import UniformTypeIdentifiers
import MobileCoreServices

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onMediaPicked: (PickedMediaInfo?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.mediaTypes = ["public.image", "public.movie"]
        picker.videoQuality = .typeHigh
        picker.cameraCaptureMode = .photo
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onMediaPicked: onMediaPicked)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var isPresented: Bool
        let onMediaPicked: (PickedMediaInfo?) -> Void

        init(isPresented: Binding<Bool>, onMediaPicked: @escaping (PickedMediaInfo?) -> Void) {
            _isPresented = isPresented
            self.onMediaPicked = onMediaPicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                let name = "Camera_\(Int(Date().timeIntervalSince1970)).jpg"
                let imageData = image.jpegData(compressionQuality: 1.0)
                let size = Int64(imageData?.count ?? 0)

                // Save to temporary file
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
                try? imageData?.write(to: tempURL)

                let info = PickedMediaInfo(
                    image: image,
                    file: tempURL, // ✅ Now file is set
                    name: name,
                    fileExtension: "jpg",
                    fileSizeInBytes: size
                )

                onMediaPicked(info)
            } else if let url = info[.mediaURL] as? URL {
                let name = url.lastPathComponent
                let ext = url.pathExtension
                let size = try? FileManager.default.attributesOfItem(atPath: url.path)[.size] as? Int64 ?? 0

                let info = PickedMediaInfo(
                    image: nil,
                    file: url,
                    name: name,
                    fileExtension: ext,
                    fileSizeInBytes: size ?? 0
                )

                onMediaPicked(info)
            } else {
                onMediaPicked(nil)
            }

            isPresented = false
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onMediaPicked(nil)
            isPresented = false
        }
    }
}


struct ImagePicker: UIViewControllerRepresentable {
    @Binding var isPresented: Bool
    var onMediaPicked: (PickedMediaInfo?) -> Void

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        picker.mediaTypes = ["public.image", "public.movie"] // support both
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(isPresented: $isPresented, onMediaPicked: onMediaPicked)
    }

    class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
        @Binding var isPresented: Bool
        let onMediaPicked: (PickedMediaInfo?) -> Void

        init(isPresented: Binding<Bool>, onMediaPicked: @escaping (PickedMediaInfo?) -> Void) {
            self._isPresented = isPresented
            self.onMediaPicked = onMediaPicked
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let pickedImage = info[.originalImage] as? UIImage {
                let name = "Photo_\(Int(Date().timeIntervalSince1970)).jpg"
                let imageData = pickedImage.jpegData(compressionQuality: 1.0)
                let size = Int64(imageData?.count ?? 0)
                
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(name)
                try? imageData?.write(to: tempURL)
                
                let media = PickedMediaInfo(
                    image: pickedImage,
                    file: tempURL,
                    name: name,
                    fileExtension: "jpg",
                    fileSizeInBytes: size
                )
                onMediaPicked(media)

            } else if let videoURL = info[.mediaURL] as? URL {
                let name = videoURL.lastPathComponent
                let ext = videoURL.pathExtension
                let size = (try? FileManager.default.attributesOfItem(atPath: videoURL.path)[.size] as? Int64) ?? 0

                let media = PickedMediaInfo(
                    image: nil,
                    file: videoURL,
                    name: name,
                    fileExtension: ext,
                    fileSizeInBytes: size
                )
                onMediaPicked(media)

            } else {
                onMediaPicked(nil)
            }

            isPresented = false // SwiftUI dismisses the sheet
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            onMediaPicked(nil)
            isPresented = false // SwiftUI dismisses the sheet
        }
    }
}
