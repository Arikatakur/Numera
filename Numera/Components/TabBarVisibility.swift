import SwiftUI

/// Shared visibility flag for the floating (+) button. Pushed detail screens
/// call `.hidesTabBar()`, which hides the native tab bar the system way
/// (`.toolbar(.hidden, for: .tabBar)` — UIKit's `hidesBottomBarWhenPushed`)
/// and flags this so the floating button leaves with it.
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
            .toolbar(.hidden, for: .tabBar)
            .onAppear { TabBarVisibility.shared.isHidden = true }
            .onDisappear { TabBarVisibility.shared.isHidden = false }
    }
}

extension View {
    /// Hide the tab bar + floating add button while this view is on screen.
    /// Apply at a navigation destination (e.g. a Settings sub-page).
    func hidesTabBar() -> some View {
        modifier(HidesTabBarModifier())
    }
}
