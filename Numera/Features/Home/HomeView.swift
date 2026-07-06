import SwiftUI

struct HomeView: View {
    let onShowInsights: () -> Void
    let onShowActivity: () -> Void
    var onShowBudget: () -> Void = {}

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(PremiumManager.self) private var premium

    @State private var pickedPeriod: Period?
    @State private var showMonthPicker = false
    @State private var showPaywall = false
    @State private var showWhatsNew = false

    /// Version whose "just got better" card was dismissed — the card returns
    /// on the next release.
    @AppStorage("whatsNewDismissedVersion") private var whatsNewDismissedVersion = ""

    private var period: Period { pickedPeriod ?? store.currentPeriod }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                        headerSection
                        whatsNewSection
                        monthCardSection
                        safeToSpendSection
                        recentActivitySection
                        Spacer().frame(height: 110)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.lg)
                    .animation(.easeInOut(duration: 0.3), value: premium.isPremium)
                }
                .refreshable { await store.bootstrap() }

                if store.isLoading && !store.hasLoaded {
                    ProgressView()
                        .tint(AppColors.accent)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showMonthPicker) {
            SelectMonthSheet(
                period: Binding(get: { period }, set: { pickedPeriod = $0 }),
                startDay: settings.monthStartDay,
                earliest: store.transactions.last?.date
            )
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showWhatsNew) {
            WhatsNewSheet()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Your money, clearly.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 2)
            }
            Spacer()
            Button { showMonthPicker = true } label: {
                HStack(spacing: 4) {
                    Text(PeriodMath.monthLabel(period))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(AppColors.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(AppColors.surfaceElevated)
                .cornerRadius(AppRadius.pill)
                .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
            }
        }
    }

    // MARK: - What's new

    @ViewBuilder
    private var whatsNewSection: some View {
        if whatsNewDismissedVersion != AppInfo.shortVersion {
            WhatsNewCard(
                onWhatsNew: { showWhatsNew = true },
                onDismiss: {
                    withAnimation(.snappy(duration: 0.3)) {
                        whatsNewDismissedVersion = AppInfo.shortVersion
                    }
                }
            )
            .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    // MARK: - Month Card

    private var topCategories: [CategoryTotal] {
        store.categoryTotals(in: period)
    }

    private var monthCardSection: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("YOUR MONTH")
                    .labelCapsStyle()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        MoneyText(amount: store.totalExpenses(in: period), size: 40)
                        changeBadge
                    }
                    Spacer()
                    miniDonutChart
                }

                Divider().background(AppColors.borderGlass)

                HStack {
                    ForEach(topCategories.prefix(2)) { item in
                        legendDot(color: Color(hex: item.category.colorHex), label: item.category.name)
                    }
                    Spacer()
                    Button { onShowInsights() } label: {
                        HStack(spacing: 4) {
                            Text("View Insights")
                                .font(.system(size: 13, weight: .semibold))
                            Image(systemName: "chevron.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundColor(AppColors.accent)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var changeBadge: some View {
        if let change = store.expenseChange(in: period) {
            let isDown = change <= 0
            HStack(spacing: AppSpacing.sm) {
                HStack(spacing: 4) {
                    Image(systemName: isDown ? "arrow.down" : "arrow.up")
                        .font(.system(size: 11, weight: .bold))
                    Text("\(abs(Int(change.rounded())))% \(isDown ? "less" : "more")")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundColor(isDown ? .black : AppColors.textPrimary)
                .padding(.horizontal, 10).padding(.vertical, 5)
                .background(isDown ? AnyShapeStyle(AppColors.accent) : AnyShapeStyle(AppColors.expense.opacity(0.35)))
                .cornerRadius(AppRadius.pill)

                Text("than last month")
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.textSecondary)
            }
        } else {
            Text("Spending this month")
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private var miniDonutChart: some View {
        let top = topCategories.prefix(3)
        let segments = top.map { DonutSegment(color: Color(hex: $0.category.colorHex), fraction: $0.share) }
        return ZStack {
            if segments.isEmpty {
                Circle().stroke(AppColors.surfaceHigh, lineWidth: 8)
            } else {
                DonutChart(segments: segments, lineWidth: 8)
            }
            Text(top.first?.category.emoji ?? "✨")
                .font(.system(size: 18))
        }
        .frame(width: 72, height: 72)
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
                .lineLimit(1)
        }
        .padding(.trailing, AppSpacing.sm)
    }

    // MARK: - Safe to Spend

    // Hidden entirely until Budget is unlocked (Pro); reappears automatically
    // when `premium.isPremium` flips. The layout change is animated in `body`.
    @ViewBuilder
    private var safeToSpendSection: some View {
        if premium.isPremium {
            unlockedSafeToSpendCard
                .transition(.opacity.combined(with: .move(edge: .top)))
        }
    }

    private var unlockedSafeToSpendCard: some View {
        NumeraCard(padding: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("SAFE TO SPEND")
                    .labelCapsStyle(color: AppColors.accent)

                if let perDay = store.safeToSpendPerDay(in: period) {
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        MoneyText(amount: perDay, size: 36)
                        Text("/ day")
                            .font(.system(size: 17))
                            .foregroundColor(AppColors.textSecondary)
                    }

                    Text("What's left of your monthly budget, split across the remaining days.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)

                    Button { onShowBudget() } label: {
                        HStack(spacing: 4) {
                            Text("Details")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    .padding(.top, AppSpacing.xs)
                } else {
                    Text("No monthly budget yet")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Set one to see how much you can safely spend each day.")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                    Button { onShowBudget() } label: {
                        HStack(spacing: 4) {
                            Text("Set budget")
                                .font(.system(size: 14, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(AppColors.accent)
                    }
                    .padding(.top, AppSpacing.xs)
                }
            }
        }
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(AppColors.accent)
                .frame(width: 3)
                .cornerRadius(2)
                .padding(.vertical, AppSpacing.md)
        }
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.hero))
    }

    // MARK: - Recent Activity

    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            HStack {
                Text("Latest Activity")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button { onShowActivity() } label: {
                    Text("SEE ALL")
                        .labelCapsStyle(color: AppColors.accent)
                }
            }

            NumeraCard(padding: 0) {
                VStack(spacing: 0) {
                    let recent = Array(store.transactions.prefix(3))
                    if recent.isEmpty {
                        Text("No transactions yet — tap + to add your first")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.xl)
                    } else {
                        ForEach(Array(recent.enumerated()), id: \.element.id) { index, tx in
                            TransactionRow(transaction: tx)
                            if index < recent.count - 1 {
                                Divider()
                                    .background(AppColors.borderGlass)
                                    .padding(.horizontal, AppSpacing.base)
                            }
                        }
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
        }
    }
}

#Preview {
    HomeView(onShowInsights: {}, onShowActivity: {})
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
        .environment(PremiumManager.preview(isPremium: true))
}
