import SwiftUI

struct ContentView: View {
    @Environment(DataStore.self) private var store

    @State private var selectedTab: AppTab = .home
    @State private var showAddTransaction = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView(
                    onShowInsights: { selectedTab = .insights },
                    onShowActivity: { selectedTab = .activity },
                    onShowBudget: { selectedTab = .budget }
                )
                .tag(AppTab.home)

                ActivityView()
                    .tag(AppTab.activity)

                InsightsView(onShowActivity: { selectedTab = .activity })
                    .tag(AppTab.insights)

                BudgetView()
                    .tag(AppTab.budget)

                SettingsView()
                    .tag(AppTab.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .ignoresSafeArea(edges: .bottom)

            GlassTabBar(selected: $selectedTab)
                .padding(.horizontal, AppSpacing.base)
                .padding(.bottom, 2)
        }
        .overlay(alignment: .bottomTrailing) {
            FloatingAddButton { showAddTransaction = true }
                .padding(.trailing, AppSpacing.screenMargin)
                .padding(.bottom, 96)
        }
        .overlay(alignment: .top) {
            if let message = store.errorMessage {
                ErrorToast(message: message) { store.errorMessage = nil }
            }
        }
        .animation(.snappy(duration: 0.3), value: store.errorMessage)
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .task {
            if !store.hasLoaded {
                await store.bootstrap()
            }
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
                .font(.system(size: 14))
                .foregroundColor(AppColors.warning)
            Text(message)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Spacer(minLength: 4)
            Button(action: onDismiss) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColors.textSecondary)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(AppColors.borderGlass, lineWidth: 1)
        )
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
}
