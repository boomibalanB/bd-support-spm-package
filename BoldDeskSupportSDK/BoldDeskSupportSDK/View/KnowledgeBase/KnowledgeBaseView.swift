import SwiftUI
import Foundation

struct KnowledgeBaseView: View {
    @Environment(\.presentationMode) private var presentationMode
    @StateObject private var kbListViewModel = KBListViewModel()
    @EnvironmentObject var toastManager: ToastManager
    
    private let isForShimmer: Bool
    
    init(isForShimmer: Bool = false) {
        self.isForShimmer = isForShimmer
    }
    
    static func shimmerPage() -> KnowledgeBaseView {
        KnowledgeBaseView(isForShimmer: true)
    }
    
    var body: some View {
        AppPage(
            
        ) {
            VStack(alignment: .leading, spacing: 0){
                CommonAppBar(
                    title: ResourceManager.localized("knowledgeBaseText", comment: ""),
                    showBackButton: true,
                    onBack: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
                {
                    NavigationLink(destination: KnowledgeBaseSearchView()) {
                        AppIcon(icon: .search, color: .appBarForegroundColor)
                            .padding(.all, 10)
                    }
                }
                NetworkWrapper {
                    VStack(spacing: 0) {
                        if kbListViewModel.isLoading {
                            ShimmerKnowledgeBaseView()
                        }
                        else {
                            if kbListViewModel.category.isEmpty {
                                Spacer()
                                Text(ResourceManager.localized("noCategoryFoundText", comment: ""))
                                    .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                                    .foregroundColor(.textTeritiaryColor)
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                Spacer()
                            } else {
                                ScrollView {
                                    // Article Cards
                                    VStack(alignment: .leading, spacing: 0) {
                                        if DeviceType.isPhone {
                                            ForEach(kbListViewModel.category, id: \.self) { article in
                                                ArticleCard(article: article)
                                                    .padding(.horizontal, 12)
                                                    .padding(.bottom, 12)
                                            }
                                        }
                                        else{
                                            let columns = [
                                                GridItem(.flexible(), spacing: 30),
                                                GridItem(.flexible(), spacing: 0)
                                            ]
                                            LazyVGrid(columns: columns, spacing: 24) {
                                                ForEach(kbListViewModel.category, id: \.self) { article in
                                                    ArticleCard(article: article)
                                                        .frame(maxWidth: .infinity)
                                                        .background(Color.backgroundPrimary)
                                                        .cornerRadius(12)
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 12)
                                                                .stroke(Color.borderSecondaryColor, lineWidth: 1)
                                                        )
                                                }
                                            }
                                            .padding(.horizontal, DeviceType.isPhone ? 30 : 32)
                                            .padding(.bottom, 40)
                                            
                                            
                                        }
                                    }
                                    .background(DeviceType.isPhone ? Color.backgroundTeritiaryColor : Color.backgroundPrimary)
                                    .padding(.top,DeviceType.isPhone ? 16 : 40)
                                    
                                    if kbListViewModel.popularArticle.isEmpty {
                                        VStack(alignment: .leading, spacing: 0) {
                                            Text(ResourceManager.localized("popularArticlesText", comment: ""))
                                                .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
                                                
                                                .foregroundColor(Color.textSecondaryColor)
                                                .padding(.top, DeviceType.isPhone ? 20 : 56)
                                                .padding(.horizontal, DeviceType.isPhone ? 12 : 32)
                                                .padding(.bottom, DeviceType.isPhone ? 16 : 24)
                                            
                                            ForEach(kbListViewModel.popularArticle, id: \.id) { article in
                                                PopularArticles(popularArticles: article)
                                                    .padding(.horizontal, DeviceType.isPhone ? 12 : 32)
                                                    .padding(.bottom, 20)
                                            }
                                        } .background(DeviceType.isPhone ? Color.backgroundTeritiaryColor :  Color.popularArticleBackgroundColor)
                                    }
                                }
                            }
                        }
                    }
                    .onAppear {
                        if !isForShimmer {
                            kbListViewModel.initiate()
                        }
                    }
                }
                PoweredByFooterView()
            }
            .background(DeviceType.isPhone ? Color.backgroundTeritiaryColor :  Color.backgroundPrimary)
            .overlay(ToastStackView())
        }
    }
}

struct ArticleCard: View {
    let article: CategoryKB
    @State private var lineHeight = LineHeight()
    
    var body: some View {
        NavigationLink(destination: AcrticlesView(categoryId: article.id, isFromSection: false), label:{
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    NetworkImageViewForKB(imageUrl: article.icon)
                    Text(article.name ?? "")
                        .font(FontFamily.customFont(size: FontSize.xlarge, weight: .semibold))
                        
                        .foregroundColor(Color.textSecondaryColor)
                        .lineLimit(1)
                        .padding(.leading, 12)
                    Spacer()
                }
                
                Text(article.description ?? "")
                    .font(FontFamily.customFont(size: DeviceType.isPhone ? FontSize.medium : FontSize.large, weight: .regular))
                    
                    .foregroundColor(.textTeritiaryColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(DeviceType.isPhone ? lineHeight.lineSpacingForMedium() : lineHeight.lineSpacingForLarge())
                    .frame(height: DeviceConfig.isIPad ? 70 : nil, alignment: .topLeading)
                    .padding(.top, 12)
                
                
                HStack(spacing: 6) {
                    Text("\(article.articleCount ?? 0) Articles")
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .semibold))
                        
                        .foregroundColor(.accentColor)
                    AppIcon(icon: .arrowRight, color: Color.accentColor)
                }
                .padding(.top, 12)
            }
            .padding(.horizontal, DeviceType.isPhone ? 20 : 24 )
            .padding(.vertical, DeviceType.isPhone ? 20 : 24 )
            .background(DeviceType.isPhone ? Color.cardBackgroundPrimary : Color.attachmentIconBackgroundColor)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderSecondaryColor, lineWidth: 1)
            )
        })
    }
}

struct PopularArticles: View {
    let popularArticles: PopularArticleModel
    
    var body: some View {
        NavigationLink(destination: HTMLWebView(articleId: popularArticles.id, articleName: popularArticles.title ?? "")) {
            HStack(alignment: .top, spacing: 8) {
                AppIcon(icon: .fileText, color: .textPlaceHolderColor)
                    .frame(width: 24, height: 24)
                
                Text(popularArticles.title ?? "")
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    
                    .foregroundColor(.textSecondaryColor)
                    .multilineTextAlignment(.leading)
                    .lineSpacing(6)
                    .padding(.top, 6)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
