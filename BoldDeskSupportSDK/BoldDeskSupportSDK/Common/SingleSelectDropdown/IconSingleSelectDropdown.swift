import SwiftUI

struct IconButtonSingleSelectDropdown: View {
    let icon: AppIcons
    var updateSelectedItem: (Int, DropdownItemModel?) -> Void
    var selectedItem: DropdownItemModel?
    var fetchItems: (Int, String) async -> [DropdownItemModel]
    var hideResetButton: Bool = false
    var onTap: (() -> Void)? = nil
    @State private var showPicker: Bool = false
    @State private var showPopover: Bool = false
    @StateObject var singleSelectViewModel: SingleSelectViewModel
    
    init(icon: AppIcons, updateSelectedItem: @escaping (Int, DropdownItemModel?) -> Void, selectedItem: DropdownItemModel? = nil, fetchItems: @escaping (Int, String) async -> [DropdownItemModel], hideResetButton: Bool, onTap: (() -> Void)? = nil) {
        self.icon = icon
        self.updateSelectedItem = updateSelectedItem
        self.selectedItem = selectedItem
        self.fetchItems = fetchItems
        self.hideResetButton = hideResetButton
        self.onTap = onTap
        _singleSelectViewModel = StateObject(wrappedValue: SingleSelectViewModel(fetchItemsAPI: fetchItems, selectedItem: selectedItem))
    }
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button(action: {
                if DeviceType.isPhone {
                    showPicker = true
                } else {
                    showPopover = true
                }
                Task {
                    onTap?()
                    singleSelectViewModel.selectedItem = selectedItem
                    await singleSelectViewModel.loadItems(index: 0, search: "")
                }
            }) {
                AppIcon(icon: .filter, size: 20, color: .appBarForegroundColor)
            }

            if selectedItem != nil {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: 2, y: -2) // Adjust position as needed
            }
        }
        .popover(isPresented: $showPopover, arrowEdge: .none) {
            PopoverSinglePicker(
                updateSeelectedItem: updateSelectedItem,
                selectedItem: selectedItem,
                isPresented: $showPopover,
                singleSelectViewModel: singleSelectViewModel
            )
        }
        .sheet(isPresented: $showPicker) {
            BottomSheetSinglePicker(
                title: "Category",
                index: 0,
                hideResetButton: hideResetButton,
                updateSeelectedItem: updateSelectedItem,
                selectedItem: selectedItem,
                isPresented: $showPicker,
                singleSelectViewModel: singleSelectViewModel
            )
        }
    }

}
