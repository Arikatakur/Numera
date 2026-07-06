import SwiftUI

struct EmailAuthView: View {
    @Environment(AuthManager.self) private var authManager
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Mode = .signIn
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showConfirmation = false

    enum Mode: String, CaseIterable {
        case signIn = "Sign In"
        case signUp = "Create Account"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AppSpacing.xl) {
                        Picker("Mode", selection: $mode) {
                            ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                        }
                        .pickerStyle(.segmented)
                        .padding(.top, AppSpacing.sm)

                        VStack(spacing: AppSpacing.md) {
                            authField("Email", text: $email, keyboardType: .emailAddress, contentType: .emailAddress)
                            authField("Password", text: $password, isSecure: true, contentType: mode == .signUp ? .newPassword : .password)
                            if mode == .signUp {
                                authField("Confirm Password", text: $confirmPassword, isSecure: true, contentType: .newPassword)
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundColor(AppColors.expense)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }

                        if showConfirmation {
                            confirmationCard
                        } else {
                            PrimaryButton(
                                title: isLoading ? "Please wait…" : mode.rawValue,
                                action: submit
                            )
                            .disabled(isLoading || !isFormValid)
                            .opacity(isFormValid ? 1 : 0.5)
                        }
                    }
                    .padding(AppSpacing.screenMargin)
                }
            }
            .navigationTitle(mode == .signIn ? "Welcome Back" : "New Account")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
            .onChange(of: mode) {
                errorMessage = nil
                showConfirmation = false
            }
        }
        .preferredColorScheme(.dark)
    }

    private var confirmationCard: some View {
        VStack(spacing: AppSpacing.md) {
            Image(systemName: "envelope.badge.shield.half.filled")
                .font(.system(size: 40, design: .rounded))
                .foregroundColor(AppColors.accent)

            Text("Check your email")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(AppColors.textPrimary)

            Text("We sent a confirmation link to **\(email)**. Tap it to activate your account, then sign in.")
                .font(.system(size: 14, design: .rounded))
                .foregroundColor(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            Button {
                mode = .signIn
                showConfirmation = false
            } label: {
                Text("Go to Sign In")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(AppColors.accent)
            }
            .padding(.top, AppSpacing.sm)
        }
        .padding(AppSpacing.cardPadding)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.card)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.card).stroke(AppColors.borderGlass, lineWidth: 1))
    }

    @ViewBuilder
    private func authField(
        _ placeholder: String,
        text: Binding<String>,
        isSecure: Bool = false,
        keyboardType: UIKeyboardType = .default,
        contentType: UITextContentType
    ) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
            } else {
                TextField(placeholder, text: text)
                    .keyboardType(keyboardType)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
            }
        }
        .textContentType(contentType)
        .font(.system(size: 16, design: .rounded))
        .foregroundColor(AppColors.textPrimary)
        .padding(AppSpacing.base)
        .background(AppColors.surfaceElevated)
        .cornerRadius(AppRadius.md)
        .overlay(RoundedRectangle(cornerRadius: AppRadius.md).stroke(AppColors.borderGlass, lineWidth: 1))
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty &&
        (mode == .signIn || password == confirmPassword)
    }

    private func submit() {
        errorMessage = nil
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                switch mode {
                case .signIn:
                    try await authManager.signIn(email: email, password: password)
                    dismiss()
                case .signUp:
                    try await authManager.signUp(email: email, password: password)
                    showConfirmation = true
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
