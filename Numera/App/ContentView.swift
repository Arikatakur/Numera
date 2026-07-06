import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var store

    @State private var selectedTab: AppTab = .home

    var body: some View {
        // System TabView: native switching (no page-swipe lag) and the system
        // tab bar, which adopts Liquid Glass automatically on iOS 26 (HIG tab
        // bars) — no appearance overrides, no custom bar to fight it.
        TabView(selection: $selectedTab) {
            HomeView(
                onShowInsights: { selectedTab = .insights },
                onShowActivity: { selectedTab = .activity },
                onShowBudget: { selectedTab = .budget }
            )
            .tabItem { Label(AppTab.home.label, systemImage: AppTab.home.icon) }
            .tag(AppTab.home)

            ActivityView()
                .tabItem { Label(AppTab.activity.label, systemImage: AppTab.activity.icon) }
                .tag(AppTab.activity)

            InsightsView(onShowActivity: { selectedTab = .activity })
                .tabItem { Label(AppTab.insights.label, systemImage: AppTab.insights.icon) }
                .tag(AppTab.insights)

            BudgetView()
                .tabItem { Label(AppTab.budget.label, systemImage: AppTab.budget.icon) }
                .tag(AppTab.budget)

            SettingsView()
                .tabItem { Label(AppTab.settings.label, systemImage: AppTab.settings.icon) }
                .tag(AppTab.settings)
        }
        .tint(AppColors.accent)
        .overlay(alignment: .bottomTrailing) {
            // Hidden on the Settings tab and on any pushed detail screen.
            if !TabBarVisibility.shared.isHidden && selectedTab != .settings {
                AddTransactionFAB()
                    .padding(.trailing, AppSpacing.screenMargin)
                    .padding(.bottom, 64)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: TabBarVisibility.shared.isHidden)
        .overlay(alignment: .top) {
            if let message = store.errorMessage {
                ErrorToast(message: message) { store.errorMessage = nil }
            }
        }
        .animation(.snappy(duration: 0.3), value: store.errorMessage)
        .task {
            if !store.hasLoaded {
                await store.bootstrap()
            }
        }
    }
}

/// The floating (+) with its sheet state isolated in this tiny view: tapping
/// it only re-renders the button, not the whole TabView tree. Presenting from
/// ContentView made the tap feel laggy on heavy tabs (Insights re-computed
/// every card before the sheet could appear).
private struct AddTransactionFAB: View {
    @State private var showAddTransaction = false

    var body: some View {
        FloatingAddButton { showAddTransaction = true }
            .sheet(isPresented: $showAddTransaction) {
                AddTransactionView()
            }
    }
}

/// Transient banner for DataStore errors; auto-dismisses after a few seconds.
private struct ErrorToast: View {
    let message: String
    var onDismiss: () -> Void

    var body: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.warning)
            Text(message)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Spacer(minLength: 4)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, 12)
        .liquidGlass(cornerRadius: AppRadius.lg)
        .padding(.horizontal, AppSpacing.screenMargin)
        .transition(.move(edge: .top).combined(with: .opacity))
        .task {
            try? await Task.sleep(for: .seconds(4))
            onDismiss()
        }
    }
}

#Preview {
    ContentView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
        .environment(PremiumManager.preview())
}
