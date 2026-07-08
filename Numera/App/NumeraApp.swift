import SwiftUI
import UIKit

@main
struct NumeraApp: App {
    @State private var authManager    = AuthManager()
    @State private var appSettings    = AppSettings.shared
    @State private var dataStore      = DataStore()
    @State private var premiumManager = PremiumManager()
    @State private var showLaunch     = true

    init() {
        // SF Rounded for navigation titles, matching the app's rounded type.
        // Fonts only — backgrounds are untouched so the system bars keep
        // their automatic Liquid Glass on iOS 26.
        let large = UIFont.systemFont(ofSize: 34, weight: .bold)
        if let descriptor = large.fontDescriptor.withDesign(.rounded) {
            UINavigationBar.appearance().largeTitleTextAttributes =
                [.font: UIFont(descriptor: descriptor, size: 34)]
        }
        let inline = UIFont.systemFont(ofSize: 17, weight: .semibold)
        if let descriptor = inline.fontDescriptor.withDesign(.rounded) {
            UINavigationBar.appearance().titleTextAttributes =
                [.font: UIFont(descriptor: descriptor, size: 17)]
        }
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                destination
                    .preferredColorScheme(.dark)
                    .environment(authManager)
                    .environment(dataStore)
                    .environment(appSettings)
                    .environment(premiumManager)

                if showLaunch {
                    LaunchAnimationView {
                        withAnimation(.easeOut(duration: 0.6)) {
                            showLaunch = false
                        }
                    }
                    .transition(.opacity)
                    .zIndex(1)
                }
            }
            // Quanto-style soft type everywhere: rounded design for any text
            // that doesn't set an explicit font (system controls, text styles).
            .fontDesign(.rounded)
            .task {
                await premiumManager.start()
            }
            .task {
                await authManager.start()
            }
            .onChange(of: authManager.session == nil) { _, signedOut in
                if signedOut { dataStore.reset() }
            }
        }
    }

    @ViewBuilder
    private var destination: some View {
        if authManager.isLoading {
            AppColors.background.ignoresSafeArea()
        } else if authManager.session != nil {
            // First-run: set up the essentials before the tabs. The flag is
            // per-user (loaded from the profile), so reading it here re-routes
            // automatically once it resolves and on completion.
            switch authManager.hasCompletedOnboarding {
            case .some(false):
                OnboardingView()
            case .some(true):
                ContentView()
            case .none:
                // Session resolved but the profile flag is still loading.
                AppColors.background.ignoresSafeArea()
            }
        } else {
            WelcomeView()
        }
    }
}
