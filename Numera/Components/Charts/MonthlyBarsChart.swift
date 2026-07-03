import SwiftUI

struct MonthlyBarGroup: Identifiable {
    let id = UUID()
    let label: String
    let primary: Double
    let secondary: Double
    var isSelected: Bool = false
}

/// Paired rounded bars per month (income vs expenses) with tappable month
/// labels — Quanto Overview chart. Pass `secondaryHidden` for single-series.
struct MonthlyBarsChart: View {
    let groups: [MonthlyBarGroup]
    var primaryColor: Color = AppColors.accent
    var secondaryColor: Color = AppColors.chartPurple
    var secondaryHidden: Bool = false
    var height: CGFloat = 150
    var onSelect: ((Int) -> Void)?

    private var maxValue: Double {
        let all = groups.flatMap { secondaryHidden ? [$0.primary] : [$0.primary, $0.secondary] }
        return max(all.max() ?? 0, 1)
    }

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .bottom, spacing: 0) {
                ForEach(Array(groups.enumerated()), id: \.element.id) { index, group in
                    VStack(spacing: 10) {
                        HStack(alignment: .bottom, spacing: 5) {
                            bar(group.primary, primaryColor)
                            if !secondaryHidden {
                                bar(group.secondary, secondaryColor)
                            }
                        }
                        .frame(height: height, alignment: .bottom)

                        Text(group.label)
                            .font(.system(size: 12, weight: group.isSelected ? .semibold : .regular))
                            .foregroundColor(group.isSelected ? AppColors.textPrimary : AppColors.textTertiary)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(group.isSelected ? Color.white.opacity(0.09) : Color.clear)
                            .clipShape(Capsule())
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        Haptics.select()
                        onSelect?(index)
                    }
                }
            }
        }
    }

    private func bar(_ value: Double, _ color: Color) -> some View {
        Capsule(style: .continuous)
            .fill(value > 0 ? color : Color.white.opacity(0.08))
            .frame(width: 13, height: value > 0 ? max(8, height * CGFloat(value / maxValue)) : 6)
    }
}
