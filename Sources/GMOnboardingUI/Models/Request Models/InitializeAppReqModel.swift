import Foundation

struct InitializeAppRequestModel: Codable {
    let apiKey: String
    let deviceID: String
    let deviceOS: String
    let appVersion: String
    let deviceModel: String
    let deviceLocale: String
    let appStoreCountry: String

    enum CodingKeys: String, CodingKey {
        case apiKey = "apiKey"
        case deviceID = "deviceID"
        case deviceOS = "deviceOS"
        case appVersion = "appVersion"
        case deviceModel = "deviceModel"
        case deviceLocale = "deviceLocale"
        case appStoreCountry = "appStoreCountry"
    }
}

