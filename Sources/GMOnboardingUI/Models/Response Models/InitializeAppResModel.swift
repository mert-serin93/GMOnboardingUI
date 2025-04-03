import Foundation

struct InitializeAppResponseModel: Codable {
    let onboarding: Onboarding
    let session: Session
}

public struct Onboarding: Codable {
    let id: Int
    let screens: [ScreenItem]
    let onboardingID: Int

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case screens = "screens"
        case onboardingID = "onboardingID"
    }
}

struct ScreenItem: Codable {
    let id: Int
    let title: String
    let items: [OnboardingScreenItem]
}

struct Session: Codable {
    let token: String

    enum CodingKeys: String, CodingKey {
        case token = "token"
    }
}
