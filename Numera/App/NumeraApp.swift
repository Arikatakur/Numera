import SwiftUI

@main
struct NumeraApp: App {
    @State private var showLaunch = true

    var body: some Scene {
        WindowGroup {
            ZStack {
                ContentView()
                    .preferredColorScheme(.dark)

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
        }
    }
}
