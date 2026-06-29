import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var showAddTransaction = false

    enum Tab { case home, activity, insights, settings }

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)

                ActivityView()
                    .tag(Tab.activity)

                InsightsView()
                    .tag(Tab.insights)

                SettingsPlaceholderView()
                    .tag(Tab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            customTabBar
        }
        .ignoresSafeArea(edges: .bottom)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
    }

    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabBarItem(icon: "house.fill",         label: "Home",     tab: .home)
            tabBarItem(icon: "list.bullet.indent",  label: "Activity", tab: .activity)

            // Floating add button (center)
            Button { showAddTransaction = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.black)
                    .frame(width: 56, height: 56)
                    .background(AppColors.accent)
                    .clipShape(Circle())
                    .shadow(color: AppColors.accent.opacity(0.45), radius: 20, x: 0, y: 4)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -8)

            tabBarItem(icon: "chart.line.uptrend.xyaxis", label: "Insights",  tab: .insights)
            tabBarItem(icon: "gearshape.fill",            label: "Settings",  tab: .settings)
        }
        .padding(.horizontal, AppSpacing.sm)
        .padding(.top, AppSpacing.md)
        .padding(.bottom, 24)
        .background(
            AppColors.surfaceCard
                .overlay(AppColors.borderGlass)
                .ignoresSafeArea(edges: .bottom)
        )
        .overlay(alignment: .top) {
            Divider().background(AppColors.borderGlass)
        }
    }

    private func tabBarItem(icon: String, label: String, tab: Tab) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.textTertiary)
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

// Placeholder until Settings screen is built
struct SettingsPlaceholderView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            VStack(spacing: AppSpacing.base) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 40))
                    .foregroundColor(AppColors.textTertiary)
                Text("Settings")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
                Text("Coming soon")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
}
