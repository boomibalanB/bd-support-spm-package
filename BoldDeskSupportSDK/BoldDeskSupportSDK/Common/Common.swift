internal import SDWebImageSwiftUI
import SwiftUI
import WebKit

struct Devider: View {
    var color: Color? = Color.borderSecondaryColor
    var body: some View {
        Rectangle()
            .frame(height: 1)
            .foregroundColor(color)
    }
}

func formattedSizeRounded(from bytes: Int64) -> String {
    let kb = Double(bytes) / 1024
    let mb = kb / 1024
    let gb = mb / 1024

    if gb >= 1 {
        return String(format: "%.2f GB", gb)
    } else if mb >= 1 {
        return String(format: "%.2f MB", mb)
    } else {
        return String(format: "%.2f KB", kb)
    }
}

func bytesToMegabytes(_ bytes: Int64) -> Double {
    return Double(bytes) / 1_048_576
}

struct LoadingDownIcon: View {
    var isLoading: Bool
    @State private var isAnimating = false

    var body: some View {
        ZStack {
            // Rotating arc always in layout, just hidden when not loading
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(Color.blue, lineWidth: 3)
                .frame(width: 25, height: 25)
                .rotationEffect(.degrees(isAnimating ? 360 : 0))
                .opacity(isLoading ? 1 : 0)
                .onAppear {
                    withAnimation(
                        Animation.linear(duration: 1).repeatForever(
                            autoreverses: false
                        )
                    ) {
                        isAnimating = true
                    }
                }

            // Chevron always in center
            AppIcon(icon: .chevronDown)
        }
        .frame(width: 30, height: 30)
        .padding(.trailing, 16)
    }
}

struct FormCheckBox: View {
    var isChecked: Bool
    var icon: AppIcons = .tick24
    var size: CGFloat = 20
    var iconSize: CGFloat = 18
    var cornerRadius: CGFloat = 3

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(
                    isChecked ? Color.clear : Color.buttonSecondaryBorderColor,
                    lineWidth: 1.5
                )
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(isChecked ? Color.accentColor : Color.clear)
                )
                .frame(width: size, height: size)

            if isChecked {
                AppIcon(
                    icon: icon,
                    size: iconSize,
                    color: .filledButtonForegroundColor
                )
            }
        }
    }
}

func toUTCDateTime(
    from input: String,
    inputFormat: String = "yyyy-MM-dd HH:mm:ss",
    outputFormat: String = "yyyy-MM-dd HH:mm:ss"
) -> String? {
    let formatter = DateFormatter()
    formatter.dateFormat = inputFormat
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone.current

    if let date = formatter.date(from: input) {
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        formatter.dateFormat = outputFormat
        return formatter.string(from: date)
    }
    return nil
}

func toLocal(
    from utcString: String,
    inputFormat: String = "yyyy-MM-dd HH:mm:ss"
) -> String? {
    let formatter = DateFormatter()
    formatter.dateFormat = inputFormat
    formatter.timeZone = TimeZone(abbreviation: "UTC")

    if let date = formatter.date(from: utcString) {
        formatter.timeZone = TimeZone.current
        return formatter.string(from: date)
    }
    return nil
}

func convertUTCToLocalDateTime(
    dateString: String,
    inputFormat: String = "yyyy-MM-dd'T'HH:mm:ssZ",
    outputFormat: String = "yyyy-MMM-dd, h:mm a"
) -> String {
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = inputFormat
    dateFormatter.timeZone = TimeZone(abbreviation: "UTC")

    guard let date = dateFormatter.date(from: dateString) else {
        return dateString  // fallback if parsing fails
    }

    dateFormatter.timeZone = TimeZone.current
    dateFormatter.dateFormat = outputFormat
    return dateFormatter.string(from: date)
}

func convertDateToLocalDate(
    _ dateString: String,
    inputFormat: String = "yyyy-MM-dd",
    outputFormat: String = "yyyy-MMM-dd"
) -> String {
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")  // Ensures month in English letters
    formatter.dateFormat = inputFormat
    formatter.timeZone = TimeZone(secondsFromGMT: 0)  // Input date is in UTC

    guard let date = formatter.date(from: dateString) else {
        return dateString
    }

    formatter.timeZone = TimeZone.current
    formatter.dateFormat = outputFormat
    return formatter.string(from: date)
}

