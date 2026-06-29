import SwiftUI

struct InsightsView: View {
    @State private var isPrivate = false
    @State private var selectedMonth = "June 2026"

    private let months = ["April 2026", "May 2026", "June 2026"]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        monthScrollPicker
                            .padding(.top, AppSpacing.sm)

                        editorialInsightCard
                        weeklyTrendCard
                        distributionRow
                        highestSpendingDayCard
                        cashFlowCard
                        topCategoriesSection

                        Spacer().frame(height: 100)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                }
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { isPrivate.toggle() } label: {
                        Image(systemName: isPrivate ? "eye.slash" : "eye")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Month Scroll Picker
    private var monthScrollPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: AppSpacing.sm) {
                ForEach(months, id: \.self) { month in
                    Button { selectedMonth = month } label: {
                        Text(month)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedMonth == month ? .black : AppColors.textSecondary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(selectedMonth == month ? AppColors.accent : AppColors.surfaceCard)
                            .cornerRadius(AppRadius.pill)
                    }
                }
            }
        }
    }

    // MARK: - Editorial Insight Card
    private var editorialInsightCard: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.sm) {
                Text("PERSONALIZED INSIGHT")
                    .labelCapsStyle(color: AppColors.accent)

                Group {
                    Text("This month, food increased by ")
                        .foregroundColor(AppColors.textPrimary)
                    + Text("18%")
                        .foregroundColor(AppColors.expense)
                    + Text(", but shopping decreased by ")
                        .foregroundColor(AppColors.textPrimary)
                    + Text("12%")
                        .foregroundColor(AppColors.accent)
                    + Text(".")
                        .foregroundColor(AppColors.textPrimary)
                }
                .font(.system(size: 20, weight: .bold))
                .lineSpacing(4)

                Button {} label: {
                    HStack(spacing: 4) {
                        Text("View spending details")
                            .font(.system(size: 14, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.accent)
                }
                .padding(.top, AppSpacing.xs)
            }
        }
    }

    // MARK: - Weekly Trend Card
    private var weeklyTrendCard: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("WEEKLY TREND")
                            .labelCapsStyle()
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("$4,280")
                                .moneyStyle(size: 24)
                            Text("+4% from avg")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.accent)
                        }
                    }
                    Spacer()
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColors.textTertiary)
                }

                miniBarChart
            }
        }
    }

    private var miniBarChart: some View {
        let days = ["M","T","W","T","F","S","S"]
        let values: [CGFloat] = [0.4, 0.6, 0.9, 0.5, 0.7, 0.3, 0.2]
        return HStack(alignment: .bottom, spacing: AppSpacing.sm) {
            ForEach(Array(zip(days, values)), id: \.0) { (day, val) in
                VStack(spacing: AppSpacing.xs) {
                    Capsule()
                        .fill(day == "W" ? AppColors.accent : AppColors.surfaceHigh)
                        .frame(width: 28, height: 80 * val)
                    Text(day)
                        .font(.system(size: 11))
                        .foregroundColor(day == "W" ? AppColors.textPrimary : AppColors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Distribution Row
    private var distributionRow: some View {
        HStack(spacing: AppSpacing.base) {
            NumeraCard(padding: AppSpacing.base) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("DISTRIBUTION")
                        .labelCapsStyle()
                    ZStack {
                        Circle()
                            .stroke(AppColors.surfaceHigh, lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: 0.75)
                            .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        Text("75%")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundColor(AppColors.textPrimary)
                    }
                    .frame(width: 80, height: 80)
                    .frame(maxWidth: .infinity)
                    Text("Needs vs Wants")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            NumeraCard(padding: AppSpacing.base) {
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.expense)
                        Text("BUDGET RISK")
                            .labelCapsStyle(color: AppColors.expense)
                    }
                    Text("Dining is at 92% of limit")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                .frame(maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }

    // MARK: - Highest Spending Day
    private var highestSpendingDayCard: some View {
        NumeraCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("HIGHEST SPENDING DAY")
                        .labelCapsStyle()
                    Text("Wednesday, May 15")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Mainly electronics & lifestyle")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("$1,240")
                        .moneyStyle(size: 20, color: AppColors.textPrimary)
                    Text("OUTLIER")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(AppColors.expense)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(AppColors.expense.opacity(0.15))
                        .cornerRadius(AppRadius.pill)
                }
            }
        }
    }

    // MARK: - Cash Flow Card
    private var cashFlowCard: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("CASH FLOW ANALYSIS")
                    .labelCapsStyle()

                cashFlowRow(label: "Income",   amount: "+$12,450", color: AppColors.income,  fill: 1.0)
                cashFlowRow(label: "Expenses", amount: "-$8,230",  color: AppColors.expense, fill: 0.66)

                Divider().background(AppColors.borderGlass)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("NET SAVINGS")
                            .labelCapsStyle()
                        Text("$4,220")
                            .moneyStyle(size: 22)
                    }
                    Spacer()
                    Text("+32.4% vs last month")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(AppColors.accent)
                        .cornerRadius(AppRadius.pill)
                }
            }
        }
    }

    private func cashFlowRow(label: String, amount: String, color: Color, fill: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 5) {
                    Circle().fill(color).frame(width: 7, height: 7)
                    Text(label)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                Text(amount)
                    .font(.system(size: 14, weight: .semibold))
                    .monospacedDigit()
                    .foregroundColor(color)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(AppColors.surfaceHigh).frame(height: 6)
                    Capsule().fill(color).frame(width: geo.size.width * fill, height: 6)
                }
            }
            .frame(height: 6)
        }
    }

    // MARK: - Top Categories
    private var topCategoriesSection: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            HStack {
                Text("Top Categories")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                Button {} label: {
                    Text("VIEW ALL")
                        .labelCapsStyle(color: AppColors.accent)
                }
            }

            NumeraCard(padding: 0) {
                VStack(spacing: 0) {
                    categoryRow(icon: "fork.knife",  iconColor: AppColors.chartGreen,
                                name: "Dining & Bar", meta: "12 transactions · 28% of total", amount: "$842.00")
                    Divider().background(AppColors.borderGlass).padding(.horizontal, AppSpacing.base)
                    categoryRow(icon: "bag.fill", iconColor: AppColors.chartPurple,
                                name: "Retail Therapy", meta: "5 transactions · 14% of total", amount: "$320.50")
                }
                .padding(.vertical, AppSpacing.sm)
            }
        }
    }

    private func categoryRow(icon: String, iconColor: Color, name: String, meta: String, amount: String) -> some View {
        HStack(spacing: AppSpacing.base) {
            ZStack {
                Circle().fill(iconColor.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(iconColor)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                Text(meta)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer()
            Text(amount)
                .font(.system(size: 15, weight: .semibold))
                .monospacedDigit()
                .foregroundColor(AppColors.textPrimary)
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.md)
    }
}

#Preview {
    InsightsView()
        .preferredColorScheme(.dark)
}
