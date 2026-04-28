import Foundation
import SwiftUI
import Combine
import QuickLook
import UIKit

final class DownloadManager: NSObject, ObservableObject, URLSessionDownloadDelegate {
    static let shared = DownloadManager()
    
    // Maps attachmentId → progress (0.0–1.0)
    @Published var activeDownloads: [Int: Double] = [:]
    
    private var completionHandlers: [Int: (Bool, URL?) -> Void] = [:]
    private var dataTokens: [Int: String] = [:]
    private var fileNames: [Int: String] = [:]
    private var downloadTasks: [Int: URLSessionDownloadTask] = [:]
    private var downloadURLs: [Int: URL] = [:]
    
    private lazy var session: URLSession = {
        let config = URLSessionConfiguration.ephemeral
        config.waitsForConnectivity = false
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()
    
    private override init() { super.init() }
    
    // MARK: - Public Method (Handle Tap)
    func handleDownloadTapped(attachment: Attachment, dataToken: String? = nil) {
        guard let url = URL(string: attachment.fileUrl) else { return }
        
        // Check if already downloaded
        if fileAlreadyExists(named: attachment.name) != nil {
            ToastManager.shared.show(
                "\(ResourceManager.localized("fileAlreadyDownloadedText", comment: ""))",
                type: .info
            )
            return
        }
        
        // Show minimal progress instantly
        activeDownloads[attachment.id] = 0.001
        
        // Start download
        DownloadManager.shared.download(
            attachmentId: attachment.id,
            from: url,
            fileName: attachment.name,
            dataToken: dataToken
        ) { [weak self] success, fileURL in
            self?.activeDownloads[attachment.id] = nil
        }
    }
    
    // MARK: - Start Download
    // Downloads and saves the file to app's Documents directory
    func download(
        attachmentId: Int,
        from url: URL,
        fileName: String,
        dataToken: String? = nil,
        completion: ((Bool, URL?) -> Void)? = nil
    ) {
        
        if downloadTasks[attachmentId] != nil { return }
        
        let urlString = url.absoluteString.lowercased()
        let hasTokenInURL = urlString.contains("token=")
        
        guard hasTokenInURL || dataToken != nil else {
            // No valid authorization → fail immediately
            ToastManager.shared.show(
                ResourceManager.localized("downloadFailedText", comment: ""),
                type: .error
            )
            completion?(false, nil)
            return
        }
        
        var request = URLRequest(url: url)
        if let token = dataToken {
            dataTokens[attachmentId] = token
            request.setValue(token, forHTTPHeaderField: "bd-datatoken")
        }
        
        fileNames[attachmentId] = fileName
        downloadURLs[attachmentId] = url
        completionHandlers[attachmentId] = completion
        
        let task = session.downloadTask(with: request)
        downloadTasks[attachmentId] = task
        
        activeDownloads[attachmentId] = 0.001
        objectWillChange.send()
        
        task.resume()
    }
    
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64,
                    totalBytesExpectedToWrite: Int64) {
        guard let id = attachmentId(for: downloadTask) else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        //Update the progress
        activeDownloads[id] = progress
        objectWillChange.send()
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask,
                    didFinishDownloadingTo location: URL) {
        //Hits when the download finishes
        guard let id = attachmentId(for: downloadTask) else { return }
        
        activeDownloads[id] = 1.0
        objectWillChange.send()
        
        let fileName = fileNames[id] ?? "attachment_\(id).tmp"
        let destinationURL = saveDownloadedFile(tempURL: location, fileName: fileName)
        
        completionHandlers[id]?(true, destinationURL)
        cleanup(for: id)
        
        ToastManager.shared.show(ResourceManager.localized("attachmentDownloadedText"), type: .success)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    didCompleteWithError error: Error?) {
        //Hit when the download fails
        guard let id = attachmentId(for: task) else { return }
        if let error = error {
            ToastManager.shared.show("\(ResourceManager.localized("downloadFailedText")) : \(error.localizedDescription)", type: .error)
            completionHandlers[id]?(false, nil)
        }
        cleanup(for: id)
        objectWillChange.send()
    }
    
