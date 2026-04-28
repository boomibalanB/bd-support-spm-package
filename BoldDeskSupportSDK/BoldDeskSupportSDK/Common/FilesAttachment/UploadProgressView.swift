import SwiftUI

struct UploadingRow: View {
    var pickedItem : PickedMediaInfo
    var isLast: Bool = false
    var isProgressShow: Bool = true
    var onDelete: (() -> Void)? = nil
    
    @State private var progress: Double = 0.0
    @State private var timer: Timer?
    @State private var uploadComplete = false

    var body: some View {
        HStack(spacing: 12) {
            if DeviceType.isTablet {
                
                Text(pickedItem.fileExtension.uppercased())
                    .font(FontFamily.customFont(size: FontSize.xxxsmall, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 5)
                    .background(Color.textTeritiaryColor)
                    .cornerRadius(4)

                let displayName = pickedItem.name.count > 20
                    ? String(pickedItem.name.prefix(20)) + "..."
                    : pickedItem.name

                Text(displayName)
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                    .foregroundColor(Color.textSecondaryColor)
                    .lineLimit(1)


                Text(formattedSizeRounded(from: pickedItem.fileSizeInBytes))
                    .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                    .foregroundColor(Color.textTeritiaryColor)
                Spacer()
                if !uploadComplete && isProgressShow {
                    CircularProgressView(progress: progress) // ⬅️ Custom circular indicator
                        .frame(width: 20, height: 20)
                } else {
                    Button(action: {
                        onDelete?()
                    }) {
                        AppIcon(icon: .delete)
                    }
                }

            } else {
                // 💻 Tablet/Desktop detailed layout
                Text(pickedItem.fileExtension.uppercased())
                    .font(FontFamily.customFont(size: FontSize.xxxsmall, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 5)
                    .background(Color.textTeritiaryColor)
                    .cornerRadius(4)

                VStack(alignment: .leading, spacing: 4) {
                    Text(pickedItem.name)
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                        .foregroundColor(Color.textSecondaryColor)
                        .lineLimit(1)

                    Text(formattedSizeRounded(from: pickedItem.fileSizeInBytes))
                        .font(FontFamily.customFont(size: FontSize.medium, weight: .regular))
                        .foregroundColor(Color.textTeritiaryColor)

                    if !uploadComplete && isProgressShow {
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.borderSecondaryColor)
                                    .frame(height: 8)
                                Capsule()
                                    .fill(Color.accentColor)
                                    .frame(width: geometry.size.width * progress, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                        }
                        .frame(height: 6)
                        .padding(.top, 4)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 8) {
                    Button(action: {
                        onDelete?()
                    }) {
                        AppIcon(icon: .delete)
                    }

                    if !uploadComplete && isProgressShow {
                        Text("\(Int(progress * 100))%")
                            .font(FontFamily.customFont(size: FontSize.medium, weight: .medium))
                            .foregroundColor(Color.textSecondaryColor)
                            .padding(.top, 4)
                    }
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .frame(maxWidth: DeviceConfig.isIPhone ? nil : .infinity)
        .background(Color.clear)
        .cornerRadius(DeviceConfig.isIPhone ? 12 : 10)
        .overlay(
            RoundedRectangle(cornerRadius: DeviceConfig.isIPhone ? 12 : 10)
                .stroke(Color.borderSecondaryColor, lineWidth: 1)
        )
        .onAppear {
            timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { t in
                if progress >= 1.0 {
                    t.invalidate()
                    uploadComplete = true
                } else {
                    progress += 0.02
                }
            }
        }
        .onDisappear {
            timer?.invalidate()
        }
    }
}


struct CircularProgressView: View {
    var progress: CGFloat // between 0 and 1

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.borderSecondaryColor, lineWidth: 3)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            if Int(progress * 100) < 100 {
                Text("\(Int(progress * 100))")
                    .font(FontFamily.customFont(size: FontSize.xxxsmall, weight: .medium))
            }
        }
    }
}
