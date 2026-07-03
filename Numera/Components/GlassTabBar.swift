import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, activity, insights, budget, settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:     return "Home"
        case .activity: return "Activity"
        case .insights: return "Insights"
        case .budget:   return "Budget"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .activity: return "list.bullet.rectangle.fill"
        case .insights: return "chart.pie.fill"
        case .budget:   return "wallet.pass.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Floating Apple-glass pill tab bar (Quanto-style): blur material, soft border,
/// sliding highlight behind the active tab.
struct GlassTabBar: View {
    @Binding var selected: AppTab
    @Namespace private var highlightNamespace

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabItem(tab)
            }
        }
        .padding(5)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 27, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 27, style: .continuous)
                .stroke(AppColors.borderGlass, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 24, x: 0, y: 12)
    }

    private func tabItem(_ tab: AppTab) -> some View {
        Button {
            guard selected != tab else { return }
            Haptics.select()
            withAnimation(.snappy(duration: 0.25)) { selected = tab }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 17, weight: .semibold))
                Text(tab.label)
                    .font(.system(size: 10, weight: .semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundColor(selected == tab ? AppColors.textPrimary : AppColors.textTertiary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 9)
            .background {
                if selected == tab {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                        .matchedGeometryEffect(id: "tab-highlight", in: highlightNamespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        GlassTabBar(selected: .constant(.home))
            .padding(.horizontal, 20)
    }
    .preferredColorScheme(.dark)
}
