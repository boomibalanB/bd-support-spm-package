import SwiftUI
struct DislikeFeedbackSlider : View {
    var articleId: Int = 0
    var htmlWebviewModel : HTMLWebViewModel
    @Binding var isPresented: Bool
    @StateObject private var viewModel  : DislikeFeedbackViewModel
    @Environment(\.presentationMode) private var presentationMode
    init (isPresented: Binding<Bool>, articleId: Int, htmlWebviewModel: HTMLWebViewModel) {
        self._isPresented = isPresented
        self.articleId = articleId
        self.htmlWebviewModel = htmlWebviewModel
        _viewModel = StateObject(wrappedValue: DislikeFeedbackViewModel(htmlWebviewModel: htmlWebviewModel))
    }
    var body: some View {
        ZStack{
            VStack (spacing: 0){
                if DeviceType.isTablet {
                    DialogAppBar(title: ResourceManager.localized("helpUsText", comment: ""), actionButtons: buildActionButtons(), onBack: {
                        isPresented = false
                    })
                }
                VStack(spacing: 0) {
                    if DeviceType.isPhone {
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
                    }
                    
                    if DeviceType.isPhone {
                        HStack(alignment: .top) {
                            Text(ResourceManager.localized("helpUsText", comment: ""))
                                .font(FontFamily.customFont(size: FontSize.semilarge, weight: .semibold))
                                
                                .foregroundColor(Color.textPrimary)
                            Spacer()
                        }
                        .padding(.top, 16)
                        .padding(.bottom, 24)
                        .padding(.horizontal, 16)
                        .background(Color.clear)
                    }
                    ScrollView{
                        VStack(alignment: .leading, spacing: 0) {
                            CheckboxWithLabel(title: FeedbackContentEnum.outdatedContent.value,
                                              showInfoButton: false,
                                              isChecked: viewModel.outdatedContentChecked,
                                              index: 0,
                                              isRequired: false,
                                              updateCheckBox: viewModel.updateCheckBoxValue)
                            .padding(.bottom, 6)
                            CheckboxWithLabel(title: FeedbackContentEnum.improve.value,
                                              showInfoButton: false,
                                              isChecked: viewModel.improveChecked,
                                              index: 1,
                                              isRequired: false,
                                              updateCheckBox: viewModel.updateCheckBoxValue)
                            .padding(.bottom, 6)
                            CheckboxWithLabel(title: FeedbackContentEnum.brokenLinks.value,
                                              showInfoButton: false,
                                              isChecked: viewModel.brokenLinksChecked,
                                              index: 2,
                                              isRequired: false,
                                              updateCheckBox: viewModel.updateCheckBoxValue)
                            .padding(.bottom, 6)
                            CheckboxWithLabel(title: FeedbackContentEnum.moreInformation.value,
                                              showInfoButton: false,
                                              isChecked: viewModel.moreInformationChecked,
                                              index: 3,
                                              isRequired: false,
                                              updateCheckBox: viewModel.updateCheckBoxValue)
                            .padding(.bottom, 6)
                            CheckboxWithLabel(title: FeedbackContentEnum.outdatedCode.value,
                                              showInfoButton: false,
                                              isChecked: viewModel.outdatedCodeChecked,
                                              index: 4,
                                              isRequired: false,
                                              updateCheckBox: viewModel.updateCheckBoxValue)
                            .padding(.bottom, 6)
                            CustomTextEditor(label: ResourceManager.localized("commentsText", comment: ""),
                                             text: Binding( // Creating a Binding
                                                get: { viewModel.descriptionText },
                                                set: { newValue in
                                                    viewModel.descriptionText = newValue
                                                }
                                                ),
                                             index: 0,
                                             isRequired: false,
                                             onTap: {})
                            .padding(.bottom, 6)
                            if AppConstant.authToken.isEmpty {
                                TextFieldView(label: ResourceManager.localized("emailText", comment: ""),
                                              text:  Binding( // Creating a Binding
                                                get: { viewModel.emailAddress },
                                                set: { newValue in
                                                    viewModel.emailAddress = newValue
                                                }),
                                              index: 0,
                                              isRequired: true,
                                              validation: viewModel.emailVaidation,
                                              onTap: {},
                                              errorMessage: viewModel.errorMessage,
                                              isValid: viewModel.isEmailValid)
                                .padding(.bottom, 6)
                            }
                            if !BDSupportSDK.isFromChatSDK {
                                CheckboxWithLabel(title: FeedbackContentEnum.canWeContant.value,
                                                  showInfoButton: false,
                                                  isChecked: viewModel.canWeContant,
                                                  index: 5,
                                                  isRequired: false,
                                                  updateCheckBox: viewModel.updateCheckBoxValue)
                                .padding(.bottom, 6)
                            }
                        }
                        .padding(.horizontal, DeviceType.isPhone ? 4 : 0)
                        .padding(.top, DeviceType.isPhone ? 0 : 24)
                    }
                }
                if DeviceType.isPhone {
                    VStack(alignment: .leading) {
                        Divider()
                        HStack(spacing: 12) {
                            if !viewModel.isSubmitDisabled {
                                FilledButton(title: ResourceManager.localized("submitText",comment: ""), onClick: {
                                    Task {
                                        await viewModel.submitFeedback(articleId: articleId)
                                    }
                                })
                            }
                            OutlinedButton(title:ResourceManager.localized("cancelText",comment: ""), onClick: {
                                isPresented = false
                            })
                        }
                        .padding(.top, 12)
                        .padding(.bottom, 12)
                        .padding(.leading, 16)
                        .background(Color.clear)
                        Divider()
                            .frame(height: 1)
                            .background(Color.backgroundPrimary)
                    }
                }
            }
            .background(Color.backgroundPrimary.ignoresSafeArea())
            .overlay(ToastStackView())
            .onChange(of: viewModel.isSuccess) { newValue in
                if newValue {
                    isPresented = false
                }
            }
            if viewModel.isLoading {
                CircleLoadingIndicatorView()
            }
        }
    }
    
    func buildActionButtons() -> [CustomAppBarAction] {
        var buttons: [CustomAppBarAction] = []
        
        if !viewModel.isLoading && !viewModel.isSubmitDisabled{
            buttons.append(
                .textButton(text: ResourceManager.localized("submitText", comment: ""), action: {
                    Task {
                        await viewModel.submitFeedback(articleId: articleId)
                    }
                })
            )
        }
        
        return buttons
    }
}
