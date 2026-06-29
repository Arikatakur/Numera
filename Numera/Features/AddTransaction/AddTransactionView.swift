import SwiftUI

struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var transactionType: TransactionType = .expense
    @State private var amountString = "0"
    @State private var selectedCategory: Category = .food
    @State private var selectedAccount = "Cash Account"
    @State private var selectedDate = Date()
    @State private var note = ""
    @State private var showCategoryPicker = false

    private var displayAmount: String {
        let val = Double(amountString) ?? 0
        return String(format: "%.2f", val)
    }

    private let quickCategories: [Category] = [.food, .coffee, .transport, .groceries, .leisure, .health, .shopping, .other]

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    typeToggle
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.lg)

                    amountDisplay
                        .padding(.top, AppSpacing.xl)

                    contextPills
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.lg)

                    noteField
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.base)

                    categoryGrid
                        .padding(.top, AppSpacing.lg)

                    Spacer()

                    keypad
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
                ToolbarItem(placement: .principal) {
                    Text("New Entry")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { dismiss() }
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Type Toggle
    private var typeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        transactionType = type
                    }
                } label: {
                    Text(type.rawValue.uppercased())
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(transactionType == type ? .black : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(transactionType == type ? AppColors.accent : Color.clear)
                        .cornerRadius(AppRadius.pill)
                }
            }
        }
        .padding(4)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.pill)
        .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
    }

    // MARK: - Amount Display
    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("$")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            Text(displayAmount)
                .font(.system(size: 56, weight: .bold))
                .monospacedDigit()
                .foregroundColor(AppColors.textPrimary)
                .tracking(-1)
                .minimumScaleFactor(0.5)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Context Pills
    private var contextPills: some View {
        HStack(spacing: AppSpacing.sm) {
            contextPill(icon: "banknote", label: selectedAccount)
            contextPill(icon: "calendar", label: "Today")
        }
    }

    private func contextPill(icon: String, label: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13))
                .foregroundColor(AppColors.textSecondary)
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
            Image(systemName: "chevron.down")
                .font(.system(size: 11))
                .foregroundColor(AppColors.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.pill)
        .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
    }

    // MARK: - Note Field
    private var noteField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)
            TextField("What was this for?", text: $note)
                .font(.system(size: 15))
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.accent)
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, 14)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.card)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).stroke(AppColors.borderGlass, lineWidth: 1))
    }

    // MARK: - Category Grid
    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            HStack {
                Text("SELECT CATEGORY")
                    .labelCapsStyle()
                    .padding(.horizontal, AppSpacing.screenMargin)
                Spacer()
                Button {} label: {
                    Text("VIEW ALL")
                        .labelCapsStyle(color: AppColors.accent)
                }
                .padding(.horizontal, AppSpacing.screenMargin)
            }

            let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
            LazyVGrid(columns: columns, spacing: AppSpacing.base) {
                ForEach(quickCategories) { cat in
                    categoryCell(cat)
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
        }
    }

    private func categoryCell(_ cat: Category) -> some View {
        let isSelected = selectedCategory == cat
        return Button {
            selectedCategory = cat
        } label: {
            VStack(spacing: AppSpacing.sm) {
                ZStack {
                    RoundedRectangle(cornerRadius: AppRadius.md)
                        .fill(isSelected ? AppColors.accent : AppColors.surfaceCard)
                        .frame(width: 64, height: 64)
                    Image(systemName: cat.sfSymbol)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(isSelected ? .black : AppColors.textSecondary)
                }
                Text(cat.rawValue)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
            }
        }
    }

    // MARK: - Keypad
    private var keypad: some View {
        let keys = ["1","2","3","4","5","6","7","8","9",".","0","⌫"]
        let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]
        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(keys, id: \.self) { key in
                Button {
                    handleKey(key)
                } label: {
                    Text(key)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 64)
                }
            }
        }
        .background(AppColors.background)
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if amountString.count > 1 { amountString.removeLast() } else { amountString = "0" }
        case ".":
            if !amountString.contains(".") { amountString += "." }
        default:
            if amountString == "0" { amountString = key } else { amountString += key }
        }
    }
}

#Preview {
    AddTransactionView()
}
