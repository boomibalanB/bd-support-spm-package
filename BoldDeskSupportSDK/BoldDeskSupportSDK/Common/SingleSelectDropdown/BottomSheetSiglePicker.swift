import SwiftUI

struct BottomSheetSinglePicker: View {
    var title: String
    var index: Int
    var hideResetButton: Bool
    var updateSeelectedItem: (Int, DropdownItemModel?) -> Void
    var selectedItem: DropdownItemModel?
    @Binding var isPresented: Bool
    @ObservedObject var singleSelectViewModel: SingleSelectViewModel
    @EnvironmentObject var toastManager: ToastManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
            
            // Title + Reset
            HStack {
                Text(title)
                    .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
                    
                    .foregroundColor(Color.textPrimary)
                Spacer()
                if selectedItem != nil && !hideResetButton {
                    Button(action: {
                        updateSeelectedItem(index, nil)
                        isPresented = false
                    }) {
                        Text(ResourceManager.localized("resetText", comment: ""))
                            .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                            
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 12)
            .padding(.horizontal, 16)
            
            DropdownSearchField { text in
                Task {
                    await singleSelectViewModel.loadItems(index: index, search: text)
                }
            }
            ZStack {
                if singleSelectViewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                            .scaleEffect(2)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.clear)
                } else {
                    if !singleSelectViewModel.items.isEmpty {
                        ScrollView {
                            ForEach(singleSelectViewModel.items, id: \.id) { item in
                                Button(action: {
                                    updateSeelectedItem(index, item)
                                    isPresented = false
                                }) {
                                    VStack {
                                        Text(item.displayName)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .foregroundColor(Color.textPrimary)
                                            .font(FontFamily.customFont(size: FontSize.large, weight: .medium))
                                        if item.subtitle.isEmpty == false {
                                            Text(item.subtitle)
                                                .frame(maxWidth: .infinity, alignment: .leading)
                                                .foregroundColor(Color.textSecondaryColor)
                                                .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                                        }
                                    }
                                    .padding(16)
                                    .background(
                                        selectedItem == item
                                        ? Color.accentColor.opacity(0.2)
                                        : Color.clear
                                    )
                                }
                            }
                            
                        }
                    }else{
                        VStack {
                            Spacer()
                            Text(ResourceManager.localized("noRecordsFoundText"))
                                    .foregroundColor(Color.textPrimary)
                                    .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                                    
                            Spacer()
                        }.frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            
        }
        .padding(.bottom, 12)
        .background(Color.backgroundPrimary.ignoresSafeArea())
        .overlay(ToastStackView())
    }
}
