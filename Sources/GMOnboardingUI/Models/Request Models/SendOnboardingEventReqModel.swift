import Foundation

struct SendEventRequestModel: Codable {
    let event: String
    let attributes: [String: String]

    enum CodingKeys: String, CodingKey {
        case event = "event"
        case attributes = "attributes"
    }
}
