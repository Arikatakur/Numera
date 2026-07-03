import SwiftUI

/// Add or edit a transaction. Pass `editing` to prefill and enable delete.
struct AddTransactionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    let editing: Transaction?

    @State private var transactionType: TransactionType
    @State private var amountString: String
    @State private var selectedCategoryId: UUID?
    @State private var selectedAccountId: UUID?
    @State private var selectedDate: Date
    @State private var titleText: String
    @State private var showDatePicker = false
    @State private var showAccountPicker = false
    @State private var showAllCategories = false
    @State private var showDeleteConfirm = false

    init(editing: Transaction? = nil) {
        self.editing = editing
        _transactionType = State(initialValue: editing?.type ?? .expense)
        _amountString = State(initialValue: editing.map { "\($0.amount)" } ?? "0")
        _selectedCategoryId = State(initialValue: editing?.categoryId)
        _selectedAccountId = State(initialValue: editing?.accountId)
        _selectedDate = State(initialValue: editing?.date ?? Date())
        _titleText = State(initialValue: editing?.title ?? "")
    }

    // MARK: - Derived

    private var kindForType: CategoryKind? {
        switch transactionType {
        case .expense:  return .expense
        case .income:   return .income
        case .transfer: return nil
        }
    }

    private var kindCategories: [UserCategory] {
        guard let kind = kindForType else { return [] }
        return store.categories(of: kind)
    }

    /// The selection, corrected when switching between expense/income kinds.
    private var activeCategoryId: UUID? {
        if let selectedCategoryId,
           kindCategories.contains(where: { $0.id == selectedCategoryId }) {
            return selectedCategoryId
        }
        return kindCategories.first?.id
    }

    private var activeAccount: Account? {
        store.account(selectedAccountId) ?? store.accounts.first
    }

    private var amount: Decimal {
        Decimal(string: amountString, locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    private var dateLabel: String {
        if Calendar.current.isDateInToday(selectedDate) { return "Today" }
        if Calendar.current.isDateInYesterday(selectedDate) { return "Yesterday" }
        let fmt = DateFormatter()
        fmt.dateFormat = "MMM d"
        return fmt.string(from: selectedDate)
    }

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

                    titleField
                        .padding(.horizontal, AppSpacing.screenMargin)
                        .padding(.top, AppSpacing.base)

                    if !kindCategories.isEmpty {
                        categoryGrid
                            .padding(.top, AppSpacing.lg)
                    }

                    Spacer(minLength: AppSpacing.sm)

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
                    Text(editing == nil ? "New Entry" : "Edit Entry")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: AppSpacing.base) {
                        if editing != nil {
                            Button { showDeleteConfirm = true } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(AppColors.danger)
                            }
                        }
                        Button("Save") { save() }
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(amount > 0 ? AppColors.accent : AppColors.textTertiary)
                            .disabled(amount <= 0)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showDatePicker) { datePicker }
        .sheet(isPresented: $showAccountPicker) { accountPicker }
        .sheet(isPresented: $showAllCategories) { allCategoriesPicker }
        .confirmationDialog("Delete this transaction?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                guard let editing else { return }
                Haptics.warning()
                Task { await store.deleteTransaction(id: editing.id) }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        }
    }

    // MARK: - Save

    private func save() {
        guard amount > 0 else { return }
        let categoryId = transactionType == .transfer ? nil : activeCategoryId
        let trimmed = titleText.trimmingCharacters(in: .whitespaces)
        let fallback = store.category(categoryId)?.name ?? transactionType.label

        let tx = Transaction(
            id: editing?.id ?? UUID(),
            type: transactionType,
            amount: amount,
            categoryId: categoryId,
            title: trimmed.isEmpty ? fallback : trimmed,
            note: editing?.note,
            date: selectedDate,
            accountId: activeAccount?.id,
            accountName: activeAccount?.name ?? ""
        )

        Haptics.success()
        let isNew = editing == nil
        Task {
            if isNew {
                await store.addTransaction(tx)
            } else {
                await store.updateTransaction(tx)
            }
        }
        dismiss()
    }

    // MARK: - Type Toggle

    private var typeToggle: some View {
        HStack(spacing: 0) {
            ForEach(TransactionType.allCases, id: \.self) { type in
                Button {
                    Haptics.select()
                    withAnimation(.easeInOut(duration: 0.2)) { transactionType = type }
                } label: {
                    Text(type.label.uppercased())
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

    // MARK: - Amount

    private var amountDisplay: some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(settings.currencySymbol)
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.textSecondary)
            Text(amountString)
                .font(.system(size: 56, weight: .bold))
                .monospacedDigit()
                .foregroundColor(AppColors.textPrimary)
                .tracking(-1)
                .lineLimit(1)
                .minimumScaleFactor(0.4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, AppSpacing.screenMargin)
    }

    // MARK: - Context Pills

    private var contextPills: some View {
        HStack(spacing: AppSpacing.sm) {
            contextPill(
                icon: nil,
                emoji: activeAccount?.emoji,
                label: activeAccount?.name ?? "Account"
            ) { showAccountPicker = true }

            contextPill(icon: "calendar", emoji: nil, label: dateLabel) { showDatePicker = true }
        }
    }

    private func contextPill(icon: String?, emoji: String?, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let emoji {
                    Text(emoji).font(.system(size: 13))
                } else if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.textPrimary)
                    .lineLimit(1)
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
    }

    // MARK: - Title Field

    private var titleField: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "text.alignleft")
                .font(.system(size: 15))
                .foregroundColor(AppColors.textTertiary)
            TextField("What was this for?", text: $titleText)
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
                Spacer()
                Button { showAllCategories = true } label: {
                    Text("VIEW ALL")
                        .labelCapsStyle(color: AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)

            let columns = Array(repeating: GridItem(.flexible()), count: 4)
            LazyVGrid(columns: columns, spacing: AppSpacing.base) {
                ForEach(kindCategories.prefix(8)) { categoryCell($0) }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
        }
    }

    private func categoryCell(_ category: UserCategory) -> some View {
        let isSelected = category.id == activeCategoryId
        return Button {
            Haptics.select()
            selectedCategoryId = category.id
        } label: {
            VStack(spacing: AppSpacing.sm) {
                EmojiIconTile(
                    emoji: category.emoji,
                    colorHex: isSelected ? category.colorHex : nil,
                    size: 58
                )
                Text(category.name)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(isSelected ? AppColors.textPrimary : AppColors.textSecondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
    }

    // MARK: - Keypad

    private var keypad: some View {
        let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "0", "⌫"]
        let columns = Array(repeating: GridItem(.flexible()), count: 3)
        return LazyVGrid(columns: columns, spacing: 0) {
            ForEach(keys, id: \.self) { key in
                Button {
                    Haptics.tap()
                    handleKey(key)
                } label: {
                    Text(key)
                        .font(.system(size: 26, weight: .regular))
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 62)
                }
            }
        }
        .background(AppColors.background)
    }

    private func handleKey(_ key: String) {
        switch key {
        case "⌫":
            if amountString.count > 1 {
                amountString.removeLast()
            } else {
                amountString = "0"
            }
        case ".":
            if !amountString.contains(".") { amountString += "." }
        default:
            if amountString.contains(".") {
                let decimals = amountString.split(separator: ".", omittingEmptySubsequences: false)
                if decimals.count > 1 && decimals[1].count >= 2 { return }
            }
            if amountString == "0" {
                amountString = key
            } else if amountString.count < 10 {
                amountString += key
            }
        }
    }

    // MARK: - Pickers

    private var datePicker: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                DatePicker("Select Date", selection: $selectedDate, in: ...Date(), displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .tint(AppColors.accent)
                    .padding(AppSpacing.screenMargin)
            }
            .navigationTitle("Select Date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showDatePicker = false }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }

    private var accountPicker: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                VStack(spacing: 0) {
                    ForEach(store.accounts) { account in
                        Button {
                            Haptics.select()
                            selectedAccountId = account.id
                            showAccountPicker = false
                        } label: {
                            HStack(spacing: AppSpacing.md) {
                                Text(account.emoji)
                                Text(account.name)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                if activeAccount?.id == account.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.accent)
                                }
                            }
                            .padding(.horizontal, AppSpacing.screenMargin)
                            .padding(.vertical, AppSpacing.base)
                        }
                        Divider().background(AppColors.borderGlass)
                    }
                    Spacer()
                }
                .padding(.top, AppSpacing.sm)
            }
            .navigationTitle("Select Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAccountPicker = false }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
    }

    private var allCategoriesPicker: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()
                let columns = Array(repeating: GridItem(.flexible()), count: 4)
                ScrollView {
                    LazyVGrid(columns: columns, spacing: AppSpacing.lg) {
                        ForEach(kindCategories) { category in
                            Button {
                                Haptics.select()
                                selectedCategoryId = category.id
                                showAllCategories = false
                            } label: {
                                VStack(spacing: AppSpacing.sm) {
                                    EmojiIconTile(
                                        emoji: category.emoji,
                                        colorHex: category.id == activeCategoryId ? category.colorHex : nil,
                                        size: 58
                                    )
                                    Text(category.name)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(category.id == activeCategoryId ? AppColors.textPrimary : AppColors.textSecondary)
                                        .lineLimit(1)
                                        .minimumScaleFactor(0.8)
                                }
                            }
                        }
                    }
                    .padding(AppSpacing.screenMargin)
                }
            }
            .navigationTitle("All Categories")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { showAllCategories = false }
                        .foregroundColor(AppColors.accent)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    AddTransactionView()
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
}