struct CircleLoadingIndicatorView: View {
    var body: some View {
        Color.black.opacity(0.4)  // Transparent gray background
            .edgesIgnoringSafeArea(.all)  // Covers the entire screen including safe areas
            .overlay(
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(
                            CircularProgressViewStyle(tint: Color.accentColor)
                        )
                        .scaleEffect(2)
                    Spacer()
                }
            )
    }
}

struct AdaptiveDivider: View {
    var isDashed: Bool = true
    var height: CGFloat = 1

    var body: some View {
        DottedLine()
            .stroke(
                strokeColor,
                style: StrokeStyle(
                    lineWidth: height,
                    dash: isDashed ? [5, 5] : []
                )
            )
            .frame(height: height)
    }

    private var strokeColor: Color {
        if DeviceConfig.isIPhone {
            return Color.borderSecondaryColor
        } else {
            return isDashed ? Color.clear : Color.borderSecondaryColor
        }
    }
}

struct CircleAvatar: View {
    let initials: String
    let backgroundColor: Color

    var body: some View {
        Text(initials)
            .font(
                FontFamily.customFont(size: FontSize.medium, weight: .semibold)
            )

            .foregroundColor(.shortCodeTextColor)
            .frame(width: 32, height: 32)
            .background(backgroundColor)
            .clipShape(Circle())
    }
}

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.backgroundOverlayColor
                .edgesIgnoringSafeArea(.all)

            ProgressView()
                .progressViewStyle(
                    CircularProgressViewStyle(tint: .accentColor)
                )
                .scaleEffect(1.5)
        }
    }
}

private class BundleLocator {}

extension Bundle {
    static var framework: Bundle {
        return Bundle(for: BundleLocator.self)
    }
}

// MARK: - Cache for SVG strings
class SVGCache {
    static let shared = SVGCache()
    private var cache: [URL: String] = [:]
    func svgString(for url: URL) -> String? { cache[url] }
    func set(svg: String, for url: URL) { cache[url] = svg }
}

