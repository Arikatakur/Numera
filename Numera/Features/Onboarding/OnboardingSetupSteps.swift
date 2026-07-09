import SwiftUI

// MARK: - 3. Currency

struct CurrencyStep: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(AppSettings.self) private var settings
    @State private var showAllCurrencies = false

    /// The four common options, always including the locale + current pick so
    /// whatever is selected shows (and highlights) in the short list.
    private var options: [CurrencyInfo] {
        var codes = ["USD", "EUR", "GBP", "ILS"]
        if let locale = Locale.current.currency?.identifier { codes.append(locale) }
        codes.append(model.currencyCode)
        var seen = Set<String>()
        return codes.compactMap { code in
            guard !seen.contains(code) else { return nil }
            seen.insert(code)
            return CurrencyInfo.info(for: code)
        }
    }

    var body: some View {
        OnboardingScaffold(
            badge: "dollarsign.circle.fill",
            title: "Choose your currency",
            subtitle: "Numera shows every amount in this currency. You can change it later in Settings."
        ) {
            VStack(spacing: AppSpacing.md) {
                ForEach(options) { currency in
                    OnboardingOptionRow(
                        emoji: currency.flag,
                        title: currency.name,
                        subtitle: currency.symbol,
                        isSelected: currency.code == model.currencyCode
                    ) { model.currencyCode = currency.code }
                }

                Button {
                    showAllCurrencies = true
                } label: {
                    HStack(spacing: AppSpacing.sm) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 15, design: .rounded))
                        Text("More currencies")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(AppColors.textSecondary)
                    .padding(.horizontal, AppSpacing.base)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
            }
        } footer: {
            PrimaryButton(title: "Continue") {
                settings.currencyCode = model.currencyCode
                Haptics.success()
                onNext()
            }
        }
        .sheet(isPresented: $showAllCurrencies) {
            NavigationStack { CurrencyPickerView() }
                .preferredColorScheme(.dark)
        }
        // The full picker writes settings directly — mirror it back into the flow.
        .onChange(of: settings.currencyCode) { _, newValue in
            model.currencyCode = newValue
        }
    }
}

// MARK: - 4. Month start

