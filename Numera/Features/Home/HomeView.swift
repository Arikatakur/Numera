import SwiftUI

struct HomeView: View {
    @State private var isPrivate = false
    @State private var showAddTransaction = false
    @State private var selectedMonth = "June"

    private let transactions = MockData.transactions
    private let recentTransactions = Array(MockData.transactions.prefix(3))

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: .now)
        switch hour {
        case 5..<12:  return "Good morning,"
        case 12..<17: return "Good afternoon,"
        default:      return "Good evening,"
        }
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
                        Spacer().frame(height: 100) // tab bar clearance
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.lg)
                }
            }
            .navigationBarHidden(true)
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Saleem")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Your money, clearly.")
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.top, 2)
            }
            Spacer()
            HStack(spacing: AppSpacing.md) {
                Button { isPrivate.toggle() } label: {
                    Image(systemName: isPrivate ? "eye.slash" : "eye")
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.textSecondary)
                }
                Button {} label: {
                    Text(selectedMonth)
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

    // MARK: - Month Card
    private var monthCardSection: some View {
        NumeraCard {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                Text("YOUR MONTH")
                    .labelCapsStyle()

                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        MoneyText(amount: MockData.totalSpentThisMonth, size: 40, isPrivate: isPrivate)

                        HStack(spacing: AppSpacing.sm) {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.down")
                                    .font(.system(size: 11, weight: .bold))
                                Text("12% less")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.black)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
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

                    Button {} label: {
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
                    MoneyText(amount: MockData.safeToSpendToday, size: 36, isPrivate: isPrivate)
                    Text("/ today")
                        .font(.system(size: 17))
                        .foregroundColor(AppColors.textSecondary)
                }

                Text("Stay on track to reach your monthly goal.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)

                Button {} label: {
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
                .padding(.leading, 0)
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
                Button {} label: {
                    Text("SEE ALL")
                        .labelCapsStyle(color: AppColors.accent)
                }
            }

            NumeraCard(padding: 0) {
                VStack(spacing: 0) {
                    ForEach(Array(recentTransactions.enumerated()), id: \.element.id) { index, tx in
                        TransactionRow(transaction: tx, isPrivate: isPrivate)
                        if index < recentTransactions.count - 1 {
                            Divider()
                                .background(AppColors.borderGlass)
                                .padding(.horizontal, AppSpacing.base)
                        }
                    }
                }
                .padding(.vertical, AppSpacing.sm)
            }
        }
    }
}

#Preview {
    HomeView()
        .preferredColorScheme(.dark)
}
