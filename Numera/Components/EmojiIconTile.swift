import SwiftUI

/// Quanto-style icon tile: emoji centered in a rounded square with a soft
/// category-colored border.
struct EmojiIconTile: View {
    let emoji: String
    var colorHex: String?
    var size: CGFloat = 46

    private var borderColor: Color {
        colorHex.map { Color(hex: $0).opacity(0.8) } ?? AppColors.borderGlass
    }

    var body: some View {
        RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
            .fill(AppColors.surfaceElevated)
            .overlay(
                RoundedRectangle(cornerRadius: size * 0.3, style: .continuous)
                    .stroke(borderColor, lineWidth: 1.5)
            )
            .overlay(
                Text(emoji)
                    .font(.system(size: size * 0.48))
            )
            .frame(width: size, height: size)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        HStack(spacing: 12) {
            EmojiIconTile(emoji: "🍽️", colorHex: "#5DDBBD")
            EmojiIconTile(emoji: "🚗", colorHex: "#6FB6FF")
            EmojiIconTile(emoji: "🤷", colorHex: "#A78BFA")
            EmojiIconTile(emoji: "🧾")
        }
    }
    .preferredColorScheme(.dark)
}
