import SwiftUI

struct DropdownSearchField: View {
    var onSearch: (String) -> Void
    var isSmall: Bool

    @State private var searchText: String = ""
    @State private var isFocused: Bool = false

    // Default initializer
    init(isSmall: Bool = false, onSearch: @escaping (String) -> Void) {
        self.isSmall = isSmall
        self.onSearch = onSearch
    }

    // Named constructor for small version
    static func small(onSearch: @escaping (String) -> Void) -> DropdownSearchField {
        return DropdownSearchField(isSmall: true, onSearch: onSearch)
    }

    var body: some View {
        HStack {
            ZStack(alignment: .leading) {
                if searchText.isEmpty {
                    Text("Search")
                        .foregroundColor(.textPlaceHolderColor)
                        .padding(.horizontal, isSmall ? 8 : 12)
                        .font(FontFamily.customFont(size: isSmall ? FontSize.medium : FontSize.large, weight: .regular))
                        
                }

                TextField("", text: $searchText, onEditingChanged: { isEditing in
                    isFocused = isEditing
                })
                .textFieldStyle(.plain)
                .foregroundColor(Color.textPrimary)
                .font(FontFamily.customFont(size: isSmall ? FontSize.medium : FontSize.large, weight: .regular))
                
                .padding(.vertical, isSmall ? 8 : 12)
                .padding(.horizontal, isSmall ? 8 : 12)
                .onChange(of: searchText) { newText in
                    onSearch(newText)
                }
            }

            Divider()
                .frame(width: 1, height: isSmall ? 36 : 44)
                .background(isFocused ? Color.accentColor.opacity(0.5) : Color.buttonSecondaryBorderColor)

            AppIcon(icon: .search)
                .padding(.leading, 6)
                .padding(.trailing, 12)
        }
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: isSmall ? 6 : 8)
                .stroke(isFocused ? Color.accentColor.opacity(0.5) : Color.buttonSecondaryBorderColor, lineWidth: 2)
        )
        .cornerRadius(isSmall ? 6 : 8)
        .padding(.horizontal, isSmall ? 12 : 16)
        .padding(.vertical, isSmall ? 12 : 14)
    }
}
