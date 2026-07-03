import Foundation

/// Central money formatting — Quanto-style symbol-first strings ("₪1,615.82").
/// Main-thread only (NumberFormatter is not thread-safe; all callers are UI code).
enum MoneyFormatter {
    private static let number: NumberFormatter = {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.usesGroupingSeparator = true
        return f
    }()

    /// "₪1,615.82" / "−₪120" / "+₪6,200". Multi-letter symbols get a space ("AED 120").
    static func string(
        _ amount: Decimal,
        code: String,
        cents: Bool,
        signed: Bool = false
    ) -> String {
        number.minimumFractionDigits = cents ? 2 : 0
        number.maximumFractionDigits = cents ? 2 : 0
        let body = number.string(from: NSDecimalNumber(decimal: amount.magnitude)) ?? "0"
        let symbol = CurrencyInfo.symbol(for: code)
        let spacer = symbol.count > 1 ? " " : ""
        let sign = amount < 0 ? "−" : (signed && amount > 0 ? "+" : "")
        return "\(sign)\(symbol)\(spacer)\(body)"
    }

    /// Axis labels: "7k", "1.2M", "825".
    static func compact(_ value: Double) -> String {
        let magnitude = abs(value)
        let sign = value < 0 ? "−" : ""
        switch magnitude {
        case 1_000_000...:
            return sign + trimZero(String(format: "%.1f", magnitude / 1_000_000)) + "M"
        case 1_000...:
            return sign + trimZero(String(format: "%.1f", magnitude / 1_000)) + "k"
        default:
            return sign + String(format: "%.0f", magnitude)
        }
    }

    private static func trimZero(_ s: String) -> String {
        s.hasSuffix(".0") ? String(s.dropLast(2)) : s
    }
}
