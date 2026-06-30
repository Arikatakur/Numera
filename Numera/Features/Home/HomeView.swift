import SwiftUI

struct HomeView: View {
    let onShowInsights: () -> Void
    let onShowActivity: () -> Void

    @Environment(AuthManager.self)    private var authManager
    @Environment(TransactionStore.self) private var store
    @Environment(AppSettings.self)   private var settings

    @State private var displayMonth  = Date()
    @State private var showMonthPicker = false
    @State private var showAddTransaction = false

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default:      return "Good evening,"
        }
    }

    private var displayName: String {
        let email = authManager.currentUserEmail ?? ""
        let username = email.split(separator: "@").first.map(String.init) ?? "there"
        return username.prefix(1).uppercased() + username.dropFirst()
    }

    private var monthLabel: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM"
        return fmt.string(from: displayMonth)
    }

    private var recentMonths: [Date] {
        (0..<6).compactMap { Calendar.current.date(byAdding: .month, value: -$0, to: .now) }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.sectionGap) {
                        headerSection
                        monthCardSection
                        safeToSpendSection
                        recentActivitySection
                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.lg)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showAddTransaction) {
            AddTransactionView()
        }
        .sheet(isPresented: $showMonthPicker) {
            monthPickerSheet
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text(displayName)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Your money, clearly.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 2)
            }
            Spacer()
            HStack(spacing: AppSpacing.md) {
                Button { settings.isPrivate.toggle() } label: {
                    Image(systemName: settings.isPrivate ? "eye.slash" : "eye")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textSecondary)
                }
                Button { showMonthPicker = true } label: {
                    HStack(spacing: 4) {
                        Text(monthLabel)
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
    }

    // MARK: - Month Card

    private var monthCardSection: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("YOUR MONTH")
                    .labelCapsStyle()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        MoneyText(amount: store.totalSpent(forMonth: displayMonth), size: 40, isPrivate: settings.isPrivate)

                        HStack(spacing: AppSpacing.sm) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 11, weight: .bold))
                                Text("12% less")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10).padding(.vertical, 5)
                            .background(AppColors.accent)
                            .cornerRadius(AppRadius.pill)

                            Text("than last month")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                    Spacer()
                    miniDonutChart
                }

                Divider().background(AppColors.borderGlass)

                HStack {
                    legendDot(color: AppColors.chartGreen,  label: "Dining")
                    legendDot(color: AppColors.chartPurple, label: "Tech")
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

    private var miniDonutChart: some View {
        ZStack {
            Circle()
                .stroke(AppColors.surfaceHigh, lineWidth: 8)
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0, to: 0.55)
                .stroke(AppColors.chartGreen, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0.55, to: 0.75)
                .stroke(AppColors.chartPurple, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 72, height: 72)
            Circle()
                .trim(from: 0.75, to: 0.88)
                .stroke(AppColors.chartOrange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 72, height: 72)
            Image(systemName: "fork.knife")
                .font(.system(size: 14))
                .foregroundColor(AppColors.textSecondary)
        }
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.trailing, AppSpacing.sm)
    }

    // MARK: - Safe to Spend

    private var safeToSpendSection: some View {
        NumeraCard(padding: AppSpacing.xl) {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("SAFE TO SPEND")
                    .labelCapsStyle(color: AppColors.accent)

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    MoneyText(amount: store.safeToSpend(forMonth: displayMonth), size: 36, isPrivate: settings.isPrivate)
                    Text("/ today")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.textSecondary)
                }

                Text("Stay on track to reach your monthly goal.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                Button { onShowInsights() } label: {
                    HStack(spacing: 4) {
                        Text("Details")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.accent)
                }
                .padding(.top, AppSpacing.xs)
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
                    let recent = store.recentTransactions
                    if recent.isEmpty {
                        Text("No transactions yet")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(AppSpacing.xl)
                    } else {
                        ForEach(Array(recent.enumerated()), id: \.element.id) { index, tx in
                            TransactionRow(transaction: tx, isPrivate: settings.isPrivate)
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

    // MARK: - Month Picker Sheet

    private var monthPickerSheet: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ForEach(recentMonths, id: \.self) { month in
                        let fmt: DateFormatter = {
                            let f = DateFormatter()
                            f.dateFormat = "MMMM yyyy"
                            return f
                        }()
                        Button {
                            displayMonth = month
                            showMonthPicker = false
                        } label: {
                            HStack {
                                Text(fmt.string(from: month))
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if Calendar.current.isDate(month, equalTo: displayMonth, toGranularity: .month) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            .padding(.horizontal, AppSpacing.screenMargin)
                            .padding(.vertical, AppSpacing.base)
                        }
                        Divider().background(AppColors.borderGlass)
                    }
                    Spacer()
                }
                .padding(.top, AppSpacing.sm)
            }
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showMonthPicker = false }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }
}

#Preview {
    HomeView(onShowInsights: {}, onShowActivity: {})
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(TransactionStore())
        .environment(AppSettings())
}
