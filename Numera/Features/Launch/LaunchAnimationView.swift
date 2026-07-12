import SwiftUI

// First-launch animation: monogram fades in center → glides left → NUMERA reveals A→N → tagline.
// Total sequence ≈ 2.4s, then calls onFinished() to hand off to the main app.
struct LaunchAnimationView: View {
    let onFinished: () -> Void

    // Glyph
    @State private var glyphOpacity: Double   = 0
    @State private var glyphScale: CGFloat    = 0.82
    // Positive = shifted right (glyph appears at screen center before slide)
    @State private var glyphExtraOffset: CGFloat = 72

    // Wordmark — letters [N, U, M, E, R, A] (indices 0–5)
    @State private var letterOpacity: [Double]  = Array(repeating: 0,  count: 6)
    @State private var letterOffset: [CGFloat]  = Array(repeating: 10, count: 6)

    // Tagline
    @State private var taglineOpacity: Double = 0
    @State private var taglineOffset: CGFloat = 8

    // Glow
    @State private var glowScale:   CGFloat = 1.0
    @State private var glowOpacity: Double  = 0.0

    private let letters = ["N", "U", "M", "E", "R", "A"]

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 24) {
                HStack(spacing: 16) {
                    // Glyph + glow move as one unit. The glow lives in a .background so
                    // its 180pt size never inflates the HStack — otherwise the glyph cell
                    // grows to the glow's width and shoves NUMERA far to the right.
                    Image("numera-mark")
                        .resizable()
                        .aspectRatio(64.0 / 57.0, contentMode: .fit)
                        .frame(height: 32)
                        .background(
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [
                                            AppColors.accent.opacity(0.3),
                                            AppColors.accent.opacity(0)
                                        ],
                                        center: .center,
                                        startRadius: 0,
                                        endRadius: 90
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .scaleEffect(glowScale)
                                .opacity(glowOpacity)
                        )
                        .opacity(glyphOpacity)
                        .scaleEffect(glyphScale)
                        .offset(x: glyphExtraOffset)

                    // Wordmark — each letter animates independently
                    HStack(spacing: 0) {
                        ForEach(0..<6, id: \.self) { i in
                            Text(letters[i])
                                .font(.system(size: 25, weight: .bold, design: .rounded))
                                .kerning(3.5)
                                .foregroundColor(AppColors.textPrimary)
                                .opacity(letterOpacity[i])
                                .offset(y: letterOffset[i])
                        }
                    }
                    // Measure the wordmark so we can correctly center the glyph initially
                    .background(
                        GeometryReader { proxy in
                            Color.clear
                                .preference(key: WordmarkWidthKey.self, value: proxy.size.width)
                        }
                    )
                }

                Text("Understand your money.")
                    .font(.system(size: 13.5, design: .rounded))
                    .kerning(0.54)
                    .foregroundColor(AppColors.textSecondary.opacity(0.55))
                    .opacity(taglineOpacity)
                    .offset(y: taglineOffset)
            }
        }
        .onPreferenceChange(WordmarkWidthKey.self) { width in
            if width > 0 {
                // glyphExtraOffset centers the glyph on screen:
                // the glyph's natural HStack position is -(wordmark + gap)/2 from center,
                // so add (wordmark + gap)/2 to shift it to screen center.
                glyphExtraOffset = (width + 16) / 2
            }
        }
        .task {
            await runAnimation()
        }
    }

    @MainActor
    private func runAnimation() async {
        // Allow one extra frame for PreferenceKey to propagate before starting.
        try? await Task.sleep(nanoseconds: 32_000_000)

        // ─── Phase 1: glyph appears (t = 100ms, duration 0.55s, ease-out) ───
        try? await Task.sleep(nanoseconds: 100_000_000)
        withAnimation(.easeOut(duration: 0.55)) {
            glyphOpacity = 1
            glyphScale   = 1.0
            glowOpacity  = 0.55
        }

        // ─── Phase 2: glyph slides left (t ≈ 650ms, duration 0.7s) ───
        // 650 - 100 - 32 (frame) = 518ms remaining
        try? await Task.sleep(nanoseconds: 518_000_000)
        withAnimation(.timingCurve(0.16, 0.84, 0.24, 1, duration: 0.7)) {
            glyphExtraOffset = 0
        }
        startGlowPulse()

        // ─── Phase 3: letters reveal A → R → E → M → U → N ───
        // First letter starts at t ≈ 770ms (120ms after slide begins)
        try? await Task.sleep(nanoseconds: 120_000_000)
        for (i, idx) in [5, 4, 3, 2, 1, 0].enumerated() {
            if i > 0 { try? await Task.sleep(nanoseconds: 70_000_000) }
            withAnimation(.timingCurve(0.2, 0.9, 0.3, 1, duration: 0.42)) {
                letterOpacity[idx] = 1
                letterOffset[idx]  = 0
            }
        }

        // ─── Phase 4: tagline (180ms after last letter, 0.55s ease-out) ───
        try? await Task.sleep(nanoseconds: 180_000_000)
        withAnimation(.easeOut(duration: 0.55)) {
            taglineOpacity = 1
            taglineOffset  = 0
        }

        // Settle, then hand off (~2.4s total from launch)
        try? await Task.sleep(nanoseconds: 1_100_000_000)
        onFinished()
    }

    private func startGlowPulse() {
        withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
            glowScale   = 1.12
            glowOpacity = 0.9
        }
    }
}

private struct WordmarkWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
