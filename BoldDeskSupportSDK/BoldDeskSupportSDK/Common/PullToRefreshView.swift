import SwiftUI

struct PullToRefreshView<Content: View, EmptyContent: View>: View {
    let content: Content
    let emptyContent: EmptyContent
    let onRefresh: () -> Void
    let hasNoItems: Bool
    var backgroundColor: Color? = nil

    @State private var refresh = Refresh(started: false, released: false, isInvalid: false)

    // Pull progress calculation
    private var pullProgress: Double {
        let maxPullDistance: CGFloat = 80
        let currentPull = max(0, refresh.offset - refresh.startOffset)
        return min(1.0, Double(currentPull / maxPullDistance))
    }

    init(
        hasNoItems: Bool,
        onRefresh: @escaping () -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder emptyContent: () -> EmptyContent,
        backgroundColor: Color? = nil,
    ) {
        self.hasNoItems = hasNoItems
        self.backgroundColor = backgroundColor
        self.onRefresh = onRefresh
        self.content = content()
        self.emptyContent = emptyContent()
    }

    var body: some View {
        if hasNoItems {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    GeometryReader { reader -> AnyView in
                        DispatchQueue.main.async {
                            if refresh.startOffset == 0 {
                                refresh.startOffset = reader.frame(in: .global).minY
                            }
                            refresh.offset = reader.frame(in: .global).minY

                            if pullProgress >= 1.0 && !refresh.started {
                                refresh.started = true
                                withAnimation(.linear) {
                                    refresh.released = true
                                }
                                onRefresh()
                            }

                            if refresh.startOffset == refresh.offset && refresh.started && refresh.released && refresh.isInvalid {
                                withAnimation(.linear) {
                                    refresh.isInvalid = false
                                }
                                onRefresh()
                            }
                        }

                        return AnyView(Color.clear.frame(width: 0, height: 0))
                    }

                    ZStack(alignment: .top) {
                        emptyContent
                            .frame(minHeight: geometry.size.height)

                        RefreshIndicatorView(
                            progress: pullProgress,
                            isRefreshing: refresh.started && refresh.released
                        )
                        .offset(y: -40)
                    }
                    .offset(y: refresh.released ? 40 : -16)
                }
                .background(backgroundColor ?? Color.backgroundTeritiaryColor)
            }.ignoresSafeArea(.all, edges: .bottom)
        } else {
            // Version 1-style layout (simpler, no outer GeometryReader)
            ScrollView(.vertical, showsIndicators: false) {
                GeometryReader { reader -> AnyView in
                    DispatchQueue.main.async {
                        if refresh.startOffset == 0 {
                            refresh.startOffset = reader.frame(in: .global).minY
                        }
                        refresh.offset = reader.frame(in: .global).minY

                        if pullProgress >= 1.0 && !refresh.started {
                            refresh.started = true
                            withAnimation(.linear) {
                                refresh.released = true
                            }
                            onRefresh()
                        }

                        if refresh.startOffset == refresh.offset && refresh.started && refresh.released && refresh.isInvalid {
                            withAnimation(.linear) {
                                refresh.isInvalid = false
                            }
                            onRefresh()
                        }
                    }

                    return AnyView(Color.clear.frame(width: 0, height: 0))
                }

                ZStack(alignment: .top) {
                    content

                    RefreshIndicatorView(
                        progress: pullProgress,
                        isRefreshing: refresh.started && refresh.released
                    )
                    .offset(y: -40)
                }
                .offset(y: refresh.released ? 40 : -16)
            }
            .background(backgroundColor ?? Color.backgroundTeritiaryColor)
            .ignoresSafeArea(.all, edges: .bottom)
        }
    }

    // Call this when the refresh completes
    func stopRefreshing() {
        withAnimation(.linear) {
            refresh.started = false
            refresh.released = false
            refresh.isInvalid = false
        }
    }
}


// MARK: - Refresh Indicator Component
struct RefreshIndicatorView: View {
    let progress: Double
    let isRefreshing: Bool
    
    var body: some View {
        ZStack {
            if isRefreshing {
                // Show default spinning progress when refreshing
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
            } else {
                // Show segmented progress ring with dashes
                SegmentedCircularProgressView(progress: progress)
            }
        }
        .frame(width: 20, height: 20) // Fixed frame to prevent jumping
        .opacity(progress > 0.1 ? 1 : 0)
    }
}

// MARK: - Segmented Circular Progress View
struct SegmentedCircularProgressView: View {
    let progress: Double
    let numberOfSegments: Int = 8
    
