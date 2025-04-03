import Foundation

struct InitializeAppResponseModel: Codable {
    let onboarding: Onboarding
    let session: Session
}

public struct Onboarding: Codable {
    public let id: Int
    public let screens: [ScreenItem]
    public let onboardingID: Int

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case screens = "screens"
        case onboardingID = "onboardingID"
    }
}

public struct ScreenItem: Codable {
    public let id: Int
    public let title: String
    public let items: [OnboardingScreenItem]
}

struct Session: Codable {
    let token: String

    enum CodingKeys: String, CodingKey {
        case token = "token"
    }
}
