import Foundation
import SwiftUI
@preconcurrency import WebKit
import SafariServices

struct HTMLView: UIViewRepresentable {
    let htmlContent: String
    @Binding var contentHeight: CGFloat
    let token: String?
    
    init(htmlContent: String, contentHeight: Binding<CGFloat>, token: String? = nil) {
        self.htmlContent = htmlContent
        self._contentHeight = contentHeight
        self.token = token
    }
    
    @Environment(\.colorScheme) var colorScheme
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "imageUrl")
        config.userContentController.add(context.coordinator, name: "imageTapped")
        config.userContentController.add(context.coordinator, name: "linkTapped")
        
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.bounces = false
        webView.backgroundColor = .clear
        return webView
    }
    
    func updateUIView(_ uiView: WKWebView, context: Context) {
        let customCSS = customCSS()
        let customJavaScript = customJavaScript()
        let tokenScript = token != nil ? "<script>const authToken = '\(token!)';</script>" : ""
        
        let wrappedHTML = """
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                \(customCSS)
            </style>
            \(tokenScript)
        </head>
        <body>
            \(htmlContent)
            <script>
                \(customJavaScript)
            </script>
        </body>
        </html>
        """
        DispatchQueue.main.async {
            uiView.loadHTMLString(wrappedHTML, baseURL: nil)
        }
    }
    
    // MARK: - Private Methods
    
   private func customCSS() -> String {
        let theme = ThemeManager.shared.currentTheme
        
        switch theme {
        case .light:
            // Force light theme
            return """
                body {
                    margin: 0;
                    padding: 0;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    color: #000000; /* Black text */
                    background-color: transparent;
                }
                span, .elementToProof {
                    color: #000000 !important;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 12px;
                    text-align: left;
                }
                th { font-weight: bold; }
                .ios-spinner {
                    position: relative;
                    width: 40px;
                    height: 40px;
                }
                .spinner-segment {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    width: 3px;
                    height: 8px;
                    background-color: #3B82F6; /* Blue spinner */
                    border-radius: 2px;
                    opacity: 0.2;
                    transform-origin: center -3px;
                    animation: ios-spinner-fade 1s linear infinite;
                }
                .segment-1 { animation-delay: 0s; }
                .segment-2 { animation-delay: 0.125s; transform: rotate(45deg); }
                .segment-3 { animation-delay: 0.25s; transform: rotate(90deg); }
                .segment-4 { animation-delay: 0.375s; transform: rotate(135deg); }
                .segment-5 { animation-delay: 0.5s; transform: rotate(180deg); }
                .segment-6 { animation-delay: 0.625s; transform: rotate(225deg); }
                .segment-7 { animation-delay: 0.75s; transform: rotate(270deg); }
                .segment-8 { animation-delay: 0.875s; transform: rotate(315deg); }
                @keyframes ios-spinner-fade {
                    0%, 87.5% { opacity: 0.2; }
                    12.5% { opacity: 1; }
                }
                """
            
        case .dark:
            // Force dark theme
            return """
                body {
                    margin: 0;
                    padding: 0;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    color: #FFFFFF;
                    background-color: transparent;
                }
                span, .elementToProof {
                    color: #FFFFFF !important;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                th, td {
                    border: 1px solid #444;
                    padding: 12px;
                    text-align: left;
                }
                th { font-weight: bold; }
                .ios-spinner {
                    position: relative;
                    width: 40px;
                    height: 40px;
                }
                .spinner-segment {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    width: 3px;
                    height: 8px;
                    background-color: #FFFFFF;
                    border-radius: 2px;
                    opacity: 0.2;
                    transform-origin: center -3px;
                    animation: ios-spinner-fade 1s linear infinite;
                }
                .segment-1 { animation-delay: 0s; }
                .segment-2 { animation-delay: 0.125s; transform: rotate(45deg); }
                .segment-3 { animation-delay: 0.25s; transform: rotate(90deg); }
                .segment-4 { animation-delay: 0.375s; transform: rotate(135deg); }
                .segment-5 { animation-delay: 0.5s; transform: rotate(180deg); }
                .segment-6 { animation-delay: 0.625s; transform: rotate(225deg); }
                .segment-7 { animation-delay: 0.75s; transform: rotate(270deg); }
                .segment-8 { animation-delay: 0.875s; transform: rotate(315deg); }
                @keyframes ios-spinner-fade {
                    0%, 87.5% { opacity: 0.2; }
                    12.5% { opacity: 1; }
                }
                """
            
        case .system:
            return """
                body {
                    margin: 0;
                    padding: 0;
                    font-family: -apple-system, BlinkMacSystemFont, sans-serif;
                    color: #000000;
                    background-color: transparent;
                }
                span, .elementToProof {
                    color: \(colorScheme == .dark ? "#FFFFFF" : "#000000") !important;
                }
                table {
                    width: 100%;
                    border-collapse: collapse;
                    margin-top: 20px;
                }
                th, td {
                    border: 1px solid #ddd;
                    padding: 12px;
                    text-align: left;
                }
                th { font-weight: bold; }
                .ios-spinner {
                    position: relative;
                    width: 40px;
                    height: 40px;
                }
                .spinner-segment {
                    position: absolute;
                    top: 50%;
                    left: 50%;
                    width: 3px;
                    height: 8px;
                    background-color: #3B82F6;
                    border-radius: 2px;
                    opacity: 0.2;
                    transform-origin: center -3px;
                    animation: ios-spinner-fade 1s linear infinite;
                }
                
                @media (prefers-color-scheme: dark) {
                    body {
                        color: #FFFFFF;
                        background-color: transparent;
                    }
                    th, td {
                        border: 1px solid #444;
                    }
                    .spinner-segment {
                        background-color: #FFFFFF;
                    }
                    a {
                        color: #58A6FF;
                    }
                }
                
                .segment-1 { animation-delay: 0s; }
                .segment-2 { animation-delay: 0.125s; transform: rotate(45deg); }
                .segment-3 { animation-delay: 0.25s; transform: rotate(90deg); }
                .segment-4 { animation-delay: 0.375s; transform: rotate(135deg); }
                .segment-5 { animation-delay: 0.5s; transform: rotate(180deg); }
                .segment-6 { animation-delay: 0.625s; transform: rotate(225deg); }
                .segment-7 { animation-delay: 0.75s; transform: rotate(270deg); }
                .segment-8 { animation-delay: 0.875s; transform: rotate(315deg); }
                @keyframes ios-spinner-fade {
                    0%, 87.5% { opacity: 0.2; }
                    12.5% { opacity: 1; }
                }
                """
        }
    }
    
    private func customJavaScript() -> String {
            """
            document.addEventListener('DOMContentLoaded', function() {
                console.log('JavaScript loaded and DOM is ready!');
                
                // Intercept images from specific domain
                const baseUrl = '\(AppConstant.inlineImageBaseUrl)';
                const imgs = document.querySelectorAll('img');
                imgs.forEach((img, index) => {
                    const originalUrl = img.src;
                    if (originalUrl.includes(baseUrl)) {
                        const uniqueId = 'loader-' + index;
                        const placeholder = document.createElement('div');
                        placeholder.id = uniqueId;
                        placeholder.className = 'ios-spinner';
                        placeholder.setAttribute('data-url', originalUrl);
                        for (let i = 1; i <= 8; i++) {
                            const segment = document.createElement('div');
                            segment.className = `spinner-segment segment-${i}`;
                            placeholder.appendChild(segment);
                        }
                        img.replaceWith(placeholder);
                        
                        // Send URL to Swift for fetching
                        window.webkit.messageHandlers.imageUrl.postMessage({
                            id: uniqueId,
                            url: originalUrl
                        });
                    } else {
                        // Add tap handler for non-API images
                        img.onclick = () => {
                            console.log('Non-API image clicked:', originalUrl);
                            window.webkit.messageHandlers.imageTapped.postMessage(originalUrl);
                        };
                    }
                });                
                // Intercept link clicks
                document.body.addEventListener('click', function(e) {
                    const a = e.target.closest('a');
                    if (a && a.href) {
                        e.preventDefault();
                        window.webkit.messageHandlers.linkTapped.postMessage(a.href);
                    }
                });
                
                // Log token availability
                if (typeof authToken !== 'undefined') {
                    console.log('File token available:', authToken);
                } else {
                    console.log('No file token provided');
                }
            });
            
            // Function to replace placeholder with image
            function setImage(id, dataUrl) {
                console.log('setImage called with ID:', id);
                const placeholder = document.getElementById(id);
                if (placeholder) {
                    console.log('Replacing placeholder with ID:', id);
                    const img = document.createElement('img');
                    img.src = dataUrl;
                    img.alt = 'Secure Image';
                    img.style.maxWidth = '100%';
                    img.style.height = 'auto';
                    img.onclick = () => {
                        const originalUrl = placeholder.getAttribute('data-url') || dataUrl;
                        console.log('Image clicked:', originalUrl);
                        window.webkit.messageHandlers.imageTapped.postMessage(originalUrl);
                    };
                    placeholder.replaceWith(img);
                    document.body.dispatchEvent(new Event('resize')); // Trigger layout update
                } else {
                    console.log('Placeholder with ID ' + id + ' not found');
                }
            }
            """
    }
    
    // MARK: - Coordinator
    
    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        var parent: HTMLView
        var processedImageUrls: Set<String> = []
        
        init(_ parent: HTMLView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
                if complete != nil {
                    webView.evaluateJavaScript("document.documentElement.clientHeight", completionHandler: { (height, error) in
                        self.parent.contentHeight = height as! CGFloat
                    })
                }
                
            })
        }
        
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "imageUrl", let body = message.body as? [String: String], let id = body["id"], let urlString = body["url"] {
                if processedImageUrls.contains(urlString) {
                    return // Skip if URL already being processed
                }
                processedImageUrls.insert(urlString)
                
                Task {
                    let base64Image = await ImageFetcher.shared.fetchImage(from: urlString, token: parent.token)
                    let sanitizedBase64Image = base64Image.replacingOccurrences(of: "\n", with: "").replacingOccurrences(of: "\r", with: "")
                    print("Processing image with ID: \(id), URL: \(urlString), Base64 length: \(sanitizedBase64Image.count)")
                    let script = """
                        setImage('\(id)', 'data:image/jpeg;base64,\(sanitizedBase64Image)');
                        """
                    DispatchQueue.main.async {
                        message.webView?.evaluateJavaScript(script) { _, error in
                            if let error = error {
                                print("Error executing setImage: \(error)")
                            } else {
                                print("Successfully called setImage for ID: \(id)")
                                message.webView?.evaluateJavaScript("document.documentElement.scrollHeight") { height, error in
                                    guard error == nil, let height = height as? CGFloat else {
                                        print("Error retrieving height: \(String(describing: error))")
                                        return
                                    }
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                        self.parent.contentHeight = height
                                    }
                                }
                            }
                            self.processedImageUrls.remove(urlString)
                        }
                    }
                }
            } else if message.name == "imageTapped", let url = message.body as? String {
                DispatchQueue.main.async {
                    if let rootVC = UIApplication.shared.connectedScenes
                        .compactMap({ $0 as? UIWindowScene })
                        .first?.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                        
                        var navController: UINavigationController? = nil
                        var currentVC: UIViewController? = rootVC
                        
                        // Traverse through view controller hierarchy to find UINavigationController
                        while currentVC != nil {
                            if let nav = currentVC as? UINavigationController {
                                navController = nav
                                break
                            } else if let tab = currentVC as? UITabBarController {
                                currentVC = tab.selectedViewController
                            } else if let presented = currentVC?.presentedViewController {
                                currentVC = presented
                            } else {
                                currentVC = currentVC?.children.first
                            }
                        }
                        
                        if let navController = navController {
                            let hostingController = UIHostingController(
                                rootView: ImagePreviewView(imageUrl: url, token: self.parent.token)
                            )
                            navController.pushViewController(hostingController, animated: true)
                        }
                    }
                }
            } else if message.name == "linkTapped", let link = message.body as? String {
                if let url = URL(string: link) {
                    handleLinkNavigation(url: url)
                } else {
                    print("Invalid URL: \(link)")
                }
            }
        }
        
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            guard navigationAction.navigationType == .linkActivated, let url = navigationAction.request.url else {
                decisionHandler(.allow)
                return
            }
            
            print("Navigation action for URL: \(url)")
            
            if url == URL(string: "about:blank")! {
                print("Ignoring about:blank navigation")
                decisionHandler(.cancel)
                return
            }
            
            let targetURL = prepareURL(url: url)
            if targetURL.scheme == "https" || ["mailto", "tel"].contains(targetURL.scheme) {
                UIApplication.shared.open(targetURL, options: [:]) { success in
                    if !success {
                        print("Failed to open URL: \(targetURL)")
                    }
                }
                decisionHandler(.cancel)
            } else if UIApplication.shared.canOpenURL(targetURL) {
                UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        }
        
        private func prepareURL(url: URL) -> URL {
            var targetURL = url
            if url.scheme == nil, let httpsURL = URL(string: "https://\(url.absoluteString)") {
                targetURL = httpsURL
            }
            
            if targetURL.scheme == "https", let token = parent.token, var components = URLComponents(url: targetURL, resolvingAgainstBaseURL: false) {
                components.queryItems = (components.queryItems ?? []) + [URLQueryItem(name: "token", value: token)]
                targetURL = components.url ?? targetURL
            }
            return targetURL
        }
        
        private func handleLinkNavigation(url: URL) {
            let targetURL = prepareURL(url: url)
            if ["https", "mailto", "tel"].contains(targetURL.scheme) {
                UIApplication.shared.open(targetURL, options: [:]) { success in
                    if !success {
                        print("Failed to open URL: \(targetURL)")
                    }
                }
            } else if UIApplication.shared.canOpenURL(targetURL) {
                UIApplication.shared.open(targetURL, options: [:], completionHandler: nil)
            } else {
                print("Cannot open URL: \(targetURL)")
            }
        }
    }
}
