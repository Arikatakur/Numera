import SwiftUI
import Charts

struct DonutSegment: Identifiable {
    let id = UUID()
    let color: Color
    /// 0…1 share of the full circle. Segments should sum to ≤ 1.
    let fraction: Double
}

/// Native Swift Charts donut (`SectorMark`) with flat (butt) ends and small
/// gaps — Quanto Summary style (not pill-capped). Pass `onSelectSegment` to
/// make the ring tappable via the native angle selection: tapping a segment
/// reports its index, tapping it again reports nil.
struct DonutChart: View {
    let segments: [DonutSegment]
    var lineWidth: CGFloat = 18
    var selectedIndex: Int? = nil
    var onSelectSegment: ((Int?) -> Void)? = nil

    /// Cumulative angle value from the native selection gesture; transient
    /// (the system clears it when the gesture ends).
    @State private var selectedAngle: Double?

    var body: some View {
        Chart {
            ForEach(Array(segments.enumerated()), id: \.element.id) { index, segment in
                SectorMark(
                    angle: .value("Share", segment.fraction),
                    innerRadius: .inset(lineWidth),
                    angularInset: 1.2
                )
                .cornerRadius(2)
                .foregroundStyle(segment.color)
                .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.3)
            }
        }
        .chartLegend(.hidden)
        .chartBackground { proxy in
            // Empty track behind the ring, aligned to the sectors' plot frame.
            GeometryReader { geo in
                if let anchor = proxy.plotFrame {
                    let frame = geo[anchor]
                    let side = min(frame.width, frame.height)
                    Circle()
                        .stroke(AppColors.surfaceHigh.opacity(0.6), lineWidth: lineWidth)
                        .frame(width: side - lineWidth, height: side - lineWidth)
                        .position(x: frame.midX, y: frame.midY)
                }
            }
        }
        .chartAngleSelection(value: $selectedAngle)
        .onChange(of: selectedAngle) { _, angle in
            guard let angle, let onSelectSegment else { return }
            let index = segmentIndex(at: angle)
            if index != nil { Haptics.select() }
            onSelectSegment(index == selectedIndex ? nil : index)
        }
        .animation(.easeInOut(duration: 0.2), value: selectedIndex)
    }

    /// Maps the native angle selection (a cumulative fraction) to its segment.
    private func segmentIndex(at cumulative: Double) -> Int? {
        var running: Double = 0
        for (index, segment) in segments.enumerated() {
            if cumulative < running + segment.fraction { return index }
            running += segment.fraction
        }
        return nil
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
