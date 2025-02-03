//
//  OnboardingUIManager.swift
//  GMOnboardingUI
//
//  Created by Mert Serin on 2024-12-03.
//

import Combine
import SwiftUI
import StoreKit

final public class OnboardingUIManager: ObservableObject {

    private let networkManager = NetworkTurnpike(agent: APIManager())
    private let authManager = AuthManager()
    let configuration: OnboardingConfiguration

    public init(key: String, customerUserId: String, configuration: OnboardingConfiguration) {
        self.configuration = configuration
        Task {
            if let response = authManager.getOnboarding() {
                await MainActor.run {
                    eventPassthrough.send(.appInitialized)
                }
                return
            }
            do {
                let response = try await initializeApp(key: key, customerUserId: customerUserId)
                authManager.save(with: response)
                authManager.setHasStartedOnboarding(with: true)
                await MainActor.run {
                    eventPassthrough.send(.appInitialized)
                }
            } catch {
                await MainActor.run {
                    eventPassthrough.send(.appInitializedFailed(error))
                }
            }
        }
    }

    public static func configure(key: String, customerUserId: String, configuration: OnboardingConfiguration = .mock()) {
        if shared == nil {
            shared = OnboardingUIManager(key: key, customerUserId: customerUserId, configuration: configuration)
        } else {
            fatalError("Premium Manager can be configured only once.")
        }
    }

    public static var shared: OnboardingUIManager!
    public var eventPassthrough: PassthroughSubject<Events, Never> = .init()

    private func initializeApp(key: String, customerUserId: String) async throws -> InitializeAppResponseModel {

        let model = InitializeAppRequestModel(apiKey: key,
                                              deviceID: customerUserId,
                                              deviceOS: UIDevice.current.systemVersion,
                                              appVersion: UIApplication.appVersion(),
                                              deviceModel: UIDevice.modelName,
                                              deviceLocale: Locale.current.region?.identifier ?? "",
                                              appStoreCountry: SKPaymentQueue.default().storefront?.countryCode ?? Locale.current.region?.identifier ?? "")
        return try await networkManager.initializeApp(with: model, authorizationHeader: nil)
    }
    
    func sendEvent(event: OnboardingAnalyticsEvent, parameters: [String: String] = [:]) async throws -> EmptyResponseModel {
        let model = SendEventRequestModel(event: event.rawValue, attributes: parameters)
        return try await networkManager.sendEvent(with: model, authorizationHeader: authManager.getAuthHeader())
    }
}

enum OnboardingAnalyticsEvent: String {
    case onboardingStarted = "onboarding_started"
    case onboardingScreenViewed = "onboarding_screen_viewed"
    case onboardingCompleted = "onboarding_completed"
}

extension OnboardingUIManager {
    public enum Events {
        case appInitialized
        case appInitializedFailed(Error)

        case onboardingStarted
        case onboardingCompleted
    }
}

extension UIApplication {
    class func appVersion() -> String {
        return Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
    }

    class func appBuild() -> String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }

    class func versionBuild() -> String {
        let version = appVersion(), build = appBuild()
        return version == build ? "v\(version)" : "v\(version)(\(build))"
    }

    static func requestReview(delay: CGFloat = 0.3) {
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delay) {
            if let scene = UIApplication.shared.connectedScenes.first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        }
    }
}
