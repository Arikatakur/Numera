import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case home, activity, insights, budget, settings

    var id: String { rawValue }

    var label: String {
        switch self {
        case .home:     return "Home"
        case .activity: return "Activity"
        case .insights: return "Insights"
        case .budget:   return "Budget"
        case .settings: return "Settings"
        }
    }

    /// SF Symbols matching Apple's own tab bars (HIG: filled variants for tabs).
    var icon: String {
        switch self {
        case .home:     return "house.fill"
        case .activity: return "list.bullet"
        case .insights: return "chart.pie.fill"
        case .budget:   return "wallet.pass.fill"
        case .settings: return "gearshape.fill"
        }
    }
}
