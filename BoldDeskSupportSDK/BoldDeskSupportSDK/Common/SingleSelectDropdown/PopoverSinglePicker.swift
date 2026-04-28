import SwiftUI

struct PopoverSinglePicker: View {
    var updateSeelectedItem: (Int, DropdownItemModel?) -> Void
    var selectedItem: DropdownItemModel?
    @Binding var isPresented: Bool
    @ObservedObject var singleSelectViewModel: SingleSelectViewModel
    var index: Int = 0 // Assuming `index` is used in `updateSeelectedItem`

    var body: some View {
        VStack (spacing: 0) {
            DropdownSearchField.small { searchText in
                Task {
                    await singleSelectViewModel.loadItems(index: index, search: searchText)
                }
            }
            .padding(.horizontal, 2)

            ZStack {
                if singleSelectViewModel.isLoading {
                    loadingView
                } else if !singleSelectViewModel.items.isEmpty {
                    itemsScrollView
                } else {
                    noResultView
                }
            }
        }
        .padding(.bottom, 8)
        .background(Color.cardBackgroundPrimary)
        .frame(minWidth: 300, maxWidth: 300, minHeight: 200, maxHeight: 400)
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                .scaleEffect(2)
            Spacer()
        }
        .background(Color.clear)
    }

    private var itemsScrollView: some View {
        ScrollView {
            ForEach(singleSelectViewModel.items, id: \.id) { item in
                Button(action: {
                    updateSeelectedItem(index, item)
                    isPresented = false
                }) {
                    HStack {
                        Text(item.displayName)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .foregroundColor(Color.textPrimary)
                            .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                            .lineLimit(3)
                            .truncationMode(.tail)
                            .multilineTextAlignment(.leading)
                            
                    }
                    .padding(.horizontal, DeviceType.isPhone ? 16 : 14)
                    .padding(.vertical, DeviceType.isPhone ? 16 : 8)
                    .background(
                        selectedItem == item
                        ? Color.accentColor.opacity(0.2)
                        : Color.clear
                    )
                }
            }
        }
    }

    private var noResultView: some View {
        VStack {
            Spacer()
            Text("noResultText")
                .foregroundColor(Color.textPrimary)
                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
