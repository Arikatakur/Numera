import SwiftUI

struct MoneyText: View {
    let amount: Decimal
    var size: CGFloat = 34
    var color: Color = AppColors.textPrimary
    var showSign: Bool = false
    var isPrivate: Bool = false

    private var formatted: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        let str = formatter.string(from: amount as NSDecimalNumber) ?? "0.00"
        if showSign { return amount >= 0 ? "+\(str)" : "-\(str)" }
        return str
    }

    var body: some View {
        if isPrivate {
            Text("••••••")
                .moneyStyle(size: size, color: color)
        } else {
            Text(formatted)
                .moneyStyle(size: size, color: color)
        }
    }
}
