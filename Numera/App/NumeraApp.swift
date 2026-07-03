import SwiftUI

@main
struct NumeraApp: App {
    @State private var authManager = AuthManager()
    @State private var appSettings = AppSettings.shared
    @State private var dataStore   = DataStore()
    @State private var showLaunch  = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                destination
                    .preferredColorScheme(.dark)
                    .environment(authManager)
                    .environment(dataStore)
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
            ContentView()
        } else {
            WelcomeView()
        }
    }
}
