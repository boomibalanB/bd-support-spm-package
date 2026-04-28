import SwiftUI

struct KnowledgeBaseSearchView: View {
    var isArticleSearch: Bool = false
    @StateObject private var viewModel = KnowledgeBaseSearchViewModel()
    @EnvironmentObject var toastManager: ToastManager
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var keyboardObserver = KeyboardObserver()
    
    var body: some View {
        AppPage(){
            VStack(alignment: .leading, spacing: 0) {
                CommonAppBarCustom {
                    HStack(spacing: 0) {
                        TicketSearchAppBar(
                            searchText: $viewModel.searchText,
                            onBack: {
                                presentationMode.wrappedValue.dismiss()
                            },
                            onSearch: {
                                Task {
                                    await viewModel.searchArticles()
                                }
                            },
                            onClear: {
                                viewModel.clearSearch()
                            },
                            onFilter: {
                                
                            },
                            placeholder: ResourceManager.localized("searchArticlesText", comment: "")
                        )
                        if !isArticleSearch {
                            IconButtonSingleSelectDropdown(icon: .filter1, updateSelectedItem: viewModel.updateSelectedItem, selectedItem: viewModel.selectedItem, fetchItems: viewModel.getCategoryItems, hideResetButton: true , onTap: viewModel.clearSearch)
                                .padding(.leading, 16)
                                .padding(.trailing, 10)
                        }
                    }
                }
                VStack(spacing: 0) {
                    ZStack {
                        if viewModel.isLoading {
                            VStack {
                                Spacer()
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: Color.accentColor))
                                    .scaleEffect(2)
                                Spacer()
                            }
                            .background(Color.clear)
                            .frame(maxWidth: .infinity, maxHeight: .infinity) // Fills ZStack space
                        }
                        else if viewModel.noItemsFound {
                            NetworkWrapper {
                                Text(ResourceManager.localized("noArticlesFoundText", comment: ""))
                                    .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                                
                                    .foregroundColor(.textTeritiaryColor)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                            }
                        }
                        else if viewModel.searchArticleList.isEmpty && !viewModel.isLoading {
                            Text(ResourceManager.localized("searchArticleInitalText", comment: ""))
                                .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                            
                                .foregroundColor(.textTeritiaryColor)
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                        else{
                            NetworkWrapper{
                                ScrollView {
                                    ForEach(viewModel.searchArticleList, id: \.self) { article in
                                        ArticlesListView(id: article.id ?? 0, articleName: article.title ?? "")
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(.bottom, DeviceType.isPhone ? 10 : 12)
                                    }
                                }
                                .padding(.horizontal, DeviceType.isPhone ? 12: 20)
                                .padding(.vertical, 16)
                            }
                        }
                    }
                    if !(keyboardObserver.isKeyboardVisible) {
                        PoweredByFooterView()
                    }
                }
            }
            .frame(maxHeight: .infinity, alignment: .top)
            .background(Color.backgroundPrimary)
            .navigationBarHidden(true)
            .overlay(ToastStackView())
        }
    }
}
