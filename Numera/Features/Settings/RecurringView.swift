import SwiftUI

/// Manage recurring transactions (Numera Pro). Rules auto-generate a
/// transaction each time they come due; create them via the Repeat option
/// when adding an entry.
struct RecurringView: View {
    @Environment(DataStore.self) private var store

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            if store.recurringRules.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        SettingsCard {
                            ForEach(Array(store.recurringRules.enumerated()), id: \.element.id) { index, rule in
                                ruleRow(rule)
                                if index < store.recurringRules.count - 1 {
                                    Divider().background(AppColors.borderSubtle).padding(.leading, 74)
                                }
                            }
                        }
                        .padding(.horizontal, AppSpacing.screenMargin)

                        Text("Recurring entries are added automatically when they come due.")
                            .font(.system(size: 13, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, AppSpacing.screenMargin)

                        Spacer().frame(height: 120)
                    }
                    .padding(.top, AppSpacing.sm)
                }
            }
        }
        .navigationTitle("Recurring")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private func ruleRow(_ rule: RecurringRule) -> some View {
        HStack(spacing: AppSpacing.base) {
            EmojiIconTile(emoji: store.category(rule.categoryId)?.emoji ?? "🔁", size: 46)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.title)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(rule.isActive ? AppColors.textPrimary : AppColors.textTertiary)
                    .lineLimit(1)
                Text(subtitle(rule))
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: AppSpacing.sm)

            MoneyText(amount: rule.amount, size: 16)
                .opacity(rule.isActive ? 1 : 0.5)

            Menu {
                Button {
                    toggleActive(rule)
                } label: {
                    Label(rule.isActive ? "Pause" : "Resume",
                          systemImage: rule.isActive ? "pause.circle" : "play.circle")
                }
                Button(role: .destructive) {
                    delete(rule)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 32, height: 32)
            }
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, AppSpacing.md)
    }

    private func subtitle(_ rule: RecurringRule) -> String {
        if rule.isActive {
            return "\(rule.frequency.label) · Next \(Self.dateFormatter.string(from: rule.nextRun))"
        }
        return "Paused · \(rule.frequency.label)"
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f
    }()

    private func toggleActive(_ rule: RecurringRule) {
        Haptics.select()
        var updated = rule
        updated.isActive.toggle()
        Task { await store.updateRecurringRule(updated) }
    }

    private func delete(_ rule: RecurringRule) {
        Haptics.warning()
        Task { await store.deleteRecurringRule(id: rule.id) }
    }

    private var emptyState: some View {
        VStack(spacing: AppSpacing.base) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 44, design: .rounded))
                .foregroundColor(AppColors.textTertiary)
            Text("No recurring transactions")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
            Text("Add one by choosing Repeat when you create an entry.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, AppSpacing.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 80)
    }
}

#Preview {
    NavigationStack {
        RecurringView()
    }
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
}
