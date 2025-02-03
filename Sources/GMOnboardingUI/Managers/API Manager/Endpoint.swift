//
//  Endpoint.swift
//  AI-Avatar
//
//  Created by Mert Serin on 2024-05-31.
//

import Foundation

extension Data {
    mutating func appendString(_ string: String) {
        if let data = string.data(using: .utf8) {
            self.append(data)
        }
    }
}

protocol Router {
    func asURLRequest(with header: [String: String]) -> URLRequest
}

protocol FakeRouter: Router {
    var fakeStatusCode: Int { get }
    var fakeJSONPath: String? { get }
}

enum Endpoint {
    case initializeApp(Encodable)
    case sendEvent(Encodable)
}

extension Endpoint {
    enum RequestType {
        case normal, multipart, formEncoded
    }

    var url: URL {
        switch self {
        case .initializeApp:
            return .makeForEndpoint("/initializeApp")
        case .sendEvent:
            return .makeForEndpoint("/sendEvent")
        }
    }

    private var httpMethod: String {
        switch self {
        case .initializeApp:
            return "POST"
        case .sendEvent:
            return "POST"
        }
    }

    private var body: Data? {
        switch self {
        case .initializeApp(let model):
            return model.asData
        case .sendEvent(let model):
            return model.asData
        default:
            return nil
        }
    }

    var requestType: RequestType {
        switch self {
        default: return .normal
        }
    }

    func asURLRequest(with header: [String: String]) -> URLRequest {
        var urlRequest = URLRequest(url: self.url)
        urlRequest.httpMethod = httpMethod
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        header.forEach({
            urlRequest.setValue($0.value, forHTTPHeaderField: $0.key)
        })

        if self.requestType == .multipart {
            let boundary = "\(UUID().uuidString)"
            urlRequest.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("\(body?.count ?? 0)", forHTTPHeaderField:"Content-Length")
        }

        if self.requestType == .formEncoded {
            urlRequest.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        }

        urlRequest.httpBody = self.body
        return urlRequest
    }

    func multipartData() -> Data{
        guard let data = self.body,
              self.requestType == .multipart
        else { fatalError("Data can not be null")}

        return data
    }

    func stubbed<T: Decodable>(model: T) -> T {
        return model
    }
}

extension Endpoint: FakeRouter {
    var fakeStatusCode: Int {
        switch self {
        default: return 200
        }
    }

    var fakeJSONPath: String? {
        switch self {
        default: return nil
        }
    }
}

extension URL {
    func appending(_ queryItem: String, value: String?) -> URL {
        guard var urlComponents = URLComponents(string: absoluteString) else { return absoluteURL }

        // Create array of existing query items
        var queryItems: [URLQueryItem] = urlComponents.queryItems ??  []

        // Create query item
        let queryItem = URLQueryItem(name: queryItem, value: value)

        // Append the new query item in the existing query items array
        queryItems.append(queryItem)

        // Append updated query items array in the url component object
        urlComponents.queryItems = queryItems

        // Returns the url from new url components
        return urlComponents.url!
    }
}

extension Encodable {

    func toJSONString() -> String {
        let jsonData = try! JSONEncoder().encode(self)
        return String(data: jsonData, encoding: .utf8)!
    }

    var asData: Data? {
        let encoder = try? JSONEncoder().encode(self)
        return encoder
    }
}

extension URL {
    static private var baseURL: String { "https://gm-onboarding-55f2c13ada3e.herokuapp.com"} // Actual server
    //    static private var baseURL: String { "http://localhost:5001"}  /*Simulator*/

    static func makeForEndpoint(baseURL: String = URL.baseURL, _ endpoint: String) -> URL {
        URL(string: "\(baseURL)\(endpoint)")!
    }
}