// MARK: - Main Image View
struct SVGLogoView: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.backgroundColor = .clear
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        if url.pathExtension.lowercased() == "svg" {
            // ✅ Handle SVG
            loadSVG(in: uiView)
        } else {
            // 🖼️ Handle normal image (PNG/JPG/GIF etc.)
            let html = """
                <html>
                  <head>
                    <meta name="viewport" content="width=device-width, initial-scale=1.0">
                    <style>
                      body { margin: 0; padding: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; }
                      img { width: 100%; height: 100%; object-fit: contain; overflow: hidden; }
                    </style>
                  </head>
                  <body>
                    <img src="\(url.absoluteString)" />
                  </body>
                </html>
                """
            uiView.loadHTMLString(html, baseURL: nil)
        }
    }

    // MARK: - SVG Loader
    private func loadSVG(in uiView: WKWebView) {
        if let cached = SVGCache.shared.svgString(for: url) {
            uiView.loadHTMLString(wrapSVG(cached), baseURL: nil)
        } else {
            DispatchQueue.global().async {
                do {
                    let svgString = try String(contentsOf: url, encoding: .utf8)
                    SVGCache.shared.set(svg: svgString, for: url)
                    DispatchQueue.main.async {
                        uiView.loadHTMLString(wrapSVG(svgString), baseURL: nil)
                    }
                } catch {
                    print("⚠️ Failed to load SVG: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - HTML Wrapper for SVG
    private func wrapSVG(_ svg: String) -> String {
        """
        <html>
          <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0">
            <style>
              body { margin: 0; padding: 0; background: transparent; display: flex; justify-content: center; align-items: center; height: 100vh; }
              svg { width: 100%; height: 100%; overflow: hidden; }
            </style>
          </head>
          <body>
            \(svg)
          </body>
        </html>
        """
    }
}

struct NetworkImageViewForKB: View {
    let imageUrl: String?

    private var isValidURL: Bool {
        guard let imageUrl, let url = URL(string: imageUrl) else {
            return false
        }
        return url.scheme?.hasPrefix("http") == true
    }

    var body: some View {
        ZStack {
            if !isValidURL || imageUrl?.isEmpty ?? true {
                defaultIconView()
            } else {
                // ✅ Valid URL → try to load network image
                WebImage(url: URL(string: imageUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    defaultIconView()
                }
                .onSuccess { image, data, cacheType in

                }
                .indicator(.activity)  // Activity Indicator
                .transition(.fade(duration: 0.5))  // Fade Transition with duration
                .frame(width: 35, height: 35)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(Color.borderSecondaryColor, lineWidth: 2)
                )
            }
        }
    }

    private func defaultIconView() -> some View {
        return AppIcon(icon: .fileText, color: Color.shortCodeTextColor)
            .frame(width: 35, height: 35)
            .background(Color.purple)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(Color.borderSecondaryColor, lineWidth: 2)
            )
    }
}

struct NetworkImageViewForHome: View {
    let imageUrl: String?

    private var isValidURL: Bool {
        guard let imageUrl, let url = URL(string: imageUrl) else {
            return false
        }
        return url.scheme?.hasPrefix("http") == true
    }

    var body: some View {
        ZStack {
            if !isValidURL || imageUrl?.isEmpty ?? true {
                defaultIconView()
            } else {
                // ✅ Valid URL → try to load network image
                WebImage(url: URL(string: imageUrl ?? "")) { image in
                    image.resizable()
                } placeholder: {
                    defaultIconView()
                }
                .onSuccess { image, data, cacheType in

                }
                .indicator(.activity)  // Activity Indicator
                .transition(.fade(duration: 0.5))  // Fade Transition with duration
                .frame(width: 32, height: 32)
            }
        }
    }

    private func defaultIconView() -> some View {
        Group {
            if let url = Bundle.framework.url(forResource: "bolddeskLogo", withExtension: "svg") {
                SVGLogoView(url: url)
                    .frame(width: 32, height: 32)
            } else {
                EmptyView()
            }
        }
    }
}

struct BottomSliderTitle: View {
    let titleText: String

    var body: some View {
        Text(ResourceManager.localized(titleText, comment: ""))
            .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
            .foregroundColor(.textPrimary)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .lineLimit(1)
            .truncationMode(.tail)
    }
}

@propertyWrapper
struct Preference<T> {
    let key: String
    let defaultValue: T
    var container: UserDefaults = .standard
    
    var wrappedValue: T {
        get { container.object(forKey: key) as? T ?? defaultValue }
        set { container.set(newValue, forKey: key) }
    }
}

struct AttachmentButton: View {
    // Callback closure
    var onTap: () -> Void

    var body: some View {
        Button(action: {
            onTap() // Execute the callback
        }) {
            HStack(spacing: 0) {
                AppIcon(icon: .attachment, size: 24)
                    .padding(.trailing, 12)
                
                Text("Attach file")
                    .foregroundColor(Color.accentColor)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                
                Text(" (up to \(AppConstant.maxFileSizeInMB)MB)")
                    .foregroundColor(Color.textSecondaryColor)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
            }
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                    .foregroundColor(Color.buttonSecondaryBorderColor)
            )
            .padding(.horizontal, 12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SingleLineTextAndLink: View {
    
    var text: String
    var ticketId: String
    var link: String
    
    var body: some View {
        
        let placeholder = "{{ticket.link}}"
        
        if text.contains(placeholder) {
            
            let parts = text.components(separatedBy: placeholder)
            let prefix = parts.first ?? ""
            let suffix = parts.count > 1 ? parts[1] : ""
            
            (
                Text(prefix)
                +
                Text("\(ticketId)")
                    .foregroundColor(.blue)
                    .underline()
                +
                Text(suffix)
            )
            .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
            .lineLimit(nil)
            .multilineTextAlignment(.leading)
            
            // 👇 Tap only on link (approximation)
            .onTapGesture {
                BDSupportSDK.onTicketCreatedEventCallBack?(ticketId, link)
            }
            
        } else {
            Text(text)
                .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
        }
    }
}
