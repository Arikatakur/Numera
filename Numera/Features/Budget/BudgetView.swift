import SwiftUI

/// Budgeting (Quanto-style): a big "left this month" ring for the overall
/// budget plus per-category limit cards with progress rings.
struct BudgetView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    enum EditorTarget: Identifiable {
        case overall
        case newCategory
        case edit(Budget)

        var id: String {
            switch self {
            case .overall:          return "overall"
            case .newCategory:      return "new"
            case .edit(let budget): return budget.id.uuidString
            }
        }
    }

    @State private var editorTarget: EditorTarget?

    private var period: Period { store.currentPeriod }

    private var categoryBudgets: [(budget: Budget, category: UserCategory)] {
        store.budgets.compactMap { budget in
            guard let categoryId = budget.categoryId,
                  let category = store.category(categoryId) else { return nil }
            return (budget, category)
        }
        .sorted { $0.category.sortOrder < $1.category.sortOrder }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.lg) {
                        if let overall = store.overallBudget {
                            overallCard(overall)
                        } else {
                            setBudgetCard
                        }

                        categoryGrid

                        Spacer().frame(height: 120)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.sm)
                }
                .refreshable { await store.bootstrap() }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Haptics.tap()
                        settings.isPrivate.toggle()
                    } label: {
                        Image(systemName: settings.isPrivate ? "eye.slash" : "eye")
                            .foregroundColor(AppColors.textSecondary)
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .sheet(item: $editorTarget) { target in
            BudgetEditSheet(target: target)
        }
    }

    // MARK: - Overall

    private func overallCard(_ overall: Budget) -> some View {
        let spent = store.totalExpenses(in: period)
        let remaining = overall.amount - spent
        let spentFraction = overall.amount > 0
            ? ((spent / overall.amount) as NSDecimalNumber).doubleValue
            : 0
        let remainingFraction = max(0, 1 - spentFraction)

        return NumeraCard {
            VStack(spacing: AppSpacing.base) {
                HStack {
                    Text(PeriodMath.monthLabel(period).uppercased())
                        .labelCapsStyle()
                    Spacer()
                    Button {
                        editorTarget = .edit(overall)
                    } label: {
                        Image(systemName: "pencil")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColors.textSecondary)
                            .frame(width: 34, height: 34)
                            .background(Color.white.opacity(0.06))
                            .clipShape(Circle())
                    }
                }

                ZStack {
                    BudgetRing(
                        progress: remainingFraction,
                        color: remaining < 0 ? AppColors.danger : AppColors.accent,
                        lineWidth: 14
                    )
                    VStack(spacing: 5) {
                        Text("Left this month")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.textSecondary)
                        MoneyText(
                            amount: remaining,
                            size: 32,
                            color: remaining < 0 ? AppColors.expense : AppColors.textPrimary
                        )
                        HStack(spacing: 4) {
                            MoneyText(amount: spent, size: 13, color: AppColors.textSecondary)
                            Text("/")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textTertiary)
                            MoneyText(amount: overall.amount, size: 13, color: AppColors.textSecondary)
                        }
                    }
                }
                .frame(width: 210, height: 210)
                .padding(.vertical, AppSpacing.sm)
            }
        }
    }

    private var setBudgetCard: some View {
        NumeraCard {
            VStack(spacing: AppSpacing.base) {
                Image(systemName: "target")
                    .font(.system(size: 34))
                    .foregroundColor(AppColors.accent)
                Text("Budgeting")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                Text("Set a monthly limit and see what's safe to spend every day.")
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                PrimaryButton(title: "Set monthly budget") {
                    editorTarget = .overall
                }
                .padding(.top, AppSpacing.xs)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.sm)
        }
    }

    // MARK: - Category budgets

    private var categoryGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            Text("Category limits")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

            let columns = [GridItem(.flexible(), spacing: AppSpacing.md), GridItem(.flexible(), spacing: AppSpacing.md)]
            LazyVGrid(columns: columns, spacing: AppSpacing.md) {
                ForEach(categoryBudgets, id: \.budget.id) { entry in
                    categoryCard(entry.budget, entry.category)
                }
                addCategoryCard
            }
        }
    }

    private func categoryCard(_ budget: Budget, _ category: UserCategory) -> some View {
        let spent = store.spent(categoryId: category.id, in: period)
        let remaining = budget.amount - spent
        let spentFraction = budget.amount > 0
            ? ((spent / budget.amount) as NSDecimalNumber).doubleValue
            : 0

        return Button {
            editorTarget = .edit(budget)
        } label: {
            VStack(spacing: AppSpacing.md) {
                ZStack {
                    BudgetRing(
                        progress: max(0, 1 - spentFraction),
                        color: spentFraction > 1 ? AppColors.danger : Color(hex: category.colorHex),
                        lineWidth: 7
                    )
                    .frame(width: 72, height: 72)
                    Text(category.emoji)
                        .font(.system(size: 26))
                }

                VStack(spacing: 2) {
                    MoneyText(
                        amount: remaining,
                        size: 18,
                        color: remaining < 0 ? AppColors.expense : AppColors.textPrimary
                    )
                    Text(remaining < 0 ? "\(category.name) over" : "\(category.name) left")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppColors.borderSubtle, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var addCategoryCard: some View {
        Button {
            editorTarget = .newCategory
        } label: {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(AppColors.accent.opacity(0.12)))
                Text("Add limit")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .background(AppColors.surfaceCard.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .strokeBorder(AppColors.borderGlass, style: StrokeStyle(lineWidth: 1, dash: [6, 5]))
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Editor sheet

struct BudgetEditSheet: View {
    let target: BudgetView.EditorTarget

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var amountText: String
    @State private var selectedCategoryId: UUID?
    @State private var showDeleteConfirm = false

    init(target: BudgetView.EditorTarget) {
        self.target = target
        switch target {
        case .edit(let budget):
            _amountText = State(initialValue: "\(budget.amount)")
            _selectedCategoryId = State(initialValue: budget.categoryId)
        case .overall, .newCategory:
            _amountText = State(initialValue: "")
            _selectedCategoryId = State(initialValue: nil)
        }
    }

    private var isOverall: Bool {
        switch target {
        case .overall:          return true
        case .newCategory:      return false
        case .edit(let budget): return budget.categoryId == nil
        }
    }

    /// Expense categories that don't have a limit yet (for the new-limit picker).
    private var availableCategories: [UserCategory] {
        store.categories(of: .expense).filter { category in
            store.budget(for: category.id) == nil
        }
    }

    private var amount: Decimal {
        Decimal(string: amountText.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    private var canSave: Bool {
        amount > 0 && (isOverall || activeCategoryId != nil)
    }

    private var activeCategoryId: UUID? {
        if case .edit(let budget) = target { return budget.categoryId }
        if case .overall = target { return nil }
        return selectedCategoryId ?? availableCategories.first?.id
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: AppSpacing.xl) {
                    if !isOverall {
                        categoryPicker
                    }

                    amountField

                    PrimaryButton(title: "Save") { save() }
                        .opacity(canSave ? 1 : 0.4)
                        .disabled(!canSave)

                    if case .edit(let budget) = target {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text(budget.categoryId == nil ? "Remove monthly budget" : "Remove limit")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(AppColors.danger)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, AppSpacing.xl)
            }
            .navigationTitle(isOverall ? "Monthly budget" : "Category limit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.height(isOverall ? 320 : 400)])
        .confirmationDialog("Remove this budget?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Remove", role: .destructive) {
                if case .edit(let budget) = target {
                    Haptics.warning()
                    Task { await store.deleteBudget(id: budget.id) }
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var categoryPicker: some View {
        let options: [UserCategory]
        let isLocked: Bool
        if case .edit = target {
            options = store.category(activeCategoryId).map { [$0] } ?? []
            isLocked = true
        } else {
            options = availableCategories
            isLocked = false
        }

        return Menu {
            ForEach(options) { category in
                Button("\(category.emoji) \(category.name)") {
                    selectedCategoryId = category.id
                }
            }
        } label: {
            HStack(spacing: AppSpacing.md) {
                if let category = store.category(activeCategoryId) {
                    EmojiIconTile(emoji: category.emoji, colorHex: category.colorHex, size: 40)
                    Text(category.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("Pick a category")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if !isLocked {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.base)
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColors.borderGlass, lineWidth: 1)
            )
        }
        .disabled(isLocked)
    }

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(settings.currencySymbol)
                .font(.system(size: 26, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .font(.system(size: 44, weight: .bold))
                .monospacedDigit()
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.accent)
                .fixedSize(horizontal: true, vertical: false)
        }
        .frame(maxWidth: .infinity)
    }

    private func save() {
        guard canSave else { return }
        Haptics.success()
        let categoryId = isOverall ? nil : activeCategoryId
        Task { await store.setBudget(categoryId: categoryId, amount: amount) }
        dismiss()
    }
}

#Preview {
    BudgetView()
        .preferredColorScheme(.dark)
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
}
