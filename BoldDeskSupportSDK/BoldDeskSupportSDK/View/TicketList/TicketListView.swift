import SwiftUI

struct TicketListView: View {
    @StateObject private var ticketListViewModel = TicketListViewModel()
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject var multiSelectViewModel: MultiSelectViewModel
    @State private var showFilterSheet: Bool = false
    @State private var showPopover: Bool = false
    @State private var ticketListNetKey: UUID = UUID()
    @State private var isShowViewDropdown: Bool = false
    @State private var showViewPopover: Bool = false
    @State private var needsRefresh: Bool = false

    init() {
        let vm = TicketListViewModel()
        _ticketListViewModel = StateObject(wrappedValue: vm)
        _multiSelectViewModel = StateObject(
            wrappedValue: MultiSelectViewModel(
                fetchItemsAPI: vm.filterModel.fetchStatuses,
                tempSelectedItems: vm.filterModel.selectedStatuses
            )
        )
    }

    var body: some View {
        AppPage {
            VStack(spacing: 0) {
                CommonAppBar(
                    title: ResourceManager.localized(
                        "allTicketsText",
                        comment: ""
                    ),
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                ) {
                    HStack(spacing: DeviceConfig.isIPhone ? 8 : 12) {

                        NavigationLink(destination: TicketSearchView()) {
                            AppIcon(
                                icon: .search,
                                color: .appBarForegroundColor
                            )
                            .padding(.all, 10)
                        }

                        Button(action: {
                            if DeviceConfig.isIPhone {
                                showFilterSheet = true
                            } else {
                                showPopover = true
                            }
                            multiSelectViewModel.tempSelectedItems =
                                ticketListViewModel.filterModel.selectedStatuses
                            Task {
                                multiSelectViewModel.loadItems(
                                    index: 0,
                                    search: ""
                                )
                            }
                        }) {
                            ZStack(alignment: .topTrailing) {
                                AppIcon(
                                    icon: .filter,
                                    color: .appBarForegroundColor
                                )

                                if ticketListViewModel.filterModel
                                    .hasActiveFilters
                                {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 3, y: -1)
                                }
                            }
                        }
                        .popover(isPresented: $showPopover, arrowEdge: .none) {
                            PopoverMultiPicker(
                                title: ResourceManager.localized(
                                    "filterByStatusText",
                                    comment: ""
                                ),
                                index: 0,
                                updateSelectedItem: ticketListViewModel
                                    .filterModel.updateSelectedStatuses,
                                selectedItems: ticketListViewModel.filterModel
                                    .selectedStatuses,
                                isPresented: $showPopover,
                                multiSelectViewModel: multiSelectViewModel
                            )
                            .presentationCornerRadius(12)
                        }
                        .sheet(isPresented: $showFilterSheet) {
                            BottomSheetMultiPicker(
                                title: ResourceManager.localized(
                                    "filterByStatusText",
                                    comment: ""
                                ),
                                index: 0,
                                updateSelectedItem: ticketListViewModel
                                    .filterModel.updateSelectedStatuses,
                                selectedItems: ticketListViewModel.filterModel
                                    .selectedStatuses,
                                isPresented: $showFilterSheet,
                                multiSelectViewModel: multiSelectViewModel
                            )
                        }.padding(.all, 10)

                    }
                }
                NetworkWrapper {
                    ZStack {
                        if ticketListViewModel.isInitialLoading {
                            TicketListShimmerView()
                        } else if ticketListViewModel.isRefreshing {
                            ScaleSlideAnimatedViewForLoadingContent(
                                content: {
                                    TicketListShimmerView()
                                }
                            )
                        } else {
                            NetworkWrapper {
                                VStack (alignment: .leading, spacing: 0) {
                                    //Ticket View dropdown
                                    TicketFilterDropdownView(
                                        title: ticketListViewModel
                                            .selectedItem?.itemName
                                            ?? "",
                                        onTap: {
                                            if DeviceConfig.isIPhone {
                                                isShowViewDropdown =
                                                    true
                                            } else {
                                                showViewPopover = true
                                            }
                                        }
                                    )
                                    .padding(.top, DeviceConfig.isIPhone ? 14 : 16)
                                    .padding(.bottom, DeviceType.isPhone ? 12 : 16)
                                    .padding(.horizontal, DeviceConfig.isIPhone ? 12 : 16)
                                    .popover(
                                        isPresented: $showViewPopover,
                                        attachmentAnchor: .rect(
                                            .bounds
                                        ),
                                        arrowEdge: .top
                                    ) {
                                        TicketViewItems(
                                            title: "",
                                            isPresented:
                                                $showViewPopover,
                                            updateSelectedItem:
                                                ticketListViewModel
                                                .updateSelectedItem,
                                            selectedItem:
                                                ticketListViewModel
                                                .selectedItem,
                                            dropdownItems:
                                                ticketListViewModel
                                                .getViewItems()
                                        )
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                        .background(
                                            Color.backgroundPrimary
                                        )
                                        .frame(maxWidth: 350)
                                        .padding(OSVersion.isiOS26OrAbove ? 6 : 0)
                                        .background(
                                            Color.backgroundPrimary
                                        )
                                    }
                                PullToRefreshView(
                                    hasNoItems: ticketListViewModel.tickets
                                        .isEmpty,
                                    onRefresh: {
                                        Task {
                                            await ticketListViewModel
                                                .refreshTickets()
                                        }
                                    },
                                    content: {
                                        LazyVStack(
                                            alignment: .leading,
                                            spacing: 12
                                        ) {
                                            ForEach(
                                                Array(
                                                    ticketListViewModel.tickets
                                                        .enumerated()
                                                ),
                                                id: \.offset
                                            ) { index, ticket in
                                                
                                                NavigationLink(
                                                    destination:
                                                        TicketDetailView(
                                                            ticketId: ticket
                                                                .ticketId,
                                                            needsRefresh:
                                                                $needsRefresh,
                                                            canViewMyOrgTickets: ticketListViewModel.canViewMyOrgTickets && ticketListViewModel.selectedItem?.id == 3
                                                        )
                                                ) {
                                                    TicketCardView(
                                                        ticketModel: ticket
                                                    )
                                                    .onChange(
                                                        of: needsRefresh
                                                    ) { newValue in
                                                        Task {
                                                            await
                                                            ticketListViewModel
                                                                .loadInitialTickets()
                                                        }
                                                    }
                                                    .onAppear {
                                                        if index
                                                            == ticketListViewModel
                                                            .tickets.count - 1
                                                            && !ticketListViewModel
                                                            .isLoadingMore
                                                            && !ticketListViewModel
                                                            .isRefreshing
                                                            && !ticketListViewModel
                                                            .isInitialLoading
                                                            && ticketListViewModel
                                                            .canLoadMore
                                                        {
                                                            Task {
                                                                await
                                                                ticketListViewModel
                                                                    .loadMoreTickets()
                                                            }
                                                        }
                                                    }
                                                    
                                                }
                                            }
                                            
                                            if ticketListViewModel.isLoadingMore
                                                && !ticketListViewModel
                                                .isRefreshing
                                            {
                                                LoadingMoreIndicatorView(
                                                    message:
                                                        ResourceManager
                                                        .localized(
                                                            "loadingMoreTicketsText",
                                                            comment: ""
                                                        )
                                                )
                                            }
                                            
                                            if ticketListViewModel
                                                .shouldShowNoMoreItems
                                            {
                                                NoMoreDataView(
                                                    message:
                                                        ResourceManager
                                                        .localized(
                                                            "noMoreDataText",
                                                            comment:
                                                                "No more items to load"
                                                        )
                                                )
                                            }
                                        }
                                        .padding(
                                            .horizontal,
                                            DeviceType.isPhone ? 12 : 20
                                        )
                                        .padding(.bottom, 16)
                                        .background(
                                            Color.backgroundTeritiaryColor
                                        )
                                    },
                                    emptyContent: {
                                        EmptyStateView(
                                            message: ResourceManager.localized(
                                                "noTicketsFoundText",
                                                comment: ""
                                            )
                                        )
                                    }
                                )
                            }
                            }
                        }
                    }
                    .background(
                        DeviceType.isPhone
                            ? Color.backgroundTeritiaryColor
                            : Color.backgroundTeritiaryColor
                    )
                    .onAppear {
                        if ticketListViewModel.tickets.isEmpty
                            && !ticketListViewModel.isInitialLoading
                        {
                            Task {
                                async let tickets: () = ticketListViewModel.loadInitialTickets()
                                async let contactGroup: () = ticketListViewModel.getContactGroups()
                                async let canViewgroup: () = ticketListViewModel.contactGroupsCanViewTickets()
                                _ = await (tickets, contactGroup, canViewgroup)
                            }
                        }
                    }
                    .onChange(of: ticketListViewModel.hasError) { hasError in
                        if hasError {
                            ToastManager.shared.show(
                                ticketListViewModel.errorMessage
                                    ?? "An unknown error occurred",
                                type: .error
                            )
                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + 0.1
                            ) {
                                ticketListViewModel.hasError = false
                            }
                        }
                    }

                }
                PoweredByFooterView()
            }
            .overlay(ToastStackView())

        }
        .bottomSheet(isPresented: $isShowViewDropdown) { dismiss in
            TicketViewItems(
                title:
                    ResourceManager
                    .localized(
                        "viewText",
                        comment: ""
                    ),
                isPresented: $isShowViewDropdown,
                updateSelectedItem: ticketListViewModel.updateSelectedItem,
                selectedItem: ticketListViewModel.selectedItem,
                dropdownItems: ticketListViewModel.getViewItems()
            )
        }
    }
}

