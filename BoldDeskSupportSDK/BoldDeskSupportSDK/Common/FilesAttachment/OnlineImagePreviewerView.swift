import SwiftUI

struct OnlineImagePreviewerView: View {
    let attachment: Attachment
    var dataToken: String? = nil
    
    @StateObject private var viewModel = OnlineImagePreviewViewModel()
    @StateObject private var downloadManager = DownloadManager.shared
    @Environment(\.presentationMode) private var presentationMode
    
    // Zoom / Pan state
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    // double tap toggles to this value
    private let doubleTapZoom: CGFloat = 2.5
    private let minZoom: CGFloat = 1.0
    private let maxZoom: CGFloat = 4.0
    
    private var progress: Double {
        downloadManager.activeDownloads[attachment.id] ?? 0.0
    }
    
    private var isDownloading: Bool {
        progress > 0 && progress < 1
    }
    
    var body: some View {
        AppPage {
            VStack(spacing: 0) {
                
                CommonAppBar(
                    title: attachment.name,
                    showBackButton: true,
                    onBack: {
                        NotificationCenter.default.post(name: .toggleOnlineImagePreview, object: nil)
                        presentationMode.wrappedValue.dismiss()
                    }
                ) {
                    if !isDownloading {
                        Button(action: downloadTapped) {
                            AppIcon.appbar(.download)
                                .padding(8)
                        }
                    }
                }
                
                
                ZStack(alignment: .top) {
                    GeometryReader { geo in
                        ZStack {
                            Color.tabBarViewBackgroundTeritiaryColor.ignoresSafeArea()
                            
                            Group {
                                if viewModel.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                                } else if viewModel.loadError {
                                    Text(ResourceManager.localized("unableToLoadTheImageText", comment: ""))
                                        .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                                        .foregroundColor(.textTeritiaryColor)
                                } else if let image = viewModel.loadedImage {
                                    zoomableImage(image: image, containerSize: geo.size)
                                } else {
                                    ProgressView()
                                }
                            }
                        }
                        .onAppear {
                            viewModel.loadImage(attachment: attachment, dataToken: dataToken)
                        }
                    }
                   
                    if isDownloading {
                        RectangleProgressBar(progress: progress)
                    }
                }
            }
            .background(Color.tabBarViewBackgroundTeritiaryColor.ignoresSafeArea())
            .overlay(ToastStackView())
        }
    }
    
    @ViewBuilder
    private func zoomableImage(image: UIImage, containerSize: CGSize) -> some View {
        // Centering and applying offset + scale
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .scaleEffect(scale)
            .offset(offset)
            .gesture(
                // Pan (drag) gesture — only effective when zoomed in
                DragGesture()
                    .onChanged { value in
                        // allow dragging when zoomed in
                        guard scale > minZoom + 0.01 else { return }
                        offset = CGSize(width: lastOffset.width + value.translation.width, height: lastOffset.height + value.translation.height)
                    }
                    .onEnded { _ in
                        // store last offset and clamp to reasonable bounds based on scaled image size
                        lastOffset = clampedOffset(for: offset, containerSize: containerSize, imageSize: image.size, scale: scale)
                        offset = lastOffset
                    }
                    .exclusively(before:
                        // Magnification as simultaneous with drag can be finicky — use highPriority for pinch
                        MagnificationGesture()
                            .onChanged { value in
                                // live scale
                                scale = (lastScale * value).clamped(to: minZoom...maxZoom)
                            }
                            .onEnded { _ in
                                lastScale = scale.clamped(to: minZoom...maxZoom)
                                // clamp offset after zoom to ensure image doesn't go too far
                                lastOffset = clampedOffset(for: lastOffset, containerSize: containerSize, imageSize: image.size, scale: lastScale)
                                offset = lastOffset
                            }
                    )
            )
            // Double tap to toggle between minZoom and doubleTapZoom
            .highPriorityGesture(
                TapGesture(count: 2)
                    .onEnded {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            if abs(scale - minZoom) < 0.01 {
                                scale = doubleTapZoom
                            } else {
                                scale = minZoom
                                offset = .zero
                                lastOffset = .zero
                                lastScale = minZoom
                            }
                        }
                    }
            )
            .animation(.easeInOut(duration: 0.15), value: scale)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // Clamp offset so image doesn't go out of visible bounds too far
    private func clampedOffset(for offset: CGSize, containerSize: CGSize, imageSize: CGSize, scale: CGFloat) -> CGSize {
        // compute scaled image dimensions when fitted in container
        let fitted = fittedImageSize(for: imageSize, containerSize: containerSize)
        let scaledWidth = fitted.width * scale
        let scaledHeight = fitted.height * scale
        
        // allowable offset (centered at 0), half overflow
        let maxX = max(0, (scaledWidth - containerSize.width) / 2)
        let maxY = max(0, (scaledHeight - containerSize.height) / 2)
        
        let clampedX = offset.width.clamped(to: -maxX...maxX)
        let clampedY = offset.height.clamped(to: -maxY...maxY)
        return CGSize(width: clampedX, height: clampedY)
    }
    
    // Compute fitted image size (scaled to fit) for base image before applying zoom
    private func fittedImageSize(for imageSize: CGSize, containerSize: CGSize) -> CGSize {
        guard imageSize.width > 0 && imageSize.height > 0 else { return .zero }
        let imageAspect = imageSize.width / imageSize.height
        let containerAspect = containerSize.width / containerSize.height
        if imageAspect > containerAspect {
            // wide image fits width
            let width = containerSize.width
            let height = width / imageAspect
            return CGSize(width: width, height: height)
        } else {
            // tall image fits height
            let height = containerSize.height
            let width = height * imageAspect
            return CGSize(width: width, height: height)
        }
    }
    
    private func downloadTapped() {
        DownloadManager.shared.handleDownloadTapped(
            attachment: attachment,
            dataToken: dataToken
        )
    }
}

fileprivate extension Comparable {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

fileprivate extension BinaryFloatingPoint {
    func clamped(to limits: ClosedRange<Self>) -> Self {
        min(max(self, limits.lowerBound), limits.upperBound)
    }
}

struct RectangleProgressBar: View {
    var progress: Double
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(Color.borderSecondaryColor)
                    .frame(height: 6)
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: geometry.size.width * progress, height: 6)
                    .animation(.easeInOut(duration: 0.25), value: progress)
            }
        }
        .frame(height: 6)
    }
}

extension Notification.Name {
    static let toggleOnlineImagePreview = Notification.Name("ToggleOnlineImagePreviewPage")
}

