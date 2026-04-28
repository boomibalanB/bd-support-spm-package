import SwiftUI
import Combine

struct PopoverMultiPicker: View {
    var title: String
    var index: Int
    var updateSelectedItem: (Int, [DropdownItemModel]) -> Void
    var selectedItems: [DropdownItemModel]
    @Binding var isPresented: Bool
    @ObservedObject var multiSelectViewModel: MultiSelectViewModel
    @EnvironmentObject var toastManager: ToastManager
    
    // Keyboard detection
    @State private var keyboardHeight: CGFloat = 0
    
    // Get screen dimensions
    private var screenWidth: CGFloat {
        UIScreen.main.bounds.width
    }
    
    private var screenHeight: CGFloat {
        UIScreen.main.bounds.height
    }
    
    private var popoverWidth: CGFloat {
        // Make popover width responsive - never exceed 90% of screen width
        min(320, screenWidth * 0.9)
    }
    
    // Calculate content area height based on available space
    private var contentAreaHeight: CGFloat {
        let headerHeight: CGFloat = 60  // Fixed header height
        let searchHeight: CGFloat = 50  // Fixed search height
        let footerHeight: CGFloat = 70  // Fixed footer height
        let fixedHeight = headerHeight + searchHeight + footerHeight
        
        // Available screen height minus keyboard and margins
        let availableHeight = screenHeight - keyboardHeight - 80 // 80pt for margins and safe areas
        
        // Content area gets remaining space, with min/max constraints
        let contentHeight = availableHeight - fixedHeight
        return max(60, min(300, contentHeight)) // Min 120pt, Max 300pt
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // FIXED HEADER - Always visible
            HStack {
                Text(title)
                    .font(FontFamily.customFont(size: FontSize.large, weight: .semibold))
                    
                    .foregroundColor(Color.textPrimary)
                    .lineLimit(1)
                Spacer()
                
                if !multiSelectViewModel.tempSelectedItems.isEmpty {
                    Button(action: {
                        multiSelectViewModel.tempSelectedItems.removeAll()
                    }) {
                        Text(ResourceManager.localized("resetText", comment: ""))
                            .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                            
                            .foregroundColor(Color.accentColor)
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.backgroundPrimary)
            
            Rectangle()
                .fill(Color.borderSecondaryColor)
                .frame(height: 1)
            
            // FIXED SEARCH FIELD - Always visible
            VStack {
                DropdownSearchField.small { searchText in
                    Task {
                        multiSelectViewModel.loadItems(index: index, search: searchText)
                    }
                }
                .padding(.horizontal, 2)
            }
            
            // FLEXIBLE CONTENT AREA - Only this part shrinks/scrolls
            Group {
                if multiSelectViewModel.isLoading {
                    VStack {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                            .scaleEffect(1.2)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.popoverBackground.opacity(0.5))
                } else {
                    if !multiSelectViewModel.displayedItems.isEmpty {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(multiSelectViewModel.displayedItems, id: \.self) { item in
                                    itemButton(item: item)
                                }
                            }
                        }
                    } else {
                        VStack {
                            Spacer()
                            Text(ResourceManager.localized("noResultText", comment: ""))
                                .foregroundColor(Color.textPrimary)
                                .font(FontFamily.customFont(size: FontSize.large, weight: .regular))
                                
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .frame(height: contentAreaHeight) // DYNAMIC HEIGHT - adapts to keyboard
            
            // Bottom action buttons
            VStack(alignment: .leading, spacing: 0) {
                Rectangle()
                    .fill(Color.borderSecondaryColor)
                    .frame(height: 1)
                
                HStack(spacing: 8) {
                    FilledButton(
                        title: ResourceManager.localized("applyText", comment: ""),
                        onClick: {
                            updateSelectedItem(index, multiSelectViewModel.tempSelectedItems)
                            isPresented = false
                        },
                        isEnabled: !multiSelectViewModel.isLoading &&
                                  !multiSelectViewModel.displayedItems.isEmpty &&
                                  !areSameItems(multiSelectViewModel.tempSelectedItems, selectedItems),
                        isSmall: true
                    )
                    
                    OutlinedButton(
                        title: ResourceManager.localized("discardText", comment: ""),
                        onClick: {
                            isPresented = false
                        },
                        isSmall: true
                    )
                    
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.backgroundPrimary)
            }
        }
        .background(Color.backgroundPrimary)
        .cornerRadius(8)
        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
        .frame(width: popoverWidth)
        .onReceive(Publishers.keyboardHeight) { height in
            withAnimation(.easeInOut(duration: 0.25)) {
                keyboardHeight = height
            }
        }
    }
    
    private func itemButton(item: DropdownItemModel) -> some View {
        Button(action: {
            if multiSelectViewModel.tempSelectedItems.contains(item) {
                multiSelectViewModel.tempSelectedItems.removeAll { $0 == item }
            } else {
                multiSelectViewModel.tempSelectedItems.append(item)
            }
        }) {
            HStack(spacing: 8) {
                FormCheckBox(isChecked: multiSelectViewModel.tempSelectedItems.contains(item))
                
                Text(item.displayName)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .foregroundColor(Color.textPrimary)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                    
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Keyboard height publisher
extension Publishers {
    static var keyboardHeight: AnyPublisher<CGFloat, Never> {
        let willShow = NotificationCenter.default.publisher(for: UIApplication.keyboardWillShowNotification)
            .map { notification -> CGFloat in
                (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0
            }
        
        let willHide = NotificationCenter.default.publisher(for: UIApplication.keyboardWillHideNotification)
            .map { _ -> CGFloat in 0 }
        
        return MergeMany(willShow, willHide)
            .eraseToAnyPublisher()
    }
}
