import SwiftUI

// Single home for Liquid Glass gating (see .claude/skills/liquid-glass/SKILL.md).
// Every glass surface in the app goes through `liquidGlass` — do not hand-roll
// `.glassEffect` or material approximations elsewhere.
extension View {
    /// Liquid Glass surface for the functional layer (cards, tab bar, toasts).
    /// Real `.glassEffect` when built with the iOS 26 SDK and running on
    /// iOS 26+; frosted `.ultraThinMaterial` treatment on iOS 17–25.
    @ViewBuilder
    func liquidGlass(cornerRadius: CGFloat, tintFallback: Double = 0.35) -> some View {
        // `#if compiler(>=6.2)` keeps the file compiling on pre-26 toolchains:
        // the `.glassEffect` symbol only exists in the iOS 26 SDK (Xcode 26 /
        // Swift 6.2). `#available` then gates the runtime for iOS 17–25.
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            // Real glass draws its own edge highlight — no manual stroke here.
            self.glassEffect(.regular, in: .rect(cornerRadius: cornerRadius))
        } else {
            materialFallback(cornerRadius: cornerRadius, tint: tintFallback)
        }
        #else
        materialFallback(cornerRadius: cornerRadius, tint: tintFallback)
        #endif
    }

    /// iOS 17–25 stand-in (NOT Liquid Glass): a translucent material blurs the
    /// backdrop, a dark tint adds depth on the near-black theme, and a hairline
    /// stroke traces the edge that real glass renders by itself.
    private func materialFallback(cornerRadius: CGFloat, tint: Double) -> some View {
        background(
            ZStack {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(AppColors.surfaceCard.opacity(tint))
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(AppColors.borderGlass, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    /// Interactive Liquid Glass for tappable controls on the base layer —
    /// chips, pills, search fields, floating buttons. `tint` colors the glass
    /// (Apple HIG: sparingly, for the prominent action). Never apply inside a
    /// glass card: glass must not stack on glass.
    /// Fallback: `fallbackFill` in the same shape + hairline border.
    @ViewBuilder
    func liquidGlassControl<S: Shape>(
        _ shape: S,
        tint: Color? = nil,
        fallbackFill: some ShapeStyle
    ) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            self.glassEffect(
                (tint.map { Glass.regular.tint($0) } ?? .regular).interactive(),
                in: shape
            )
        } else {
            controlFallback(shape, fill: fallbackFill)
        }
        #else
        controlFallback(shape, fill: fallbackFill)
        #endif
    }

    private func controlFallback<S: Shape>(_ shape: S, fill: some ShapeStyle) -> some View {
        background(fill, in: shape)
            .overlay(shape.stroke(AppColors.borderGlass, lineWidth: 1))
    }
}

/// Blends the glass of nearby controls (Apple's `GlassEffectContainer`) on
/// iOS 26; renders content unchanged on iOS 17–25. Wrap rows of glass chips
/// or grouped glass buttons in this.
struct LiquidGlassGroup<Content: View>: View {
    var spacing: CGFloat? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
        #else
        content()
        #endif
    }
}
