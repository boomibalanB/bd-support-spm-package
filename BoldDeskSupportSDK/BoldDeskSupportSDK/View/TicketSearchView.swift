import SwiftUI

struct TicketSearchView: View {
    @StateObject private var viewModel = TicketSearchViewModel()
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    var body: some View {
        AppPage(){
            VStack(spacing: 0) {
                CommonAppBarCustom {
                    TicketSearchAppBar(
                        searchText: $viewModel.searchText,
                        onBack: {
                            presentationMode.wrappedValue.dismiss()
                        },
                        onSearch: {
                            viewModel.searchTickets()
                        },
                        onClear: {
                            viewModel.clearSearch()
                        },
                        onFilter: {
                            viewModel.openFilter()
                        },
                        placeholder: ResourceManager.localized("searchTicketsInText", comment: "")
                    )
                }
                ZStack {
                    Color.backgroundPrimary
                        .ignoresSafeArea()
                    if viewModel.isSearching {
                        TicketSearchShimmerView()
                    } else if !viewModel.hasSearched {
                        TicketSearchInitialView()
                    } else if viewModel.isRefreshing {
                        ScaleSlideAnimatedViewForLoadingContent(
                            content: {
                                TicketSearchShimmerView()
                            }
                        )
                    } else {
                        NetworkWrapper {
                            PullToRefreshView(
                                hasNoItems: viewModel.tickets.isEmpty,
                                onRefresh: viewModel.refreshTickets,
                                content: {
                                    TicketSearchResultsView(viewModel: viewModel)
                                },
                                emptyContent: {
                                    EmptyStateView(message: ResourceManager.localized("noTicketsFoundSearchText", comment: ""), backgroundColor: .cardBackgroundPrimary)
                                },
                                backgroundColor: Color.backgroundPrimary
                            )
                        }
                    }
                }
                if !(keyboardObserver.isKeyboardVisible) {
                    PoweredByFooterView()
                }
            }
            .navigationBarHidden(true)
            .onChange(of: viewModel.hasError) { hasError in
                if hasError {
                    ToastManager.shared.show(viewModel.errorMessage ?? "An unknown error occurred", type: .error)
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        viewModel.hasError = false
                    }
                }
            }
            .overlay(ToastStackView())
        }
    }
}

struct TicketSearchInitialView: View {
    var body: some View {
        VStack(spacing: 16) {
            Text(ResourceManager.localized("searchTicketInitialText", comment: ""))
                .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                
                .foregroundColor(.textTeritiaryColor)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

struct TicketSearchResultsView: View {
    @ObservedObject var viewModel: TicketSearchViewModel
    
    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(viewModel.tickets.enumerated()), id: \.offset) { index, ticket in
                VStack(spacing: 0) {
                    NavigationLink(destination: TicketDetailView(ticketId: ticket.ticketId, isFromSearchPage: true)) {
                        TicketSearchItemView(searchModel: ticket)
                            .onAppear {
                                if index == viewModel.tickets.count - 1 &&
                                    !viewModel.isLoadingMore &&
                                    !viewModel.isSearching &&
                                    !viewModel.isRefreshing &&
                                    viewModel.canLoadMore {
                                    viewModel.loadMoreTickets()
                                }
                            }
                    }
                    
                    if index != viewModel.tickets.count - 1 {
                        AdaptiveDivider(isDashed: false)
                    }
                }
            }
            
            if viewModel.isLoadingMore {
                LoadingMoreIndicatorView(message: ResourceManager.localized("loadingMoreTicketsText", comment: ""))
            }
            
            if viewModel.shouldShowNoMoreItems {
                NoMoreDataView(message: ResourceManager.localized("noMoreDataText", comment: "No more items to load"))
            }
        }
        .padding(.bottom, 16)

    }
}

struct TicketSearchShimmerView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(0..<10, id: \.self) { index in
                    TicketSearchItemShimmerView()
                    
                    if index != 9 {
                        AdaptiveDivider(isDashed: false)
                    }
                }
            }
        }
    }
}

struct TicketSearchAppBar: View {
    @Binding var searchText: String
    var onBack: () -> Void
    var onSearch: () -> Void
    var onClear: () -> Void
    var onFilter: () -> Void
    var placeholder: String = ""
    
    var body: some View {
        HStack(spacing: 0) {
            Button(action: {
                onBack()
            }) {
                AppIcon(icon: .chevronLeft, size: DeviceConfig.isIPhone ? 24 : 26, color: .appBarForegroundColor)
            }
            .frame(width: DeviceConfig.isIPhone ? 20 : 22, height: DeviceConfig.isIPhone ? 20 : 22)
            .padding(.trailing, 8)
            
            HStack(spacing: 8) {
                ZStack(alignment: .leading) {
                    Text(placeholder)
                        .font(FontFamily.customFont(size: DeviceConfig.isIPhone ? FontSize.medium : FontSize.large, weight: .medium))
                        .foregroundColor(
                            .appBarSeachBoxPlaceHolderColor
                        )
                        .opacity(searchText.isEmpty ? 1 : 0)
    
                    TextField("", text: $searchText)
                        .font(FontFamily.customFont(size: DeviceConfig.isIPhone ? FontSize.medium : FontSize.large, weight: .medium))
                        .foregroundColor(
                            .appBarSeachBoxTextColor
                        )
                        .onChange(of: searchText) { newValue in
                            onSearch()
                        }
                }
                
                if !searchText.isEmpty {
                    Button(action: {
                        onClear()
                    }) {
                        Text(ResourceManager.localized("clearText", comment: ""))
                            .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                            
                            .foregroundColor(.appBarForegroundColor)
                    }
                }
            }
        }
    }
}
