import SwiftUI
import AuthenticationServices
import CryptoKit

struct WelcomeView: View {
    @Environment(AuthManager.self) private var authManager
    @State private var showEmailAuth = false
    @State private var rawNonce = ""
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Branding
                VStack(spacing: 14) {
                    Image("numera-mark")
                        .resizable()
                        .aspectRatio(64.0 / 57.0, contentMode: .fit)
                        .frame(height: 44)

                    Text("NUMERA")
                        .font(.system(size: 28, weight: .bold))
                        .kerning(5)
                        .foregroundColor(AppColors.textPrimary)

                    Text("Understand your money.")
                        .font(.system(size: 14))
                        .kerning(0.5)
                        .foregroundColor(AppColors.textSecondary.opacity(0.65))
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13))
                            .foregroundColor(AppColors.expense)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, AppSpacing.sm)
                    }

                    SignInWithAppleButton(.signIn) { request in
                        rawNonce = Self.randomNonce()
                        request.requestedScopes = [.fullName, .email]
                        request.nonce = Self.sha256(rawNonce)
                    } onCompletion: { result in
                        Task { await handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(.white)
                    .frame(height: 52)
                    .cornerRadius(AppRadius.pill)

                    Button {
                        showEmailAuth = true
                    } label: {
                        Label("Continue with Email", systemImage: "envelope")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 52)
                            .background(AppColors.surfaceElevated)
                            .cornerRadius(AppRadius.pill)
                            .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
                    }
                }
                .padding(.horizontal, AppSpacing.screenMargin)

                Text("Your data stays private. No tracking by default.")
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.textTertiary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AppSpacing.xl)
                    .padding(.top, AppSpacing.lg)
                    .padding(.bottom, AppSpacing.xxxl)
            }
        }
        .sheet(isPresented: $showEmailAuth) {
            EmailAuthView()
                .environment(authManager)
        }
    }

    @MainActor
    private func handleApple(_ result: Result<ASAuthorization, Error>) async {
        errorMessage = nil
        switch result {
        case .success(let auth):
            guard
                let cred = auth.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = cred.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple sign-in failed. Please try again."
                return
            }
            do {
                try await authManager.signInWithApple(idToken: idToken, nonce: rawNonce)
            } catch {
                errorMessage = error.localizedDescription
            }
        case .failure(let error):
            guard (error as? ASAuthorizationError)?.code != .canceled else { return }
            errorMessage = error.localizedDescription
        }
    }

    static func randomNonce(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var nonce = "", remaining = length
        while remaining > 0 {
            var bytes = [UInt8](repeating: 0, count: 16)
            SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
            for byte in bytes where remaining > 0 {
                nonce.append(charset[Int(byte) % charset.count])
                remaining -= 1
            }
        }
        return nonce
    }

    static func sha256(_ input: String) -> String {
        SHA256.hash(data: Data(input.utf8))
            .compactMap { String(format: "%02x", $0) }
            .joined()
    }
}
