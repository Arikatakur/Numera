import SwiftUI

@main
struct NumeraApp: App {
    @State private var authManager   = AuthManager()
    @State private var txStore       = TransactionStore()
    @State private var appSettings   = AppSettings()
    @State private var showLaunch    = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                destination
                    .preferredColorScheme(.dark)
                    .environment(authManager)
                    .environment(txStore)
                    .environment(appSettings)

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
            .task {
                await authManager.start()
            }
        }
    }

    @ViewBuilder
    private var destination: some View {
        if authManager.isLoading {
            AppColors.background.ignoresSafeArea()
        } else if authManager.session != nil {
            ContentView()
        } else {
            WelcomeView()
        }
    }
}
