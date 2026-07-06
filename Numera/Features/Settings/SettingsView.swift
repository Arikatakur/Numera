import SwiftUI
import UIKit

/// Settings hub — Quanto structure (General / Preferences / Privacy / Data /
/// About) rendered with Numera's card language.
struct SettingsView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings
    @Environment(PremiumManager.self) private var premium
    @Environment(\.requestReview) private var requestReview
    @Environment(\.openURL) private var openURL

    private struct ExportItem: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    @State private var showSignOutConfirm = false
    @State private var showEraseConfirm = false
    @State private var showDeleteAccountConfirm = false
    @State private var exportItem: ExportItem?
    @State private var showPaywall = false
    @State private var showManageSubscriptions = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: AppSpacing.lg) {
                        PageTitle(text: "Settings")

                        profileCard

                        if !premium.isPremium {
                            proBanner
                        }

                        SettingsSectionHeader(title: "General")
                        SettingsCard {
                            NavigationLink {
                                CategoriesView().hidesTabBar()
                            } label: {
                                SettingsRow(icon: "circle.grid.2x2", title: "Categories") {
                                    SettingsValueChevron()
                                }
                            }
                            SettingsDivider()
                            NavigationLink {
                                AccountsView().hidesTabBar()
                            } label: {
                                SettingsRow(icon: "building.columns", title: "Accounts") {
                                    SettingsValueChevron(value: "\(store.accounts.count)")
                                }
                            }
                            SettingsDivider()
                            Button {
                                if premium.isPremium {
                                    showManageSubscriptions = true
                                } else {
                                    showPaywall = true
                                }
                            } label: {
                                SettingsRow(icon: "star.circle", title: "Subscription") {
                                    SettingsValueChevron(value: premium.isPremium ? "Pro" : "Free")
                                }
                            }
                        }

                        SettingsSectionHeader(title: "Automations")
                        SettingsCard {
                            if premium.isPremium {
                                NavigationLink {
                                    RecurringView().hidesTabBar()
                                } label: {
                                    SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Recurring transactions") {
                                        SettingsValueChevron(value: "\(store.recurringRules.count)")
                                    }
                                }
                            } else {
                                Button {
                                    showPaywall = true
                                } label: {
                                    SettingsRow(icon: "arrow.triangle.2.circlepath", title: "Recurring transactions") {
                                        PremiumBadge()
                                    }
                                }
                            }
                        }

                        SettingsSectionHeader(title: "Preferences")
                        SettingsCard {
                            NavigationLink {
                                CurrencyPickerView().hidesTabBar()
                            } label: {
                                SettingsRow(icon: "dollarsign.circle", title: "Currency") {
                                    SettingsValueChevron(value: settings.currencyCode)
                                }
                            }
                            SettingsDivider()
                            NavigationLink {
                                ReminderView().hidesTabBar()
                            } label: {
                                SettingsRow(icon: "bell", title: "Reminder") {
                                    SettingsValueChevron(value: settings.reminderFrequency.label)
                                }
                            }
                            SettingsDivider()
                            NavigationLink {
                                MonthStartDayView().hidesTabBar()
                            } label: {
                                SettingsRow(icon: "calendar", title: "Month start day") {
                                    SettingsValueChevron(value: ordinal(settings.monthStartDay))
                                }
                            }
                            SettingsDivider()
                            SettingsRow(icon: "calendar.badge.clock", title: "First day of week") {
                                Menu {
                                    Button("Monday") { settings.firstWeekday = 2 }
                                    Button("Sunday") { settings.firstWeekday = 1 }
                                } label: {
                                    SettingsValueChevron(value: settings.firstWeekday == 2 ? "Monday" : "Sunday")
                                }
                            }
                            SettingsDivider()
                            SettingsRow(icon: "centsign.circle", title: "Display cents") {
                                Toggle("", isOn: $settings.displayCents)
                                    .labelsHidden()
                                    .tint(AppColors.accent)
                            }
                            SettingsDivider()
                            SettingsRow(icon: "hand.tap", title: "Haptic feedback") {
                                Toggle("", isOn: $settings.hapticsEnabled)
                                    .labelsHidden()
                                    .tint(AppColors.accent)
                            }
                        }

                        SettingsSectionHeader(title: "Privacy & security")
                        SettingsCard {
                            SettingsRow(icon: "eye.slash", title: "Hide balances") {
                                Toggle("", isOn: $settings.isPrivate)
                                    .labelsHidden()
                                    .tint(AppColors.accent)
                            }
                        }

                        SettingsSectionHeader(title: "Data")
                        SettingsCard {
                            Button {
                                if !premium.isPremium {
                                    showPaywall = true
                                } else if let url = store.exportCSVFile() {
                                    exportItem = ExportItem(url: url)
                                }
                            } label: {
                                SettingsRow(icon: "square.and.arrow.up", title: "Export data (CSV)") {
                                    if premium.isPremium {
                                        SettingsValueChevron()
                                    } else {
                                        PremiumBadge()
                                    }
                                }
                            }
                            SettingsDivider()
                            NavigationLink {
                                ImportTransactionsView().hidesTabBar()
                            } label: {
                                SettingsRow(icon: "square.and.arrow.down", title: "Import data (CSV)") {
                                    SettingsValueChevron()
                                }
                            }
                            SettingsDivider()
                            Button {
                                showEraseConfirm = true
                            } label: {
                                SettingsRow(icon: "trash", title: "Erase data", iconTint: AppColors.danger, titleColor: AppColors.danger)
                            }
                        }

                        SettingsSectionHeader(title: "About")
                        SettingsCard {
                            SettingsRow(icon: "info.circle", title: "Version") {
                                Text(versionText)
                                    .font(.system(size: 15))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                            SettingsDivider()
                            Button {
                                showSignOutConfirm = true
                            } label: {
                                SettingsRow(icon: "rectangle.portrait.and.arrow.right", title: "Sign out", iconTint: AppColors.danger, titleColor: AppColors.danger)
                            }
                            SettingsDivider()
                            Button {
                                showDeleteAccountConfirm = true
                            } label: {
                                SettingsRow(icon: "person.crop.circle.badge.xmark", title: "Delete account", iconTint: AppColors.danger, titleColor: AppColors.danger)
                            }
                        }

                        SettingsSectionHeader(title: "Support & feedback")
                        SettingsCard {
                            Button {
                                Haptics.tap()
                                rateApp()
                            } label: {
                                SettingsRow(icon: "star", title: "Rate on App Store") {
                                    SettingsValueChevron()
                                }
                            }
                            SettingsDivider()
                            Button {
                                Haptics.tap()
                                openURL(AppInfo.forumURL)
                            } label: {
                                SettingsRow(icon: "bubble.left.and.bubble.right", title: "Feedback & roadmap") {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                            SettingsDivider()
                            forumRow("hand.thumbsup", "Help us improve", type: "improvement")
                            SettingsDivider()
                            forumRow("ladybug", "Report a bug", type: "bug")
                            SettingsDivider()
                            forumRow("lightbulb", "Feature request", type: "feature")
                        }

                        SettingsSectionHeader(title: "Other")
                        SettingsCard {
                            Button {
                                Haptics.tap()
                                openInstagram()
                            } label: {
                                SettingsRow(assetIcon: "instagram.logo", title: "Follow creator on IG") {
                                    Image(systemName: "arrow.up.right")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(AppColors.textTertiary)
                                }
                            }
                        }

                        SettingsSectionHeader(title: "Legal")
                        SettingsCard {
                            settingsLink("hand.raised", "Privacy policy", "https://clientvault.org/numera/privacy")
                            SettingsDivider()
                            settingsLink("doc.text", "Terms of use", "https://clientvault.org/numera/terms")
                            SettingsDivider()
                            settingsLink("questionmark.circle", "Support", "https://clientvault.org/numera/support")
                        }

                        VStack(spacing: 4) {
                            Text("Numera — your money, clearly.")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textTertiary)
                            Text("Version \(AppInfo.versionString)")
                                .font(.system(size: 12))
                                .foregroundColor(AppColors.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AppSpacing.sm)

                        Spacer().frame(height: 80)
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                    .padding(.top, AppSpacing.sm)
                }
            }
            // Root bar hidden — the title lives in-content (PageTitle) so it
            // aligns with the cards; pushed sub-pages still show their bars.
            .navigationBarHidden(true)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { try? await authManager.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your data.")
        }
        .confirmationDialog("Erase all data?", isPresented: $showEraseConfirm, titleVisibility: .visible) {
            Button("Erase everything", role: .destructive) {
                Haptics.warning()
                Task { await store.eraseAllData() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Deletes every transaction, budget, account, and custom category. Default categories are restored. This cannot be undone.")
        }
        .confirmationDialog("Delete account?", isPresented: $showDeleteAccountConfirm, titleVisibility: .visible) {
            Button("Delete account", role: .destructive) {
                Haptics.warning()
                Task {
                    do { try await authManager.deleteAccount() }
                    catch { store.errorMessage = "Couldn't delete your account. Please try again." }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes your account and all your data. This cannot be undone.")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .manageSubscriptionsSheet(isPresented: $showManageSubscriptions)
        .sheet(item: $exportItem) { item in
            ShareSheet(activityItems: [item.url])
                .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Support & feedback actions

    private func rateApp() {
        if !AppInfo.appStoreID.isEmpty,
           let url = URL(string: "https://apps.apple.com/app/id\(AppInfo.appStoreID)?action=write-review") {
            openURL(url)
        } else {
            requestReview()
        }
    }

    private func forumRow(_ icon: String, _ title: String, type: String) -> some View {
        Button {
            Haptics.tap()
            openURL(AppInfo.forumComposeURL(type: type))
        } label: {
            SettingsRow(icon: icon, title: title) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }

    /// Opens the creator's Instagram: the app when installed, otherwise the web
    /// profile. Uses `canOpenURL` to decide up front — the old completion-based
    /// fallback opened the web URL when the user cancelled the system
    /// "Open in Instagram?" prompt, which read as "Cancel still opens it".
    private func openInstagram() {
        let appURL = AppInfo.instagramAppURL
        if UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            UIApplication.shared.open(AppInfo.instagramURL)
        }
    }

    // MARK: - Pro banner

    private var proBanner: some View {
        Button {
            showPaywall = true
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                Text("Try Numera Pro for free!")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)
                Text("Unlock budgeting, recurring & export.")
                    .font(.system(size: 14))
                    .foregroundColor(.black.opacity(0.7))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(AppSpacing.lg)
            .background(
                LinearGradient(
                    colors: [AppColors.chartTeal, AppColors.accent],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Profile

    private var profileCard: some View {
        SettingsCard {
            HStack(spacing: AppSpacing.base) {
                ZStack {
                    Circle()
                        .fill(AppColors.accent.opacity(0.15))
                        .frame(width: 54, height: 54)
                    Text(initials)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.accent)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(displayName)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    Text(authManager.currentUserEmail ?? "—")
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.textSecondary)
                }
                Spacer()
            }
            .padding(AppSpacing.base)
        }
    }

    private var displayName: String {
        let email = authManager.currentUserEmail ?? ""
        let username = email.split(separator: "@").first.map(String.init) ?? "User"
        return username.prefix(1).uppercased() + username.dropFirst()
    }

    private var initials: String {
        String((authManager.currentUserEmail ?? "N").prefix(1).uppercased())
    }

    private var versionText: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    private func ordinal(_ n: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .ordinal
        return formatter.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    // MARK: - Legal & support

    private func settingsLink(_ icon: String, _ title: String, _ urlString: String) -> some View {
        Link(destination: URL(string: urlString)!) {
            SettingsRow(icon: icon, title: title) {
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

#Preview {
    SettingsView()
        .preferredColorScheme(.dark)
        .environment(AuthManager())
        .environment(DataStore.preview())
        .environment(AppSettings.shared)
        .environment(PremiumManager.preview())
}