    var body: some View {
        ZStack {
            ForEach(0..<numberOfSegments, id: \.self) { index in
                let angle = Double(index) * (360.0 / Double(numberOfSegments))
                let shouldShow = Double(index) < (progress * Double(numberOfSegments))
                
                RoundedRectangle(cornerRadius: 10)
                    .fill(shouldShow ? Color.accentColor : Color.gray.opacity(0.25))
                    .frame(width: 2.5, height: 6.5)
                    .offset(y: -7)
                    .rotationEffect(.degrees(angle))
                    .animation(.easeOut(duration: 0.1), value: shouldShow)
            }
        }
        .frame(width: 20, height: 20)
    }
}

struct Refresh {
    var startOffset: CGFloat = 0
    var offset: CGFloat = 0
    var started: Bool
    var released: Bool
    var isInvalid: Bool
}


struct ScaleSlideAnimatedViewForLoadingContent<Content: View>: View {
    let content: Content
    @State private var animationOffset: CGFloat = 80
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .offset(y: animationOffset)
            .onAppear {
                withAnimation(.easeOut(duration: 0.4)) {
                    animationOffset = 0
                }
            }
            .onDisappear {
                animationOffset = 80
            }
    }
}


struct NonBouncingScrollView<Content: View>: UIViewRepresentable {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    func makeUIView(context: Context) -> UIScrollView {
        let scrollView = UIScrollView()
        scrollView.bounces = false
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false

        let hosting = UIHostingController(rootView: content)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false

        scrollView.addSubview(hosting.view)

        NSLayoutConstraint.activate([
            hosting.view.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            hosting.view.topAnchor.constraint(equalTo: scrollView.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            hosting.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])

        return scrollView
    }

    func updateUIView(_ uiView: UIScrollView, context: Context) {
        if let hostingController = uiView.subviews.first?.next as? UIHostingController<Content> {
            hostingController.rootView = content
        }
    }
}

struct EmptyStateView: View {
    let message: String
    var backgroundColor: Color? = nil

    var body: some View {
        VStack {
            Spacer()
            Text(message)
                .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                .foregroundColor(.textSecondaryColor)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundColor ?? Color.backgroundTeritiaryColor)
    }
}

struct LoadingMoreIndicatorView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Spacer()
                ProgressView()
                    .scaleEffect(0.8)
                Text(message)
                    .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
                    
                    .foregroundColor(.textTeritiaryColor)
                Spacer()
            }
            .padding()
        }
    }
}

struct NoMoreDataView: View {
    let message: String

    var body: some View {
        Text(message)
            .font(FontFamily.customFont(size: FontSize.small, weight: .medium))
            
            .foregroundColor(.textTeritiaryColor)
            .padding(.vertical, 12)
    }
}

struct NestedRefreshableScrollView<Content: View, EmptyContent: View, TopContent: View>: View {
    let content: Content
    let emptyContent: EmptyContent
    let topContent: TopContent
    let onRefresh: () -> Void
    let onScrollOffsetChange: (CGFloat) -> Void
    let hasNoItems: Bool

    @State private var refresh = Refresh(started: false, released: false, isInvalid: false)

    // Pull progress calculation
    private var pullProgress: Double {
        let maxPullDistance: CGFloat = 80
        let currentPull = max(0, refresh.offset - refresh.startOffset)
        return min(1.0, Double(currentPull / maxPullDistance))
    }

    init(
        hasNoItems: Bool,
        onRefresh: @escaping () -> Void,
        onScrollOffsetChange: @escaping (CGFloat) -> Void,
        @ViewBuilder content: () -> Content,
        @ViewBuilder emptyContent: () -> EmptyContent,
        @ViewBuilder topContent: () -> TopContent
    ) {
        self.hasNoItems = hasNoItems
        self.onRefresh = onRefresh
        self.onScrollOffsetChange = onScrollOffsetChange
        self.content = content()
        self.emptyContent = emptyContent()
        self.topContent = topContent()
    }

