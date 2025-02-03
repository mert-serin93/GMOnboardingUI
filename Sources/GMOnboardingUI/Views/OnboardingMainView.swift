import SwiftUI

public struct OnboardingMainView<T: View>: View {
    @StateObject private var onboardingManager = OnboardingUIManager.shared
    @State private var isAppInitialized = false
    let splashView: T

    public init(splashView: T) {
        self.splashView = splashView
    }

    public var body: some View {
        ZStack {
            if isAppInitialized {
                // Your main view content goes here
                OnboardingScreenTabView()
                    .fadeTransition()
            } else {
                splashView
                    .fadeTransition()
            }
        }
        .onReceive(onboardingManager.eventPassthrough) { event in
            switch event {
            case .appInitialized:
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2)) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        isAppInitialized = true
                    }
                }
            case .appInitializedFailed(let error):
                print("App initialization failed: \(error)")
            default:
                break
            }
        }
    }
}

extension View {
    func fadeTransition() -> some View {
        self.transition(.opacity)
    }
}
