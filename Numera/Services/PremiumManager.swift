import Foundation
import StoreKit

// Note: StoreKit's Transaction collides with Numera's Transaction model —
// always qualify as StoreKit.Transaction in this file.

enum PremiumProduct: String, CaseIterable {
    case monthly  = "org.clientvault.numera.pro.monthly.v2"
    case yearly   = "org.clientvault.numera.pro.yearly.v2"
    case lifetime = "org.clientvault.numera.pro.lifetime"

    /// Tier order for upgrade/downgrade comparison: monthly < yearly < lifetime.
    var rank: Int {
        switch self {
        case .monthly:  return 0
        case .yearly:   return 1
        case .lifetime: return 2
        }
    }
}

/// StoreKit 2 subscription state. Entitlements are the on-device source of
/// truth — no server-side receipt validation (privacy-first, local-only).
@MainActor
@Observable
final class PremiumManager {
    /// True when any Numera Pro entitlement (subscription or lifetime) is active.
    private(set) var isPremium = false
    /// The plan the user currently owns, if any. Lifetime takes precedence when
    /// (unusually) both a subscription and lifetime are active. Drives the
    /// paywall's manage / upgrade / downgrade states.
    private(set) var activeProduct: PremiumProduct?
    /// Loaded products in fixed order: monthly, yearly, lifetime.
    private(set) var products: [Product] = []
    /// True once the product request finished (even if it returned nothing —
    /// e.g. products not yet configured in App Store Connect).
    private(set) var hasLoadedProducts = false
    var isPurchasing = false
    var purchaseError: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    /// For previews and locked-state UI work.
    static func preview(isPremium: Bool = false, active: PremiumProduct? = nil) -> PremiumManager {
        let manager = PremiumManager()
        manager.isPremium = isPremium
        manager.activeProduct = active ?? (isPremium ? .yearly : nil)
        manager.hasLoadedProducts = true
        return manager
    }

    deinit {
        updatesTask?.cancel()
    }

    // MARK: - Lifecycle

    func start() async {
        // React to renewals, refunds, and purchases made outside the app.
        updatesTask?.cancel()
        updatesTask = Task { [weak self] in
            for await update in StoreKit.Transaction.updates {
                if case .verified(let transaction) = update {
                    await transaction.finish()
                    await self?.refreshEntitlements()
                }
            }
        }
        await loadProducts()
        await refreshEntitlements()
    }

    func loadProducts() async {
        do {
            let loaded = try await Product.products(for: PremiumProduct.allCases.map(\.rawValue))
            products = PremiumProduct.allCases.compactMap { product in
                loaded.first { $0.id == product.rawValue }
            }
        } catch {
            products = []
            #if DEBUG
            print("[PremiumManager] product load failed — \(error)")
            #endif
        }
        hasLoadedProducts = true
    }

    func refreshEntitlements() async {
        var active: PremiumProduct?
        for await entitlement in StoreKit.Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement,
                  transaction.revocationDate == nil,
                  let product = PremiumProduct(rawValue: transaction.productID) else { continue }
            // Lifetime always wins; otherwise take the active subscription.
            if product == .lifetime || active == nil {
                active = product
            }
        }
        activeProduct = active
        isPremium = active != nil
    }

    // MARK: - Purchasing

    /// Returns true when the purchase completed and premium is active.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        guard !isPurchasing else { return false }
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    purchaseError = "The purchase couldn't be verified."
                    return false
                }
                await transaction.finish()
                await refreshEntitlements()
                return isPremium
            case .userCancelled:
                return false
            case .pending:
                purchaseError = "The purchase is awaiting approval (Ask to Buy)."
                return false
            @unknown default:
                return false
            }
        } catch {
            purchaseError = "The purchase failed — please try again."
            return false
        }
    }

    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
        if !isPremium {
            purchaseError = "No previous purchases found for this Apple ID."
        }
    }

    // MARK: - Display helpers

    var monthlyProduct: Product? { product(.monthly) }
    var yearlyProduct: Product? { product(.yearly) }
    var lifetimeProduct: Product? { product(.lifetime) }

    func product(_ id: PremiumProduct) -> Product? {
        products.first { $0.id == id.rawValue }
    }

    /// "Save 24%" — yearly vs 12× monthly, when both prices are known.
    var yearlySavingsPercent: Int? {
        guard let monthly = monthlyProduct?.price,
              let yearly = yearlyProduct?.price,
              monthly > 0 else { return nil }
        let full = monthly * 12
        guard full > yearly else { return nil }
        let ratio = ((full - yearly) / full * 100) as NSDecimalNumber
        return Int(ratio.doubleValue.rounded())
    }
}
