import SwiftUI

struct BottomSheet<Content : View>: View {
    @State private var showImagePicker = false
    @State private var showCameraPicker = false
    @State private var showFileImporter = false
    @State private var pickedItems: [PickedMediaInfo] = []
    
    let content: Content
    @Binding var cardShow: Bool
    let height: CGFloat
    
    init(cardShow: Binding<Bool>,
         height: CGFloat,
         @ViewBuilder content: () -> Content) {
        _cardShow = cardShow
        self.content = content()
        self.height = height
    }
    
    var body: some View {
        ZStack {
            GeometryReader { _ in
                EmptyView()
            }
            .background(Color.gray.opacity(0.5))
            .opacity(cardShow ? 1 : 0)
            .animation(.easeIn, value: cardShow)
            .onTapGesture {
                self.dismiss()
            }
            VStack {
                Spacer()
                VStack(spacing: 0) {
                    if cardShow {
                        HStack(alignment: .top) {
                            Text("")  .frame(width: 32, height: 4)
                            Spacer()
                            VStack(spacing: 0) {
                                Rectangle()
                                    .fill(Color.buttonSecondaryBorderColor)
                                    .frame(width: 32, height: 4)
                                    .cornerRadius(2)
                                    .padding(.top, 16)
                                
                            }
                            Spacer()
                            Button(action: {
                                self.dismiss()
                            }) {
                                AppIcon(icon: .close, color: .textPlaceHolderColor)
                            }.padding(.trailing, 16)
                                .padding(.top, 12)
                        }
                    }
                    content.padding(.top, 20)
                }
                .frame(width: UIScreen.main.bounds.width - 20, height: height)
                .background(Color.white)
                .cornerRadius(16)
                .padding(.bottom, 24)
                .offset(y: cardShow ? 0 : height)
                .animation(.default.delay(0.2), value: cardShow)
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    func dismiss() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            cardShow.toggle()
        }
    }
}
