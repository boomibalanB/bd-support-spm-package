import SwiftUI

struct BottomSheetMultiPicker: View {
    var title: String
    var index: Int
    var updateSelectedItem: (Int, [DropdownItemModel]) -> Void
    var selectedItems: [DropdownItemModel]
    @Binding var isPresented: Bool
    @ObservedObject var multiSelectViewModel: MultiSelectViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack {
                Rectangle()
                    .fill(Color.buttonSecondaryBorderColor)
                    .frame(width: 32, height: 4)
                    .cornerRadius(2)
                    .padding(.top, 4)
                HStack {
                    Spacer()
                    Button(action: {
                        isPresented = false
                    }) {
                        AppIcon(icon: .close, color: .textPlaceHolderColor)
                            .padding()
                    }
                }
            }
            .frame(height: 30) // Adjust height to provide spacing
            .background(Color.backgroundPrimary)
            
            HStack {
                Text(title)
                    .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
                    
                    .foregroundColor(Color.textPrimary)
                Spacer()
                if !multiSelectViewModel.tempSelectedItems.isEmpty {
                    Button(action: {
                        multiSelectViewModel.tempSelectedItems.removeAll()
                    }) {
                        Text("Reset")
                            .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                            
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            .background(Color.backgroundPrimary)
            
            DropdownSearchField { searchText in
               multiSelectViewModel.loadItems(index: index, search: searchText)
            }
            if multiSelectViewModel.isLoading {
                VStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            else{
                if !multiSelectViewModel.displayedItems.isEmpty {
                    ScrollView {
                        //                    if !initialSelected.isEmpty {
                        //                        Divider()
                        //                            .frame(height: 1)
                        //                            .background(Color.borderSecondaryColor)
                        //                            .padding(.vertical, 8)
                        //
                        //                        ForEach(initialSelected, id: \.self) { item in
                        //                            itemButton(item: item)
                        //                        }
                        //
                        //                        Divider()
                        //                            .frame(height: 1)
                        //                            .background(Color.borderSecondaryColor)
                        //                            .padding(.vertical, 8)
                        //                    }
                        
                        ForEach(multiSelectViewModel.displayedItems, id: \.self) { item in
                            itemButton(item: item)
                        }
                    }
                }
                else{
                    VStack {
                        Spacer()
                        Text(ResourceManager.localized("noRecordsFoundText"))
                                .foregroundColor(Color.textPrimary)
                                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                                
                        Spacer()
                    }.frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            
            VStack(alignment: .leading) {
                Divider()
                    .frame(height: 1)
                    .background(Color.borderSecondaryColor)
                
                HStack {
                    FilledButton(title: ResourceManager.localized("saveText", comment: ""), onClick: {
                        updateSelectedItem(index, multiSelectViewModel.tempSelectedItems)
                        isPresented = false
                    })
                    
                    OutlinedButton(title: ResourceManager.localized("cancelText", comment: ""), onClick: {
                        isPresented = false
                    })
                }
                .padding(.top, 12)
                .padding(.horizontal)
                .background(Color.backgroundPrimary)
                .padding(.bottom, 12)
                Divider()
                    .frame(height: 1)
                    .background(Color.borderSecondaryColor)
                
                
            }
        }
        .background(Color.backgroundPrimary.ignoresSafeArea())
    }
    
    private func itemButton(item: DropdownItemModel) -> some View {
        Button(action: {
            if multiSelectViewModel.tempSelectedItems.contains(item) {
                multiSelectViewModel.tempSelectedItems.removeAll { $0 == item }
            } else {
                multiSelectViewModel.tempSelectedItems.append(item)
            }
        }) {
            HStack {
                FormCheckBox(isChecked: multiSelectViewModel.tempSelectedItems.contains(item))
                Text(item.displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.textPrimary)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                    .lineLimit(3)
                    .truncationMode(.tail)
                    .multilineTextAlignment(.leading)
                    .padding(.leading, 8)
                Spacer()
            }
            .padding(16)
        }
    }
}
