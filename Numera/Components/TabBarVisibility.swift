import SwiftUI

/// Shared visibility flag for the app's floating chrome (GlassTabBar +
/// FloatingAddButton). Pushed detail screens call `.hidesTabBar()` so the
/// floating bar doesn't overlap them — mirroring UIKit's
/// `hidesBottomBarWhenPushed`. The top-level Settings list intentionally keeps
/// the bar (its layout reserves space for it); only its sub-pages hide it.
@MainActor
@Observable
final class TabBarVisibility {
    static let shared = TabBarVisibility()
    var isHidden = false
    private init() {}
}

private struct HidesTabBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear { TabBarVisibility.shared.isHidden = true }
            .onDisappear { TabBarVisibility.shared.isHidden = false }
    }
}

extension View {
    /// Hide the floating tab bar + add button while this view is on screen.
    /// Apply at a navigation destination (e.g. a Settings sub-page).
    func hidesTabBar() -> some View {
        modifier(HidesTabBarModifier())
    }
}
