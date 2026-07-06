import SwiftUI

/// Accounts manager (Quanto-style): total balance hero, account rows,
/// floating "New account" pill. Balances are starting balance ± transactions.
struct AccountsView: View {
    @Environment(DataStore.self) private var store
    @Environment(PremiumManager.self) private var premium

    enum EditorTarget: Identifiable {
        case new
        case edit(Account)

        var id: String {
            switch self {
            case .new:               return "new"
            case .edit(let account): return account.id.uuidString
            }
        }
    }

    @State private var editorTarget: EditorTarget?
    @State private var showPaywall = false

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: AppSpacing.xl) {
                    VStack(spacing: 6) {
                        Text("Total balance")
                            .font(.system(size: 15, design: .rounded))
                            .foregroundColor(AppColors.textSecondary)
                        MoneyText(amount: store.totalBalance, size: 40)
                    }
                    .padding(.top, AppSpacing.lg)

                    SettingsCard {
                        ForEach(Array(store.accounts.enumerated()), id: \.element.id) { index, account in
                            Button {
                                editorTarget = .edit(account)
                            } label: {
                                HStack(spacing: AppSpacing.base) {
                                    EmojiIconTile(emoji: account.emoji, size: 46)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(account.name)
                                            .font(.system(size: 14, design: .rounded))
                                            .foregroundColor(AppColors.textSecondary)
                                        MoneyText(amount: store.currentBalance(of: account), size: 18)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                                .padding(.horizontal, AppSpacing.base)
                                .padding(.vertical, AppSpacing.md)
                            }
                            .buttonStyle(.plain)

                            if index < store.accounts.count - 1 {
                                Divider().background(AppColors.borderSubtle).padding(.leading, 78)
                            }
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)

                    if !premium.isPremium {
                        HStack(spacing: AppSpacing.sm) {
                            Text("Add more accounts with Numera Pro")
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            PremiumBadge()
                        }
                        .padding(.horizontal, AppSpacing.screenMargin)
                    }

                    Spacer().frame(height: 100)
                }
            }

            FloatingPillButton(title: "New account") {
                if !premium.isPremium && store.accounts.count >= 1 {
                    showPaywall = true
                } else {
                    editorTarget = .new
                }
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .navigationTitle("Accounts")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $editorTarget) { target in
            AccountEditSheet(target: target)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
    }
}

// MARK: - Editor sheet

struct AccountEditSheet: View {
    let target: AccountsView.EditorTarget

    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var balanceText: String
    @State private var showDeleteConfirm = false

    private var editing: Account? {
        if case .edit(let account) = target { return account }
        return nil
    }

    init(target: AccountsView.EditorTarget) {
        self.target = target
        switch target {
        case .new:
            _name = State(initialValue: "")
            _emoji = State(initialValue: "🏦")
            _balanceText = State(initialValue: "")
        case .edit(let account):
            _name = State(initialValue: account.name)
            _emoji = State(initialValue: account.emoji)
            _balanceText = State(initialValue: "\(account.balance)")
        }
    }

    private var balance: Decimal {
        Decimal(string: balanceText.replacingOccurrences(of: ",", with: "."), locale: Locale(identifier: "en_US_POSIX")) ?? 0
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                VStack(spacing: AppSpacing.xl) {
                    EmojiIconTile(emoji: emoji, size: 76)
                        .padding(.top, AppSpacing.sm)

                    TextField("Account name", text: $name)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(AppColors.textPrimary)
                        .tint(AppColors.accent)
                        .padding(AppSpacing.base)
                        .background(AppColors.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .stroke(AppColors.borderGlass, lineWidth: 1)
                        )

                    VStack(alignment: .leading, spacing: AppSpacing.sm) {
                        Text("STARTING BALANCE")
                            .labelCapsStyle()
                        HStack(spacing: 6) {
                            Text(settings.currencySymbol)
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(AppColors.textSecondary)
                            TextField("0", text: $balanceText)
                                .keyboardType(.decimalPad)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .foregroundColor(AppColors.textPrimary)
                                .tint(AppColors.accent)
                        }
                        .padding(AppSpacing.base)
                        .background(AppColors.surfaceCard)
                        .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                                .stroke(AppColors.borderGlass, lineWidth: 1)
                        )
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    emojiRow

                    PrimaryButton(title: editing == nil ? "Create account" : "Save changes") {
                        save()
                    }
                    .opacity(canSave ? 1 : 0.4)
                    .disabled(!canSave)

                    if editing != nil && store.accounts.count > 1 {
                        Button {
                            showDeleteConfirm = true
                        } label: {
                            Text("Delete account")
                                .font(.system(size: 15, weight: .semibold, design: .rounded))
                                .foregroundColor(AppColors.danger)
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, AppSpacing.screenMargin)
            }
            .navigationTitle(editing == nil ? "New Account" : "Edit Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .confirmationDialog("Delete \(name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let editing {
                    Haptics.warning()
                    Task { await store.deleteAccount(id: editing.id) }
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Its transactions are kept and stay linked to the account name.")
        }
    }

    private var emojiRow: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ICON")
                .labelCapsStyle()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.sm) {
                    ForEach(Account.emojiSuggestions, id: \.self) { suggestion in
                        Button {
                            Haptics.select()
                            emoji = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.system(size: 22, design: .rounded))
                                .frame(width: 40, height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(emoji == suggestion ? AppColors.accent.opacity(0.25) : Color.white.opacity(0.04))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(emoji == suggestion ? AppColors.accent : Color.clear, lineWidth: 1.5)
                                )
                        }
                    }
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        Haptics.success()
        if var updated = editing {
            updated.name = trimmed
            updated.emoji = emoji
            updated.balance = balance
            Task { await store.updateAccount(updated) }
        } else {
            let created = Account(name: trimmed, balance: balance, emoji: emoji)
            Task { await store.addAccount(created) }
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        AccountsView()
    }
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
    .environment(PremiumManager.preview())
}
