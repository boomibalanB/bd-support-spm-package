import SwiftUI

struct BottomSheetPresenter<SheetContent: View>: ViewModifier {
    @Binding var isPresented: Bool
    let content: (_ dismiss: @escaping () -> Void) -> SheetContent

    @State private var translation: CGFloat = 0
    @State private var sheetHeight: CGFloat = 0
    @State private var yOffset: CGFloat = UIScreen.main.bounds.height
    
    @StateObject private var keyboardObserver = KeyboardObserver()

    func body(content host: Content) -> some View {
        ZStack {
            host

            if isPresented {
                Color.backgroundOverlayColor
                    .ignoresSafeArea()
                    .onTapGesture { dismissSheet() }

                VStack {
                    Spacer()

                    VStack(spacing: 0) {
                        HStack {
                            Spacer()
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color.buttonSecondaryBorderColor)
                                .frame(width: 32, height: 4)
                            Spacer()
                        }
                        .overlay(
                            Button(action: { dismissSheet() }) {
                                AppIcon(icon: .close, color: Color.textQuarteraryColor)
                            }
                                .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.trailing, 16)
                        )
                        .frame(height: 30)

                        self.content { dismissSheet() }
                            .padding(.bottom, 16)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.backgroundPrimary)
                            .ignoresSafeArea(edges: .bottom)
                    )
                    .background(
                        GeometryReader { proxy in
                            Color.clear.onAppear {
                                sheetHeight = proxy.size.height
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    yOffset = 0
                                }
                            }
                        }
                    )
                    .padding(.all, 12)
                    .offset(y: yOffset + max(0, translation))
                    .offset(y: yOffset + max(0, translation))
                    .padding(.bottom, keyboardObserver.isKeyboardVisible ? keyboardObserver.keyboardHeight - 24 : 0)
                    .animation(.interactiveSpring(response: 0.35, dampingFraction: 0.85, blendDuration: 0.25), value: keyboardObserver.keyboardHeight)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                translation = max(0, value.translation.height)
                            }
                            .onEnded { value in
                                let shouldClose = value.translation.height > sheetHeight * 0.25
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                                    if shouldClose {
                                        dismissSheet()
                                    } else {
                                        translation = 0
                                    }
                                }
                            }
                    )
                    
                    Color.backgroundPrimary
                        .frame(height: 15)
                }
                .ignoresSafeArea()
                
                
            }
        }
    }

    private func dismissSheet() {
        withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
            yOffset = sheetHeight
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            isPresented = false
            translation = 0
        }
    }
}


extension View {
    func bottomSheet<Content: View>(
        isPresented: Binding<Bool>,
        @ViewBuilder content: @escaping (_ dismiss: @escaping () -> Void) -> Content
    ) -> some View {
        self.modifier(
            BottomSheetPresenter(isPresented: isPresented, content: content)
        )
    }
}