struct TicketListShimmerView: View {
    var body: some View {
        NonBouncingScrollView {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(0..<10, id: \.self) { _ in
                        TicketCardShimmer()
                    }
                }
                .padding(.horizontal, DeviceType.isPhone ? 12 : 20)
                .padding(.top, DeviceType.isPhone ? 16 : 24)
                .background(Color.backgroundTeritiaryColor)
            }
        }.ignoresSafeArea(.all, edges: .bottom)
    }
}

struct TicketViewItems: View {
    var title: String
    @Binding var isPresented: Bool
    var updateSelectedItem: (Int, DropdownItemModel?) -> Void
    var selectedItem: DropdownItemModel?
    var dropdownItems: [DropdownItemModel] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title
            if DeviceConfig.isIPhone {
                BottomSliderTitle(titleText: title)
                    .padding(.bottom, 8)
            }
            ForEach(dropdownItems, id: \.id) { item in
                ViewItemButton(
                    title: item.itemName,
                    isSelected: selectedItem == item,
                    action: {
                        updateSelectedItem(item.id, item)
                        isPresented = false
                    }
                )
            }
        }
        .buttonStyle(.plain)
    }
}

struct ViewItemButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(
                        FontFamily.customFont(
                            size: FontSize.large,
                            weight: .medium
                        )
                    )
                Spacer()
            }
            .foregroundColor(.textSecondaryColor)
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .contentShape(Rectangle())  // Makes entire row tappable
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.2)
                : Color.clear
        )
    }
}

struct TicketFilterDropdownView: View {
    let title: String
    var onTap: () -> Void = {}

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut) {
                onTap()
            }
        }) {
            HStack {
                Text(title)
                    .font(
                        FontFamily.customFont(
                            size: FontSize.medium,
                            weight: .semibold
                        )
                    )
                    .foregroundColor(.textSecondaryColor)

                AppIcon(
                    icon: .chevronDown,
                    size: 20,
                    color: Color.buttonSecondaryColor
                )
            }
            .padding(.bottom, DeviceConfig.isIPhone ? 2 : 0)
            .padding(.horizontal, DeviceConfig.isIPhone ? 2 : 4)
            .background(Color.backgroundTeritiaryColor)
        }
        .buttonStyle(PlainButtonStyle())  // Removes default button styling
    }
}

#Preview {
    TicketListView()
}
