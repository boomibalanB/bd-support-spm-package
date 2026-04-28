import SwiftUI
import Foundation

struct AcrticlesView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var articlesViewModel :ArticlesViewModel
    @EnvironmentObject var toastManager: ToastManager
    var categoryId: Int = 0
    var isFromSection: Bool = false
    init(categoryId: Int, isFromSection: Bool){
        self.categoryId = categoryId
        self.isFromSection = isFromSection
        _articlesViewModel = StateObject(wrappedValue:  ArticlesViewModel(categoryId: categoryId, isFormSection: isFromSection))
    }
    
    var body: some View {
        AppPage(
            
        ) {
            VStack(alignment: .leading,spacing: 0){
                CommonAppBar(
                    title: ResourceManager.localized("knowledgeBaseText", comment: ""),
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                ){
                    NavigationLink(destination: KnowledgeBaseSearchView(isArticleSearch: true)) {
                        AppIcon(icon: .search, color: .appBarForegroundColor)
                            .padding(.all, 10)
                    }
                }
                
                NetworkWrapper {
                    ScrollView {
                        if articlesViewModel.isLoading {
                            ArticlesShimmer()
                        }
                        else{
                            VStack(alignment: .leading, spacing: 0){
                                Text(articlesViewModel.title)
                                    .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
                                    
                                    .foregroundColor(.textSecondaryColor)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 16)
                                if articlesViewModel.description.isEmpty == false {
                                    Text(articlesViewModel.description)
                                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                                        
                                        .foregroundColor(.textSecondaryColor)
                                        .padding(.horizontal,  20)
                                        .padding(.bottom, 24)
                                }
                                LazyVStack(alignment: .leading, spacing: 0){
                                    ForEach(articlesViewModel.articlesList.indices, id: \.self) { index in
                                        let article = articlesViewModel.articlesList[index]
                                        
                                        Group {
                                            if article.isSection ?? false {
                                                CategorySection(article: article)
                                                    .onAppear {
                                                        
                                                        if index == articlesViewModel.articlesList.count - 1 &&
                                                            articlesViewModel.articlesList.count > 19 &&
                                                            !articlesViewModel.isLoadingMore &&
                                                            articlesViewModel.canLoadMore {
                                                            Task {
                                                                await articlesViewModel.loadMoreTickets(id: categoryId , isSection: isFromSection)
                                                                print("applied load more")
                                                            }
                                                        }
                                                    }
                                            } else {
                                                ArticlesListView(id: article.id ?? 0, articleName: article.name ?? "")
                                                    .onAppear {
                                                        if index == articlesViewModel.articlesList.count - 1 &&
                                                            articlesViewModel.articlesList.count > 19 &&
                                                            !articlesViewModel.isLoadingMore &&
                                                            articlesViewModel.canLoadMore {
                                                            Task {
                                                                await articlesViewModel.loadMoreTickets(id: categoryId, isSection: isFromSection)
                                                                print("applied load more")
                                                            }
                                                        }
                                                    }
                                            }
                                        }
                                        
                                        .padding(.bottom, 20)
                                    }
                                    
                                    if articlesViewModel.isLoadingMore {
                                        LoadingMoreIndicatorView(message: ResourceManager.localized("loadingMoreTicketsText", comment: ""))                                    }
                                    
                                    if articlesViewModel.shouldShowNoMoreItems {
                                        NoMoreDataView(message: ResourceManager.localized("noMoreDataText", comment: "No more items to load"))
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .onAppear {
                        articlesViewModel.initiate()
                    }
                }
                PoweredByFooterView()
            }
            .background(Color.backgroundPrimary)
            .overlay(  ToastStackView())
        }
    }
}

struct ArticlesListView: View {
    let id: Int
    let articleName: String
    
    var body: some View {
        NavigationLink(destination: HTMLWebView(articleId: id, articleName: articleName)) {
            HStack(alignment: .top, spacing: 8) {
                AppIcon(icon: .fileText, color: .textPlaceHolderColor)
                    .frame(width: 24, height: 24)
                
                Text(articleName)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textSecondaryColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .padding(.top, 4)
                
                Spacer()
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategorySection: View {
    let article: ArticlesModel
    
    var body: some View {
        NavigationLink(destination: AcrticlesView(categoryId: article.id ?? 0, isFromSection: true)) {
            HStack(alignment: .top, spacing: 8) {
                AppIcon(icon: .folder, color: .textPlaceHolderColor)
                    .frame(width: 24, height: 24)
                
                Text(article.name ?? "")
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textSecondaryColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .padding(.top, 4)
            }
        }
    }
}

