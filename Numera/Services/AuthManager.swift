import Supabase
import SwiftUI

@MainActor
@Observable
final class AuthManager {
    var session: Session?
    var isLoading = true

    func start() async {
        for await (event, session) in await SupabaseManager.shared.client.auth.authStateChanges {
            switch event {
            case .initialSession:
                self.session = session
                self.isLoading = false
            case .signedIn:
                self.session = session
            case .signedOut:
                self.session = nil
            default:
                break
            }
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
