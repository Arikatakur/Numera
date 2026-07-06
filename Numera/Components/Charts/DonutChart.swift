import SwiftUI

struct DonutSegment: Identifiable {
    let id = UUID()
    let color: Color
    /// 0…1 share of the full circle. Segments should sum to ≤ 1.
    let fraction: Double
}

/// Multi-segment donut with rounded caps and small gaps (Quanto Summary style).
/// Pass `onSelectSegment` to make the ring tappable: tapping a segment reports
/// its index, tapping it again (or anywhere off the ring) reports nil.
struct DonutChart: View {
    let segments: [DonutSegment]
    var lineWidth: CGFloat = 18
    var gap: Double = 0.015
    var selectedIndex: Int? = nil
    var onSelectSegment: ((Int?) -> Void)? = nil

    private var startOffsets: [Double] {
        var running: Double = 0
        return segments.map { segment in
            defer { running += segment.fraction }
            return running
        }
    }

    var body: some View {
        GeometryReader { geo in
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
                            .opacity(selectedIndex == nil || selectedIndex == index ? 1 : 0.3)
                    }
                }
            }
            .animation(.easeInOut(duration: 0.2), value: selectedIndex)
            .contentShape(Circle())
            .gesture(tapGesture(in: geo.size), including: onSelectSegment == nil ? .none : .all)
        }
    }

    private func tapGesture(in size: CGSize) -> some Gesture {
        SpatialTapGesture().onEnded { value in
            let index = segmentIndex(at: value.location, in: size)
            if index != nil { Haptics.select() }
            onSelectSegment?(index == selectedIndex ? nil : index)
        }
    }

    /// Maps a tap point to the segment under it: distance must fall on the
    /// ring band; the angle (0 at 12 o'clock, clockwise — matching the -90°
    /// rotated trims) picks the segment.
    private func segmentIndex(at point: CGPoint, in size: CGSize) -> Int? {
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let dx = point.x - center.x
        let dy = point.y - center.y
        let radius = (dx * dx + dy * dy).squareRoot()
        let ringRadius = min(size.width, size.height) / 2 - lineWidth / 2
        guard abs(radius - ringRadius) <= lineWidth else { return nil }

        var fraction = (atan2(dy, dx) + .pi / 2) / (2 * .pi)
        if fraction < 0 { fraction += 1 }

        let starts = startOffsets
        for (index, segment) in segments.enumerated()
        where fraction >= starts[index] && fraction < starts[index] + segment.fraction {
            return index
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
