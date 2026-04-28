import SwiftUI

struct ImagePreviewView: View {
    let imageUrl: String
    let token: String?

    @State private var image: UIImage? = nil
    @State private var isLoading: Bool = true
    @State private var error: Error? = nil
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero

    private let minScale: CGFloat = 1.0
    private let maxScale: CGFloat = 5.0

    var body: some View {
        ZStack {
            if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                    .scaleEffect(1.5)
            } else if let image = image {
                ScrollView([.horizontal, .vertical], showsIndicators: false) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(
                            width: UIScreen.main.bounds.width,
                            height: UIScreen.main.bounds.width * (image.size.height / image.size.width)
                        )
                        .scaleEffect(scale)
                        .offset(offset)
                        .gesture(
                            MagnificationGesture()
                                .onChanged { value in
                                    let delta = value / lastScale
                                    lastScale = value
                                    let newScale = scale * delta
                                    scale = min(max(newScale, minScale), maxScale)
                                }
                                .onEnded { _ in
                                    lastScale = 1.0
                                }
                                .simultaneously(with: DragGesture()
                                    .onChanged { value in
                                        offset = CGSize(
                                            width: lastOffset.width + value.translation.width,
                                            height: lastOffset.height + value.translation.height
                                        )
                                    }
                                    .onEnded { _ in
                                        lastOffset = offset
                                    }
                                )
                        )
                        .gesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    withAnimation {
                                        if scale > minScale {
                                            scale = minScale
                                            offset = .zero
                                            lastOffset = .zero
                                        } else {
                                            scale = min(maxScale / 2, minScale * 2)
                                            offset = .zero
                                            lastOffset = .zero
                                        }
                                    }
                                }
                        )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.backgroundPrimary.edgesIgnoringSafeArea(.all))
            } else if error != nil {
                VStack (spacing: 16) {
                    Text(ResourceManager.localized("unableToLoadTheImageText"))
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        .foregroundColor(.textSecondaryColor)
                        .multilineTextAlignment(.center)
                    Button(action: {
                        Task {
                            await loadImage()
                        }
                    }) {
                        HStack {
                            AppIcon(icon: .reset, size: 16, color: Color.accentColor)
                            Text(ResourceManager.localized("retryText", comment: "Retry"))
                                .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                                .foregroundColor(.accentColor)
                        }
                        .padding(.vertical, 4)
                        .padding(.horizontal, 10)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(20)
                    }
                }
            }
        }
        .onAppear {
            Task { await loadImage() }
        }
        .navigationBarTitleDisplayMode(.inline)
    }

    private func loadImage() async {
        isLoading = true
        error = nil

        do {
            let base64String = await ImageFetcher.shared.fetchImage(from: imageUrl, token: token)
            guard let data = Data(base64Encoded: base64String),
                  let uiImage = UIImage(data: data) else {
                throw URLError(.cannotDecodeContentData)
            }
            await MainActor.run {
                self.image = uiImage
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
}
