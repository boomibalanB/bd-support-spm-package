import Foundation
import SwiftUI
import WebKit

struct HTMLWebView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var htmlWebViewModel: HTMLWebViewModel
    @EnvironmentObject var toastManager: ToastManager
    var articleId: Int = 0
    @State private var isPresented = false
    @Environment(\.colorScheme) var colorScheme
    @State private var contentHeight: CGFloat = .zero

    private let isForShimmer: Bool
    
    init(articleId: Int, articleName: String, isForShimmer: Bool = false) {
        self.articleId = articleId
        self.isForShimmer = isForShimmer
        _htmlWebViewModel = StateObject(
            wrappedValue: HTMLWebViewModel(
                isDisabled: isForShimmer,
                articleId: articleId,
                articleName: articleName
            )
        )
    }
    
    static func shimmerPage() -> HTMLWebView {
        HTMLWebView(articleId: 0, articleName: "", isForShimmer: true)
    }

    var body: some View {
        AppPage {
            VStack(alignment: .leading, spacing: 0) {
                CommonAppBar(
                    title: ResourceManager.localized(
                        "knowledgeBaseText",
                        comment: ""
                    ),
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                VStack(alignment: .leading, spacing: 0) {
                    if htmlWebViewModel.isLoading {
                        ArticlesShimmer()
                    } else {
                        if !htmlWebViewModel.kbTitle.isEmpty {
                            VStack(spacing: 0) {
                                ScrollView {
                                    Text(htmlWebViewModel.kbTitle)
                                        .foregroundColor(Color.textPrimaryColor)
                                        .font(
                                            FontFamily.customFont(
                                                size: DeviceType.isPhone ? FontSize.extralarge : FontSize.xxlarge,
                                                weight: .semibold
                                            )
                                        )
                                        .multilineTextAlignment(.leading)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 26)
                                        .padding(.horizontal, 12)

                                    
                                    WebView(
                                        url: nil,
                                        htmlString: htmlWebViewModel.kbHTMLContent,
                                        contentHeight: $contentHeight
                                    )
                                    .frame(height: contentHeight)
                                    .id(colorScheme)
                                    
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .padding(.horizontal, 12)
                                    .padding(.top, 16)
                                    .padding(.bottom, 16)
                                }
                                
                                if contentHeight > 0 && !htmlWebViewModel.isLikedOrDisliked {
                                    FeedbackCardView(
                                        onLike: {
                                            Task {
                                                await htmlWebViewModel.likeArticle(
                                                    articleId: articleId
                                                )
                                            }
                                        },
                                        onDislike: {
                                            isPresented = true
                                        }
                                    )
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
                                }
                            }
                        } else{
                            VStack {
                                Spacer()
                                Text(ResourceManager.localized("articleNotExist", comment: ""))
                                    .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                                    .foregroundColor(.textTeritiaryColor)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                Spacer()
                            }
                        }
                    }
                }
                .overlay(ToastStackView())
                Devider(color: Color.backgroundTeritiaryColor)
                    .sheet(isPresented: $isPresented) {
                        DislikeFeedbackSlider(
                            isPresented: $isPresented,
                            articleId: articleId,
                            htmlWebviewModel: htmlWebViewModel
                        )
                        .presentationCornerRadius(12)
                    }
                    .background(Color.backgroundPrimary)
                PoweredByFooterView()
            }
            .background(Color.backgroundPrimary)
            .onChange(of: colorScheme) { _ in
                contentHeight = .zero
            }
        }
    }
}

struct WebView: UIViewRepresentable {
    let url: URL?
    let htmlString: String?
    @Binding var contentHeight: CGFloat
    @Environment(\.colorScheme) var colorScheme
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.configuration.allowsInlineMediaPlayback = true
        webView.configuration.dataDetectorTypes = []
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = false
        webView.scrollView.showsVerticalScrollIndicator = false
        webView.scrollView.showsHorizontalScrollIndicator = false
        webView.scrollView.isScrollEnabled = false
        
        let localStyles = loadAllCSS()

