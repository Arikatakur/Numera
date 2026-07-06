import SwiftUI

/// Large in-content page title (Apple large-title size), aligned to the
/// 20pt screen margin like Home's header — native large titles sit on the
/// system margin and looked glued to the screen edge next to the app's
/// content margin.
struct PageTitle: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 34, weight: .bold))
            .foregroundColor(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
