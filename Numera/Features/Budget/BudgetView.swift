import SwiftUI

/// Budgeting (Quanto-style): a big "left this month" ring for the overall
/// budget plus per-category limit cards with progress rings.
struct BudgetView: View {
    @Environment(DataStore.self) private var store
    @Environment(PremiumManager.self) private var premium

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
    @State private var showPaywall = false

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

                if premium.isPremium {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppSpacing.lg) {
                            if let overall = store.overallBudget {
                                overallCard(overall)
                            } else {
                                setBudgetCard
                            }

                            categoryGrid

                            Spacer().frame(height: 80)
                        }
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.xs)
                    }
                    .refreshable { await store.bootstrap() }
                } else {
                    lockedView
                }
            }
            .navigationTitle("Budget")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(item: $editorTarget) { target in
            BudgetEditSheet(target: target)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }

    // MARK: - Locked (premium)

    /// Quanto-style budgeting lock screen: mock ring + pitch + unlock CTA.
    private var lockedView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: AppSpacing.xl) {
                ZStack {
                    BudgetRing(progress: 0.72, color: AppColors.accent, lineWidth: 14)
                    VStack(spacing: 5) {
                        Text("Left this month")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        Text("$1,320")
                            .moneyStyle(size: 32)
                        Text("$680 / $2,000")
                            .font(.system(size: 13, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .frame(width: 210, height: 210)
                .padding(.top, AppSpacing.xl)

                VStack(spacing: AppSpacing.sm) {
                    Text("Budgeting")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                    Text("Set limits to how much you want to spend on each category.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .multilineTextAlignment(.center)
                }

                UnlockGradientButton(title: "Unlock") {
                    showPaywall = true
                }
                .padding(.horizontal, AppSpacing.xxl)

                Spacer().frame(height: 80)
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.top, AppSpacing.sm)
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

        // The whole card opens the editor (which shows this card with the
        // edit controls inside) — no pencil badge.
        return Button {
            editorTarget = .edit(overall)
        } label: {
            NumeraCard {
            VStack(spacing: AppSpacing.base) {
                HStack {
                    Text(PeriodMath.monthLabel(period).uppercased())
                        .labelCapsStyle()
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }

                ZStack {
                    BudgetRing(
                        progress: remainingFraction,
                        color: remaining < 0 ? AppColors.danger : AppColors.accent,
                        lineWidth: 14
                    )
                    VStack(spacing: 5) {
                        Text("Left this month")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        MoneyText(
                            amount: remaining,
                            size: 32,
                            color: remaining < 0 ? AppColors.expense : AppColors.textPrimary
                        )
                        HStack(spacing: 4) {
                            MoneyText(amount: spent, size: 13, color: AppColors.textSecondary)
                            Text("/")
                                .font(.system(size: 13, design: .rounded))
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
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editorTarget = .edit(overall)
            } label: {
                Label("Edit budget", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Haptics.warning()
                Task { await store.deleteBudget(id: overall.id) }
            } label: {
                Label("Remove budget", systemImage: "trash")
            }
        }
    }

    private var setBudgetCard: some View {
        NumeraCard {
            VStack(spacing: AppSpacing.base) {
                Image(systemName: "target")
                    .font(.system(size: 34, design: .rounded))
                    .foregroundColor(AppColors.accent)
                Text("Budgeting")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("Set a monthly limit and see what's safe to spend every day.")
                    .font(.system(size: 14, design: .rounded))
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
                .font(.system(size: 20, weight: .bold, design: .rounded))
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
                        .font(.system(size: 26, design: .rounded))
                }

                VStack(spacing: 2) {
                    MoneyText(
                        amount: remaining,
                        size: 18,
                        color: remaining < 0 ? AppColors.expense : AppColors.textPrimary
                    )
                    Text(remaining < 0 ? "\(category.name) over" : "\(category.name) left")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .liquidGlass(cornerRadius: AppRadius.card)
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button {
                editorTarget = .edit(budget)
            } label: {
                Label("Edit limit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                Haptics.warning()
                Task { await store.deleteBudget(id: budget.id) }
            } label: {
                Label("Remove limit", systemImage: "trash")
            }
        }
    }

    private var addCategoryCard: some View {
        Button {
            editorTarget = .newCategory
        } label: {
            VStack(spacing: AppSpacing.md) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 72, height: 72)
                    .background(Circle().fill(AppColors.accent.opacity(0.12)))
                Text("Add limit")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, AppSpacing.lg)
            .liquidGlass(cornerRadius: AppRadius.card, tintFallback: 0.2)
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
    @FocusState private var amountFocused: Bool

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

                VStack(spacing: 0) {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: AppSpacing.lg) {
                            // The budget card itself, editing inline: the ring
                            // preview follows the amount as you type.
                            cardPreview

                            if !isOverall {
                                categoryPicker
                            }

                            amountField
                        }
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.base)
                        .padding(.bottom, AppSpacing.base)
                    }
                    .scrollDismissesKeyboard(.interactively)

                    // Actions pinned below the scroll area: the amount field
                    // auto-focuses, so Save used to sit under the keypad and
                    // needed several taps. Pinned, it stays above the keyboard
                    // and fires on the first tap.
                    VStack(spacing: AppSpacing.md) {
                        PrimaryButton(title: "Save") { save() }
                            .opacity(canSave ? 1 : 0.4)
                            .disabled(!canSave)

                        if case .edit(let budget) = target {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Text(budget.categoryId == nil ? "Remove monthly budget" : "Remove limit")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.danger)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.sm)
                    .padding(.bottom, AppSpacing.base)
                    .background(AppColors.background)
                }
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
        .presentationDetents([.height(isOverall ? 560 : 620), .large])
        .presentationDragIndicator(.visible)
        .onAppear {
            // New budgets go straight to typing; editing shows the card first.
            switch target {
            case .edit: break
            case .overall, .newCategory: amountFocused = true
            }
        }
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

    // MARK: - Card preview (the card, editing inside)

    /// Live version of the tapped budget card: same ring, same numbers,
    /// recomputed from the amount field as you type.
    @ViewBuilder
    private var cardPreview: some View {
        let period = store.currentPeriod
        if isOverall {
            let spent = store.totalExpenses(in: period)
            ringPreview(
                spent: spent,
                limit: amount,
                color: AppColors.accent,
                emoji: nil,
                caption: "Left this month"
            )
        } else if let category = store.category(activeCategoryId) {
            let spent = store.spent(categoryId: category.id, in: period)
            ringPreview(
                spent: spent,
                limit: amount,
                color: Color(hex: category.colorHex),
                emoji: category.emoji,
                caption: "\(category.name) left"
            )
        }
    }

    private func ringPreview(spent: Decimal, limit: Decimal, color: Color, emoji: String?, caption: String) -> some View {
        // Until an amount is entered there's no budget to show — keep the ring
        // empty and the number a placeholder rather than a scary "−spent over".
        let hasLimit = limit > 0
        let remaining = limit - spent
        let spentFraction = hasLimit ? ((spent / limit) as NSDecimalNumber).doubleValue : 0
        let remainingFraction = hasLimit ? max(0, 1 - spentFraction) : 0

        return VStack(spacing: AppSpacing.md) {
            ZStack {
                BudgetRing(
                    progress: remainingFraction,
                    color: !hasLimit ? AppColors.surfaceHigh : (remaining < 0 ? AppColors.danger : color),
                    lineWidth: 10
                )
                .frame(width: 132, height: 132)

                VStack(spacing: 3) {
                    if let emoji {
                        Text(emoji)
                            .font(.system(size: 22, design: .rounded))
                    }
                    if hasLimit {
                        MoneyText(
                            amount: remaining,
                            size: 22,
                            color: remaining < 0 ? AppColors.expense : AppColors.textPrimary
                        )
                    } else {
                        Text("—")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }

            VStack(spacing: 2) {
                Text(hasLimit && remaining < 0 ? caption.replacingOccurrences(of: " left", with: " over") : caption)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                HStack(spacing: 4) {
                    MoneyText(amount: spent, size: 12, color: AppColors.textTertiary)
                    Text("/")
                        .font(.system(size: 12, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                    if hasLimit {
                        MoneyText(amount: limit, size: 12, color: AppColors.textTertiary)
                    } else {
                        Text("—")
                            .font(.system(size: 12, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AppSpacing.lg)
        .liquidGlass(cornerRadius: AppRadius.card)
        .animation(.snappy(duration: 0.25), value: amountText)
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
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                } else {
                    Text("Pick a category")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
                if !isLocked {
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(AppSpacing.base)
            .liquidGlass(cornerRadius: AppRadius.lg)
        }
        .disabled(isLocked)
    }

    private var amountField: some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(settings.currencySymbol)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
            TextField("0", text: $amountText)
                .keyboardType(.decimalPad)
                .focused($amountFocused)
                .font(.system(size: 44, weight: .bold, design: .rounded))
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
        .environment(PremiumManager.preview(isPremium: true))
}
