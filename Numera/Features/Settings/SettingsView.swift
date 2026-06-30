import SwiftUI

struct SettingsView: View {
    @Environment(AuthManager.self)  private var authManager
    @Environment(AppSettings.self) private var settings
    @State private var showSignOutConfirm = false

    var body: some View {
        @Bindable var settings = settings

        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                List {
                    // Account
                    Section("Account") {
                        HStack(spacing: AppSpacing.base) {
                            ZStack {
                                Circle()
                                    .fill(AppColors.surfaceElevated)
                                    .frame(width: 52, height: 52)
                                Text(initials)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColors.accent)
                            }
                            VStack(alignment: .leading, spacing: 3) {
                                Text(displayName)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                Text(authManager.currentUserEmail ?? "—")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppColors.textSecondary)
                            }
                        }
                        .padding(.vertical, AppSpacing.sm)
                        .listRowBackground(AppColors.surfaceCard)
                    }

                    // Privacy
                    Section("Privacy") {
                        Toggle(isOn: $settings.isPrivate) {
                            Label("Hide Balances", systemImage: "eye.slash")
                                .foregroundColor(AppColors.textPrimary)
                        }
                        .tint(AppColors.accent)
                        .listRowBackground(AppColors.surfaceCard)
                    }

                    // About
                    Section("About") {
                        HStack {
                            Label("Version", systemImage: "info.circle")
                                .foregroundColor(AppColors.textPrimary)
                            Spacer()
                            Text("1.0.0 (build \(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                                .font(.system(size: 13))
                                .foregroundColor(AppColors.textSecondary)
                        }
                        .listRowBackground(AppColors.surfaceCard)
                    }

                    // Sign Out
                    Section {
                        Button(role: .destructive) {
                            showSignOutConfirm = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                    .font(.system(size: 16, weight: .semibold))
                                Spacer()
                            }
                        }
                        .listRowBackground(AppColors.surfaceCard)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .confirmationDialog("Sign Out", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign Out", role: .destructive) {
                Task { try? await authManager.signOut() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to access your data.")
        }
    }

    private var displayName: String {
        let email = authManager.currentUserEmail ?? ""
        let username = email.split(separator: "@").first.map(String.init) ?? "User"
        return username.prefix(1).uppercased() + username.dropFirst()
    }

    private var initials: String {
        String((authManager.currentUserEmail ?? "U").prefix(1).uppercased())
    }
}
