import SwiftUI

struct DonutSegment: Identifiable {
    let id = UUID()
    let color: Color
    /// 0…1 share of the full circle. Segments should sum to ≤ 1.
    let fraction: Double
}

/// Multi-segment donut with rounded caps and small gaps (Quanto Summary style).
struct DonutChart: View {
    let segments: [DonutSegment]
    var lineWidth: CGFloat = 18
    var gap: Double = 0.015

    private var startOffsets: [Double] {
        var running: Double = 0
        return segments.map { segment in
            defer { running += segment.fraction }
            return running
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.surfaceHigh.opacity(0.6), lineWidth: lineWidth)

            let starts = startOffsets
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                if segment.fraction > gap * 2 {
                    Circle()
                        .trim(
                            from: starts[index] + gap / 2,
                            to: starts[index] + segment.fraction - gap / 2
                        )
                        .stroke(segment.color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                }
            }
        }
    }
}

#Preview {
    ZStack {
        AppColors.background.ignoresSafeArea()
        DonutChart(segments: [
            DonutSegment(color: AppColors.chartPurple, fraction: 0.55),
            DonutSegment(color: AppColors.chartTeal, fraction: 0.25),
            DonutSegment(color: AppColors.chartOrange, fraction: 0.2),
        ])
        .frame(width: 220, height: 220)
    }
    .preferredColorScheme(.dark)
}
