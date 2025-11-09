import SwiftUI

@main
struct PokerGameApp: App {
    @State private var isShowingLaunch = true
    
    var body: some Scene {
        WindowGroup {
            if isShowingLaunch {
                LaunchScreenView()
                    .onAppear {
                        // Show launch screen for 2 seconds then transition to main game
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isShowingLaunch = false
                            }
                        }
                    }
            } else {
                GameView()
                    .transition(.opacity)
            }
        }
    }
}
