import Supabase
import SwiftUI

@MainActor
@Observable
final class AuthManager {
    var session: Session?
    var isLoading = true

    /// Per-user first-run flag, sourced from `profiles.has_completed_onboarding`
    /// (not the device) so onboarding follows the account across devices/logins.
    /// `nil` = not yet determined for the current session.
    var hasCompletedOnboarding: Bool?

    func start() async {
        for await (event, session) in await SupabaseManager.shared.client.auth.authStateChanges {
            switch event {
            case .initialSession:
                self.session = session
                if session != nil { await loadOnboardingState() }
                self.isLoading = false
            case .signedIn:
                self.session = session
                await loadOnboardingState()
            case .signedOut:
                self.session = nil
                self.hasCompletedOnboarding = nil
            default:
                break
            }
        }
    }

    // MARK: - Onboarding flag

    /// Reads the per-user onboarding flag from the profile row. Fails open —
    /// treated as completed — on any error (offline, or the migration not yet
    /// applied), so a returning user is never trapped in onboarding.
    private func loadOnboardingState() async {
        guard let userId = session?.user.id else {
            hasCompletedOnboarding = nil
            return
        }
        do {
            let profile: ProfileFlagsDTO = try await SupabaseManager.shared.client
                .from("profiles")
                .select("has_completed_onboarding")
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            hasCompletedOnboarding = profile.has_completed_onboarding
        } catch {
            #if DEBUG
            print("[AuthManager] onboarding state load failed — \(error)")
            #endif
            hasCompletedOnboarding = true
        }
    }

    /// Marks onboarding complete for this user: optimistic local flag (routes
    /// straight into the tabs) plus a persisted profile update.
    func markOnboardingComplete() async {
        hasCompletedOnboarding = true
        guard let userId = session?.user.id else { return }
        do {
            try await SupabaseManager.shared.client
                .from("profiles")
                .update(ProfileFlagsDTO(has_completed_onboarding: true))
                .eq("id", value: userId.uuidString)
                .execute()
        } catch {
            #if DEBUG
            print("[AuthManager] onboarding completion persist failed — \(error)")
            #endif
        }
    }

    func signIn(email: String, password: String) async throws {
        try await SupabaseManager.shared.client.auth.signIn(email: email, password: password)
    }

    func signUp(email: String, password: String) async throws {
        try await SupabaseManager.shared.client.auth.signUp(email: email, password: password)
    }

    func signInWithApple(idToken: String, nonce: String) async throws {
        try await SupabaseManager.shared.client.auth.signInWithIdToken(
            credentials: OpenIDConnectCredentials(provider: .apple, idToken: idToken, nonce: nonce)
        )
    }

    func signOut() async throws {
        try await SupabaseManager.shared.client.auth.signOut()
    }

    /// Permanently deletes the user's account and all associated data. The
    /// `delete-account` Edge Function removes the Supabase auth user; every
    /// owned row is cascade-deleted server-side. Apple requires in-app account
    /// deletion for apps that support account creation.
    func deleteAccount() async throws {
        try await SupabaseManager.shared.client.functions.invoke("delete-account")
        // Account is gone server-side — clear the local session. Local scope
        // avoids revoking a token that no longer exists.
        try? await SupabaseManager.shared.client.auth.signOut(scope: .local)
    }

    var currentUserEmail: String? {
        session?.user.email
    }
}
