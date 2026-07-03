import Foundation

/// A monthly spending limit. `categoryId == nil` is the overall monthly budget
/// (powers safe-to-spend); a non-nil category is a per-category limit.
struct Budget: Identifiable, Codable, Hashable {
    var id: UUID = UUID()
    var categoryId: UUID?
    var amount: Decimal
}