    private func attachmentId(for task: URLSessionTask) -> Int? {
        return downloadTasks.first { $0.value == task }?.key
    }
    
    private func fileAlreadyExists(named fileName: String) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = docs.appendingPathComponent(fileName)
        return FileManager.default.fileExists(atPath: destination.path) ? destination : nil
    }
    
    private func saveDownloadedFile(tempURL: URL, fileName: String) -> URL? {
        let fileManager = FileManager.default
        let docs = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        var destination = docs.appendingPathComponent(fileName)
        
        var suffix = 1
        let nameWithoutExt = (fileName as NSString).deletingPathExtension
        let ext = (fileName as NSString).pathExtension
        
        while fileManager.fileExists(atPath: destination.path) {
            let newFileName = "\(nameWithoutExt)(\(suffix))" + (ext.isEmpty ? "" : ".\(ext)")
            destination = docs.appendingPathComponent(newFileName)
            suffix += 1
        }
        
        do {
            try fileManager.moveItem(at: tempURL, to: destination)
            return destination
        } catch {
            return nil
        }
    }
    
    private func cleanup(for attachmentId: Int) {
        completionHandlers[attachmentId] = nil
        dataTokens[attachmentId] = nil
        fileNames[attachmentId] = nil
        downloadTasks[attachmentId] = nil
        downloadURLs[attachmentId] = nil
        activeDownloads[attachmentId] = nil
    }
    
    func cancelAllDownloads() {
        for (_, task) in downloadTasks { task.cancel() }
        activeDownloads.removeAll()
        completionHandlers.removeAll()
        downloadTasks.removeAll()
        dataTokens.removeAll()
        downloadURLs.removeAll()
        fileNames.removeAll()
        objectWillChange.send()
    }
    
    func localFileURL(for attachment: Attachment) -> URL? {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let destination = docs.appendingPathComponent(attachment.name)
        if FileManager.default.fileExists(atPath: destination.path) {
            return destination
        }
        return nil
    }
    
    func openDownloadedFile(_ attachment: Attachment) {
        // Get the local file path where the attachment is saved
        guard let fileURL = localFileURL(for: attachment) else {
            // If file not found, show a message to download it first
            ToastManager.shared.show(ResourceManager.localized("downloadFirstText"), type: .info)
            return
        }
        
        // Run on main thread since we’re updating the UI
        DispatchQueue.main.async {
            // Create a preview screen to show the file
            let previewController = QLPreviewController()
            
            // Tell the preview controller which file to show
            let previewItem = PreviewItem(url: fileURL)
            previewController.dataSource = previewItem
            previewController.modalPresentationStyle = .fullScreen
            
            // Get the main app window (supports iOS 15+ and older)
            let keyWindow: UIWindow? = {
                if #available(iOS 15.0, *) {
                    return UIApplication.shared.connectedScenes
                        .compactMap { ($0 as? UIWindowScene)?.keyWindow }
                        .first
                } else {
                    return UIApplication.shared.windows.first(where: { $0.isKeyWindow })
                }
            }()
            
            // Get the main view controller from the window
            guard let rootVC = keyWindow?.rootViewController else {
                ToastManager.shared.show(ResourceManager.localized("unableToPreviewText"), type: .error)
                return
            }
            
            // Find the topmost screen that’s currently shown
            var topVC = rootVC
            while let presented = topVC.presentedViewController {
                topVC = presented
            }
            
            // Show the file preview
            topVC.present(previewController, animated: true)
        }
    }
}

extension DownloadManager: UIDocumentInteractionControllerDelegate {
    // Needed if file preview uses UIDocumentInteractionController
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        UIApplication.shared.windows.first?.rootViewController ?? UIViewController()
    }
}

private class PreviewItem: NSObject, QLPreviewControllerDataSource, QLPreviewItem {
    var previewItemURL: URL?
    
    // Store the file’s URL
    init(url: URL) {
        previewItemURL = url
    }
    
    // Only one file to preview
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
    
    // Return the file to preview
    func previewController(_ controller: QLPreviewController,
                           previewItemAt index: Int) -> QLPreviewItem {
        return self
    }
}

