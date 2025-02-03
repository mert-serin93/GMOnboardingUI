//
//  OnboardingScreenTabView.swift
//  GMOnboardingUI
//
//  Created by Mert Serin on 2024-12-03.
//

import SwiftUI

final public class OnboardingScreenTabViewModel: ObservableObject {
    @Published var screens: [ScreenItem] = []
    let authManager = AuthManager()
    @Published var currentState: Int = 0

    @Published var backgroundItems: [OnboardingScreenItem] = []
    @Published var items: [OnboardingScreenItem] = []

    init() {
        guard let response = authManager.getOnboarding() else { return }
        if screens.isEmpty {
            Task {
                try await OnboardingUIManager.shared.sendEvent(event: .onboardingStarted, parameters: ["onboarding_id": "\(response.onboarding.id)"])
            }
        }
        self.screens = response.onboarding.screens
        self.items = screens[currentState].items.filter({$0.type != .backgroundView})
        self.backgroundItems = screens[currentState].items.filter({$0.type == .backgroundView})
    }

    func onCtaAction() {
        guard let response = authManager.getOnboarding() else { return }
        if currentState < screens.count - 1 {
            Task {
                try await OnboardingUIManager.shared.sendEvent(event: .onboardingScreenViewed, parameters: [
                    "onboarding_id": "\(response.onboarding.id)",
                    "screen_id": "\(screens[currentState].id)"])
            }

            withAnimation(.easeInOut(duration: 0.5)) {
                currentState += 1
                self.items = screens[currentState].items.filter({$0.type != .backgroundView})
                self.backgroundItems = screens[currentState].items.filter({$0.type == .backgroundView})
            }
            
        } else {
            Task {
                try await OnboardingUIManager.shared.sendEvent(event: .onboardingCompleted, parameters: [
                    "onboarding_id": "\(response.onboarding.id)",
                    "screen_id": "\(screens[currentState].id)"])
            }
            OnboardingUIManager.shared.eventPassthrough.send(.onboardingCompleted)
        }
    }
}

public struct OnboardingScreenTabView: View {

    @StateObject var viewModel = OnboardingScreenTabViewModel()

    public var body: some View {
        OnboardingPreviewView(backgroundElements: viewModel.backgroundItems, elements: viewModel.items, onCtaAction: viewModel.onCtaAction)
            .transition(
                .asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                )
            )
            .animation(
                .spring(
                    response: 0.5,
                    dampingFraction: 0.8,
                    blendDuration: 0.3
                ),
                value: true
            )
            .ignoresSafeArea()
            .id(viewModel.screens.isEmpty ? 0 : viewModel.screens[viewModel.currentState].id)
    }
}

#Preview {
    OnboardingScreenTabView()
}