    var body: some View {
        if hasNoItems {
            GeometryReader { geometry in
                ScrollView(.vertical, showsIndicators: false) {
                    VStack (spacing: 0){
                        Color.clear
                            .frame(width: 0, height: 0)
                            .background(scrollOffsetReader())
                        Color.clear
                            .frame(width: 0, height: 0)
                            .background(
                                GeometryReader { reader -> AnyView in
                                    DispatchQueue.main.async {
                                        if refresh.startOffset == 0 {
                                            refresh.startOffset = reader.frame(in: .global).minY
                                        }
                                        refresh.offset = reader.frame(in: .global).minY

                                        if pullProgress >= 1.0 && !refresh.started {
                                            refresh.started = true
                                            withAnimation(.linear) {
                                                refresh.released = true
                                            }
                                            onRefresh()
                                        }

                                        if refresh.startOffset == refresh.offset && refresh.started && refresh.released && refresh.isInvalid {
                                            withAnimation(.linear) {
                                                refresh.isInvalid = false
                                            }
                                            onRefresh()
                                        }
                                    }

                                    return AnyView(Color.clear.frame(width: 0, height: 0))
                                }
                            )
                        topContent
                        ZStack(alignment: .top) {
                            emptyContent
                                .frame(minHeight: geometry.size.height - (DeviceConfig.isIPhone ? 238 : 172))

                            RefreshIndicatorView(
                                progress: pullProgress,
                                isRefreshing: refresh.started && refresh.released
                            )
                            .offset(y: -40)
                        }
                        .offset(y: refresh.released ? 40 : 0)
                    }
                }
                .background(Color.backgroundTeritiaryColor)
            }.ignoresSafeArea(.all, edges: .bottom)
            .coordinateSpace(name: "broScroll")
        } else {
            ScrollView(.vertical, showsIndicators: false) {
                VStack (spacing: 0){
                    Color.clear
                                        .frame(width: 0, height: 0)
                                        .background(scrollOffsetReader())
                    Color.clear
                        .frame(width: 0, height: 0)
                        .background(
                            GeometryReader { reader -> AnyView in
                                DispatchQueue.main.async {
                                    if refresh.startOffset == 0 {
                                        refresh.startOffset = reader.frame(in: .global).minY
                                    }
                                    refresh.offset = reader.frame(in: .global).minY

                                    if pullProgress >= 1.0 && !refresh.started {
                                        refresh.started = true
                                        withAnimation(.linear) {
                                            refresh.released = true
                                        }
                                        onRefresh()
                                    }

                                    if refresh.startOffset == refresh.offset && refresh.started && refresh.released && refresh.isInvalid {
                                        withAnimation(.linear) {
                                            refresh.isInvalid = false
                                        }
                                        onRefresh()
                                    }
                                }

                                return AnyView(Color.clear.frame(width: 0, height: 0))
                            }
                        )
                    topContent
                    ZStack(alignment: .top) {
                        content
                        RefreshIndicatorView(
                            progress: pullProgress,
                            isRefreshing: refresh.started && refresh.released
                        )
                        .offset(y: -40)
                    }
                    .offset(y: refresh.released ? 40 : 0)
                }
            }
            .background(Color.backgroundTeritiaryColor)
            .ignoresSafeArea(.all, edges: .bottom)
            .coordinateSpace(name: "broScroll")
        }
    }

    func stopRefreshing() {
        withAnimation(.linear) {
            refresh.started = false
            refresh.released = false
            refresh.isInvalid = false
        }
    }
    
    // Helper view to detect scroll offset and trigger callback
        @ViewBuilder
        private func scrollOffsetReader() -> some View {
            Color.clear
                .frame(height: 0)
                .background(
                    GeometryReader { reader in
                        let frame = reader.frame(in: .named("broScroll"))
                        Color.clear
                            .onAppear {
                                onScrollOffsetChange(frame.minY)
                            }
                            .onChange(of: frame.minY) { newValue in
                                onScrollOffsetChange(newValue)
                            }
                    }
                )
        }
}


struct GeometryGetter: View {
    @Binding var refresh: Refresh
    let onRefresh: () async -> Void
    
    private let maxPullDistance: CGFloat = 80
    @State private var hasReachedMaxDistance = false
    @State private var isDragging = false

    private var pullProgress: Double {
        let currentPull = max(0, refresh.offset - refresh.startOffset)
        return min(1.0, Double(currentPull / maxPullDistance))
    }

    var body: some View {
        GeometryReader { geometry in
            self.makeView(geometry: geometry)
        }
    }

    func makeView(geometry: GeometryProxy) -> some View {
        DispatchQueue.main.async {
            let minY = geometry.frame(in: .global).minY
            
            if refresh.startOffset == 0 {
                refresh.startOffset = minY
            }
            refresh.offset = minY
            
            let pullDistance = refresh.offset - refresh.startOffset
            
            // Detect drag start & progress
            if pullDistance > 0 {
                if !isDragging { isDragging = true }
                if pullDistance >= maxPullDistance {
                    hasReachedMaxDistance = true
                }
            }
            
            // Detect release
            if isDragging && pullDistance <= 0 {
                if hasReachedMaxDistance && !refresh.started {
                    triggerRefresh()
                }
                isDragging = false
                hasReachedMaxDistance = false
            }
        }
        
        return Rectangle().fill(Color.clear)
    }
    
    private func triggerRefresh() {
        refresh.started = true
        withAnimation(.linear) {
            refresh.released = true
        }
        Task {
            await onRefresh()
            stopRefreshing()
        }
    }
    
    private func stopRefreshing() {
        withAnimation(.linear) {
            refresh.started = false
            refresh.released = false
            refresh.isInvalid = false
        }
    }
}