        if let url = url {
            webView.load(URLRequest(url: url))
        } else if let html = htmlString {
            let css = customCSS()
            let isDarkMode = (colorScheme == .dark)
            let theme = isDarkMode ? "dark" : "light"
            let darkModeClass = isDarkMode ? "e-dark-mode" : ""

            let responsiveHTML = """
            <!DOCTYPE html>
            <html lang="en" data-bs-theme="\(theme)">
            <head>
                <meta charset="utf-8">
                <meta name="viewport" content="width=device-width, initial-scale=1.0">
                <style>
                    \(css)
                    \(localStyles)
                </style>
                <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap">
                <link rel="stylesheet" href="https://fonts.gstatic.com/s/roboto/v47/KFO7CnqEu92Fr1ME7kSn66aGLdTylUAMa3yUBA.woff2">
                <link rel="stylesheet" href="https://fonts.gstatic.com/s/inter/v20/UcC73FwrK3iLTeHuS_nVMrMxCp50SjIa1ZL7.woff2">
                <link rel="stylesheet" href="https://fonts.googleapis.com/css2?family=Inter:wght@100;200;300;400;500;600;700;800;900&display=swap">
            </head>
            <body class="articles-description-container article-description-content-overwrite pt-10 \(darkModeClass)">
                <div id="article-description" class="article-description toastui-editor-contents">
                    \(html)
                </div>
            </body>
            </html>
            """
            
            let refererString = "https://\(Bundle.main.bundleIdentifier ?? "com.sampleapp")"
            webView.loadHTMLString(
                responsiveHTML,
                baseURL: URL(string: refererString)
            )
        }

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if let url = url, uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.readyState") { complete, _ in
                guard complete != nil else { return }
                
                webView.evaluateJavaScript("document.body.scrollHeight") { height, _ in
                    if let h = height as? CGFloat, h > 0 {
                        DispatchQueue.main.async {
                            self.parent.contentHeight = h
                        }
                    }
                }
            }
        }
    }
    
    
    private func customCSS() -> String {
        let backgroundColor = colorScheme == .dark ? "#0C111D" : "#FFFFFF"
        
        return """
            body {
                margin: 0;
                padding: 0;
                background-color: \(backgroundColor) !important;
            }
            iframe {
                display: block;
                width: 100%;
                max-width: 100%;
                height: auto;
                border: none;
            }
            video, img {
                max-width: 100%;
                height: auto;
            }
            """
    }
    
    func loadAllCSS() -> String {
        
        let bundle = Bundle(for: AppSettingsManager.self)
        
        let cssFiles = [
            "articleDetails.min",
            "bds_kb_29_2_4.min",
            "bold-chat-widget",
            "bootstrap_5_3_2_v1.min",
            "google-font-apis.min",
            "highlightjs.min",
            "highlightjs_v1.min",
            "layout.min",
            "tui_edior_3.1.5_v1.min"
        ]
        
        var combinedCSS = ""
        
        for file in cssFiles {
            if let url = bundle.url(forResource: file, withExtension: "css"),
               let cssContent = try? String(contentsOf: url) {
                combinedCSS += "\n/* --- \(file).css --- */\n"
                combinedCSS += cssContent
            }
        }
        
        return combinedCSS
    }

}

struct FeedbackCardView: View {
    var onLike: () -> Void
    var onDislike: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Text(ResourceManager.localized("articleFeedbackText", comment: ""))
                .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                .foregroundColor(.feedbackCardForegroundColor)
            HStack(spacing: 0) {
                Spacer()
                FeedbackButton(
                    title: ResourceManager.localized("likeText", comment: ""),
                    appIcon: .like,
                ) {
                    onLike()
                }
                Spacer()
                    .frame(width: 12)
                FeedbackButton(
                    title: ResourceManager.localized("dislikeText", comment: ""),
                    appIcon: .dislike,
                ) {
                    onDislike()
                }
                Spacer()
            }
        }
        .padding(.vertical, DeviceType.isPhone ? 16 : 20)
        .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
        .background(Color.feedbackCardBackgroundColor)
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.feedbackCardForegroundColor.opacity(0.2))
        )
    }
    
}

struct FeedbackButton: View {
    let title: String
    let appIcon: AppIcons
    let action: () -> Void
    
    var body: some View {
        OutlinedButton.withIcon(
            title: title,
            icon: appIcon,
            onClick: action,
            iconOnRight: false,
            isSmall: true,
            color: .feedbackCardForegroundColor
        )
    }
}