struct MonthStartStep: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(AppSettings.self) private var settings

    private var today: Int { Calendar.current.component(.day, from: .now) }

    var body: some View {
        OnboardingScaffold(
            badge: "calendar",
            title: "When does your month start?",
            subtitle: "Numera uses this for monthly totals, insights, and budgets."
        ) {
            VStack(spacing: AppSpacing.md) {
                OnboardingOptionRow(
                    symbol: "1.circle.fill",
                    title: "1st of the month",
                    subtitle: "Standard calendar month",
                    isSelected: model.monthStartMode == .first
                ) { model.monthStartMode = .first }

                OnboardingOptionRow(
                    symbol: "calendar.badge.clock",
                    title: "Today (the \(ordinal(today)))",
                    subtitle: "Begin your cycle from today",
                    isSelected: model.monthStartMode == .today
                ) { model.monthStartMode = .today }

                OnboardingOptionRow(
                    symbol: "slider.horizontal.3",
                    title: "Custom day",
                    subtitle: model.monthStartMode == .custom ? "Starts on the \(ordinal(model.customStartDay))" : "Pick any day of the month",
                    isSelected: model.monthStartMode == .custom
                ) { model.monthStartMode = .custom }

                if model.monthStartMode == .custom {
                    customDayGrid
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .animation(.smooth(duration: 0.25), value: model.monthStartMode)
        } footer: {
            PrimaryButton(title: "Continue") {
                settings.monthStartDay = model.resolvedMonthStartDay
                Haptics.success()
                onNext()
            }
        }
    }

    private var customDayGrid: some View {
        NumeraCard(padding: AppSpacing.base) {
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(1...31, id: \.self) { day in
                    let isSelected = model.customStartDay == day
                    Button {
                        Haptics.select()
                        model.customStartDay = day
                    } label: {
                        Text("\(day)")
                            .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                            .monospacedDigit()
                            .foregroundColor(isSelected ? .black : AppColors.textPrimary)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(isSelected ? AppColors.accent : Color.white.opacity(0.04)))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func ordinal(_ n: Int) -> String {
        let suffix: String
        switch (n % 100, n % 10) {
        case (11, _), (12, _), (13, _): suffix = "th"
        case (_, 1): suffix = "st"
        case (_, 2): suffix = "nd"
        case (_, 3): suffix = "rd"
        default:     suffix = "th"
        }
        return "\(n)\(suffix)"
    }
}

// MARK: - 5. Main account

struct MainAccountStep: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    var body: some View {
        OnboardingScaffold(
            badge: "creditcard.fill",
            title: "Create your first account",
            subtitle: "Use one account to start. You can add more later."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                // Name + live emoji preview
                HStack(spacing: AppSpacing.base) {
                    EmojiIconTile(emoji: model.accountEmoji, colorHex: "#B8F36A", size: 58)
                    TextField("Account name", text: $model.accountName)
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .tint(AppColors.accent)
                        .textInputAutocapitalization(.words)
                        .submitLabel(.done)
                }
                .padding(AppSpacing.base)
                .background(AppColors.surfaceCard, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous).stroke(AppColors.borderGlass, lineWidth: 1))

                // Emoji picker
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("ICON").labelCapsStyle()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: AppSpacing.sm) {
                            ForEach(Account.emojiSuggestions, id: \.self) { emoji in
                                Button {
                                    Haptics.select()
                                    model.accountEmoji = emoji
                                } label: {
                                    EmojiIconTile(
                                        emoji: emoji,
                                        colorHex: model.accountEmoji == emoji ? "#B8F36A" : nil,
                                        size: 50
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }

                // Optional starting balance
                VStack(alignment: .leading, spacing: AppSpacing.sm) {
                    Text("STARTING BALANCE (OPTIONAL)").labelCapsStyle()
                    HStack(spacing: AppSpacing.sm) {
                        Text(settings.currencySymbol)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        TextField("0", text: $model.startingBalance)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(AppColors.textPrimary)
                            .keyboardType(.decimalPad)
                            .tint(AppColors.accent)
                    }
                    .padding(AppSpacing.base)
                    .background(AppColors.surfaceCard, in: RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous).stroke(AppColors.borderGlass, lineWidth: 1))

                    Text("You can skip this and set it later in Settings → Accounts.")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            PrimaryButton(title: "Continue") {
                applyAccount()
                Haptics.success()
                onNext()
            }
        }
    }

    /// Updates the seeded "Main account" in place (keeps its id/history) or
    /// creates one if none exists — never duplicates.
    private func applyAccount() {
        let trimmed = model.accountName.trimmingCharacters(in: .whitespaces)
        let name = trimmed.isEmpty ? "Main" : trimmed
        let balance = model.startingBalanceDecimal ?? store.accounts.first?.balance ?? 0

        Task {
            if var account = store.accounts.first {
                account.name = name
                account.emoji = model.accountEmoji
                account.balance = balance
                await store.updateAccount(account)
            } else {
                await store.addAccount(Account(name: name, balance: balance, emoji: model.accountEmoji))
            }
        }
    }
}

// MARK: - 6. Categories

struct CategoriesStep: View {
    var onNext: () -> Void

    @Environment(DataStore.self) private var store

    private var expense: [UserCategory] { store.categories(of: .expense) }
    private var income: [UserCategory] { store.categories(of: .income) }

    var body: some View {
        OnboardingScaffold(
            badge: "square.grid.2x2.fill",
            title: "Your starter categories",
            subtitle: "These are ready to use. Add, rename, or remove any of them later in Settings."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.xl) {
                if expense.isEmpty && income.isEmpty {
                    Text("We'll set up a helpful starter set of categories for you.")
                        .font(.system(size: 15, design: .rounded))
                        .foregroundColor(AppColors.textSecondary)
                } else {
                    if !expense.isEmpty { categorySection("EXPENSES", expense) }
                    if !income.isEmpty { categorySection("INCOME", income) }
                }
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            PrimaryButton(title: "Looks good") {
                seedIfNeeded()
                Haptics.success()
                onNext()
            }
        }
    }

    private func categorySection(_ title: String, _ categories: [UserCategory]) -> some View {
        VStack(alignment: .leading, spacing: AppSpacing.base) {
            Text(title).labelCapsStyle()
            let columns = Array(repeating: GridItem(.flexible()), count: 4)
            LazyVGrid(columns: columns, spacing: AppSpacing.base) {
                ForEach(categories) { category in
                    VStack(spacing: AppSpacing.sm) {
                        EmojiIconTile(emoji: category.emoji, colorHex: category.colorHex, size: 54)
                        Text(category.name)
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                }
            }
        }
    }

    /// Fallback only — the DB seeds defaults on sign-up, so this rarely runs.
    private func seedIfNeeded() {
        guard store.categories.isEmpty else { return }
        Task {
            for category in UserCategory.seedDefaults {
                await store.addCategory(category)
            }
        }
    }
}

// MARK: - 7. First transaction

struct FirstTransactionStep: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    @State private var showAddTransaction = false

    private var sampleCategory: UserCategory? {
        store.categories(of: .expense).first { $0.name == "Food" }
            ?? store.categories(of: .expense).first
    }

    var body: some View {
        OnboardingScaffold(
            badge: "plus.circle.fill",
            title: "Add your first expense",
            subtitle: "This is the whole app: log what you spend, and Home and Insights update instantly."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.base) {
                sampleCard
                Text("Not sure yet? Add a sample and delete it anytime — or skip.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            PrimaryButton(title: "Add real expense") {
                Haptics.tap()
                showAddTransaction = true
            }
            OnboardingSecondaryButton(title: "Use sample", action: addSample)
            Button {
                Haptics.tap()
                onNext()
            } label: {
                Text("Skip for now")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.plain)
        }
        // After the real add-transaction flow finishes, continue the onboarding.
        .sheet(isPresented: $showAddTransaction, onDismiss: onNext) {
            AddTransactionView()
        }
    }

    private var sampleCard: some View {
        HStack(spacing: AppSpacing.base) {
            EmojiIconTile(emoji: sampleCategory?.emoji ?? "🍽️", colorHex: sampleCategory?.colorHex, size: 46)
            VStack(alignment: .leading, spacing: 2) {
                Text("Coffee")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Text("\(sampleCategory?.name ?? "Food") · Today")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
            }
            Spacer(minLength: 0)
            Text(MoneyFormatter.string(Decimal(string: "12.50")!, code: settings.currencyCode, cents: settings.displayCents))
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundColor(AppColors.expense)
        }
        .padding(AppSpacing.base)
        .liquidGlass(cornerRadius: AppRadius.card)
    }

    private func addSample() {
        let account = store.accounts.first { $0.name == model.accountName } ?? store.accounts.first
        let tx = Transaction(
            type: .expense,
            amount: Decimal(string: "12.50")!,
            categoryId: sampleCategory?.id,
            title: "Coffee",
            note: "Coffee",
            date: .now,
            accountId: account?.id,
            accountName: account?.name ?? ""
        )
        Haptics.success()
        model.didLogFirstTransaction = true
        Task { await store.addTransaction(tx) }
        onNext()
    }
}

// MARK: - 8. Reminder (optional)

struct ReminderStep: View {
    @Bindable var model: OnboardingModel
    var onNext: () -> Void

    @Environment(AppSettings.self) private var settings

    var body: some View {
        OnboardingScaffold(
            badge: "bell.badge.fill",
            title: "Want a daily reminder?",
            subtitle: "A gentle nudge can help you keep your spending up to date."
        ) {
            VStack(alignment: .leading, spacing: AppSpacing.md) {
                OnboardingOptionRow(
                    symbol: "sunrise.fill",
                    title: "Morning",
                    subtitle: "Around 9:00 AM",
                    isSelected: model.reminderChoice == .morning
                ) { model.reminderChoice = .morning }

                OnboardingOptionRow(
                    symbol: "moon.stars.fill",
                    title: "Evening",
                    subtitle: "Around 9:00 PM",
                    isSelected: model.reminderChoice == .evening
                ) { model.reminderChoice = .evening }

                OnboardingOptionRow(
                    symbol: "bell.slash.fill",
                    title: "Not now",
                    subtitle: "No notifications",
                    isSelected: model.reminderChoice == .notNow
                ) { model.reminderChoice = .notNow }

                Text("We only ask for notification permission if you pick a time.")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textTertiary)
                    .padding(.top, AppSpacing.xs)
            }
            .padding(.top, AppSpacing.xs)
        } footer: {
            PrimaryButton(title: "Continue", action: applyReminder)
        }
    }

    /// Only Morning/Evening schedule a notification — which is the single place
    /// that requests permission. "Not now" (or no choice) never prompts.
    private func applyReminder() {
        switch model.reminderChoice {
        case .morning, .evening:
            settings.reminderFrequency = .daily
            settings.reminderHour = model.reminderHour ?? 21
            settings.reminderMinute = 0
            Haptics.success()
            Task { await ReminderScheduler.reschedule(settings: settings) }
        case .notNow, .none:
            settings.reminderFrequency = .never
            Haptics.tap()
        }
        onNext()
    }
}

#Preview("Currency") {
    ZStack { AppColors.background.ignoresSafeArea(); CurrencyStep(model: OnboardingModel(), onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(AppSettings.shared)
}

#Preview("Month start") {
    ZStack { AppColors.background.ignoresSafeArea(); MonthStartStep(model: OnboardingModel(), onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(AppSettings.shared)
}

#Preview("Account") {
    ZStack { AppColors.background.ignoresSafeArea(); MainAccountStep(model: OnboardingModel(), onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
}

#Preview("Categories") {
    ZStack { AppColors.background.ignoresSafeArea(); CategoriesStep(onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(DataStore.preview())
}

#Preview("First transaction") {
    ZStack { AppColors.background.ignoresSafeArea(); FirstTransactionStep(model: OnboardingModel(), onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
        .environment(PremiumManager.preview())
}

#Preview("Reminder") {
    ZStack { AppColors.background.ignoresSafeArea(); ReminderStep(model: OnboardingModel(), onNext: {}) }
        .preferredColorScheme(.dark)
        .environment(AppSettings.shared)
}
