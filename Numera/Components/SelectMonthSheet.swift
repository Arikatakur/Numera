import SwiftUI

/// Quanto-style "Select date" sheet: a row of year pills and a month grid.
/// Future months are disabled; picking a month rebuilds the bound period.
struct SelectMonthSheet: View {
    @Binding var period: Period
    let startDay: Int
    /// Earliest selectable date (usually the oldest transaction). Controls the year row.
    var earliest: Date?

    @Environment(\.dismiss) private var dismiss
    @State private var selectedYear: Int

    init(period: Binding<Period>, startDay: Int, earliest: Date? = nil) {
        _period = period
        self.startDay = startDay
        self.earliest = earliest
        _selectedYear = State(initialValue: Calendar.current.component(.year, from: period.wrappedValue.start))
    }

    private var years: [Int] {
        let current = Calendar.current.component(.year, from: .now)
        let first = earliest.map { Calendar.current.component(.year, from: $0) } ?? current - 3
        return Array(min(first, current)...current).reversed()
    }

    private var monthSymbols: [String] {
        DateFormatter().shortMonthSymbols ?? []
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.xl) {
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 40, height: 4)
                    .padding(.top, AppSpacing.md)

                Text("Select date")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: AppSpacing.sm) {
                        ForEach(years, id: \.self) { year in
                            yearPill(year)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                }

                let columns = Array(repeating: GridItem(.flexible(), spacing: AppSpacing.md), count: 3)
                LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                    ForEach(1...12, id: \.self) { month in
                        monthCell(month)
                    }
                }
                .padding(.horizontal, AppSpacing.screenMargin)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
    }

    private func yearPill(_ year: Int) -> some View {
        let isSelected = year == selectedYear
        return Button {
            Haptics.select()
            selectedYear = year
        } label: {
            Text(String(year))
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.textPrimary)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .liquidGlassControl(Capsule(), fallbackFill: AppColors.surfaceElevated)
                .overlay(
                    Capsule().stroke(
                        isSelected ? AppColors.accent : Color.clear,
                        lineWidth: 1.5
                    )
                )
        }
    }

    private func monthCell(_ month: Int) -> some View {
        let target = PeriodMath.period(year: selectedYear, month: month, startDay: startDay)
        let isSelected = target == period
        let isFuture = target.start > .now
        return Button {
            Haptics.tap()
            period = target
            dismiss()
        } label: {
            Text(monthSymbols.indices.contains(month - 1) ? monthSymbols[month - 1] : "\(month)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(isFuture ? AppColors.textTertiary.opacity(0.5) : AppColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .liquidGlassControl(Capsule(), fallbackFill: AppColors.surfaceElevated.opacity(isFuture ? 0.4 : 1))
                .overlay(
                    Capsule().stroke(
                        isSelected ? AppColors.accent : Color.clear,
                        lineWidth: 1.5
                    )
                )
                .opacity(isFuture ? 0.55 : 1)
        }
        .disabled(isFuture)
    }
}
