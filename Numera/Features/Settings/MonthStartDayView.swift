import SwiftUI

/// "Month start day" (Quanto): pick the day each budgeting month begins so
/// reports match salary cycles. Drives every period calculation in the app.
struct MonthStartDayView: View {
    @Environment(AppSettings.self) private var settings

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Specify the start day of each month so your monthly reports and summaries match your cycle.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)

                    NumeraCard(padding: AppSpacing.base) {
                        let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
                        LazyVGrid(columns: columns, spacing: 10) {
                            ForEach(1...31, id: \.self) { day in
                                dayCell(day)
                            }
                        }
                        .padding(.vertical, AppSpacing.xs)
                    }

                    if settings.monthStartDay > 28 {
                        Text("In shorter months the period starts on the last day of the month.")
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.textTertiary)
                    }

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, AppSpacing.sm)
            }
        }
        .navigationTitle("Month start day")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func dayCell(_ day: Int) -> some View {
        let isSelected = settings.monthStartDay == day
        return Button {
            Haptics.select()
            settings.monthStartDay = day
        } label: {
            Text("\(day)")
                .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                .monospacedDigit()
                .foregroundColor(isSelected ? .black : AppColors.textPrimary)
                .frame(width: 40, height: 40)
                .background(
                    Circle().fill(isSelected ? AppColors.textPrimary : Color.white.opacity(0.04))
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        MonthStartDayView()
    }
    .preferredColorScheme(.dark)
    .environment(AppSettings.shared)
}
