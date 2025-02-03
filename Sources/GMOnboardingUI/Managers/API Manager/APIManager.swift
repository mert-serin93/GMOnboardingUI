//
//  APIManager.swift
//  AI-Avatar
//
//  Created by Mert Serin on 2024-05-31.
//

import Combine
import Foundation
import UIKit

struct Response<T, U> {
    let value: T?
    let error: U?
    let response: URLResponse
}

protocol RealAPIManager {
    var session: URLSession { get }

    func run<T: Decodable>(_ endpoint: Endpoint, authorizationHeader: [String:String]?, stubbedData: T?) async throws -> T
    func runMultipart<T: Decodable>(_ endpoint: Endpoint, authorizationHeader: [String:String]?) async throws -> T
}

extension RealAPIManager {
    var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatter = OptionalFractionalSecondsDateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
        return decoder
    }
}

struct APIErrorResponseModel: Decodable {

}

struct APIManager: RealAPIManager {
    var session: URLSession = URLSession.shared

    // MARK: Async
    func run<T: Decodable>(_ endpoint: Endpoint, authorizationHeader: [String:String]?, stubbedData: T? = nil) async throws -> T {

        if let stubbedData = stubbedData {
            return stubbedData
        }

        var (data, response): (Data, URLResponse)
        if #available(iOS 15.0, *) {
            (data, response) = try await URLSession.shared.data(for: endpoint.asURLRequest(with: authorizationHeader ?? [:]), delegate: nil)
        } else {
            (data, response) = try await URLSession.shared.data(from: endpoint.asURLRequest(with: authorizationHeader ?? [:]))
        }

        if let response = response as? HTTPURLResponse, (400...600).contains(response.statusCode) {
            let error = try decoder.decode(APIErrorResponseModel.self, from: data)

            throw NetworkError.serverError(error)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw NetworkError.decode
        }


    }

    func runMultipart<T: Decodable>(_ endpoint: Endpoint, authorizationHeader: [String:String]?) async throws -> T {
        var request = URLRequest(url: endpoint.url)
        let boundary = "Boundary-\(UUID().uuidString)"
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        for (key, value) in authorizationHeader ?? [:] {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Create form data
        let formData = createFormData(
            parameters: [:],
            fileData: endpoint.multipartData(),
            fileName: "test",
            fieldName: "image",
            boundary: boundary
        )

        request.httpBody = formData

        // Make the request using async/await
        let (data, response) = try await URLSession.shared.data(for: request)
        if let response = response as? HTTPURLResponse, (400...600).contains(response.statusCode) {
            let error = try decoder.decode(APIErrorResponseModel.self, from: data)
            throw NetworkError.serverError(error)
        }

        return try decoder.decode(T.self, from: data)
    }

    func createFormData(parameters: [String: Any], fileData: Data, fileName: String, fieldName: String, boundary: String) -> Data {
        var bodyData = Data()
        // Add parameters
        for (key, value) in parameters {
            bodyData.append("--\(boundary)\r\n")
            bodyData.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n")
            bodyData.append("\(value)\r\n")
        }

        // Add file data
        bodyData.append("--\(boundary)\r\n")
        bodyData.append("Content-Disposition: form-data; name=\"\(fieldName)\"; filename=\"\(fileName)\"\r\n")
        bodyData.append("Content-Type: application/octet-stream\r\n\r\n")
        bodyData.append(fileData)
        bodyData.append("\r\n")

        // Add final boundary
        bodyData.append("--\(boundary)--\r\n")

        return bodyData
    }
}

struct FakeAPIManager: RealAPIManager {
    var session: URLSession = URLSession.shared

    func run<T: Decodable>(_ endpoint: Endpoint, authorizationHeader: [String:String]?, stubbedData: T?) async throws -> T {
        guard let bundlePath = Bundle.main.path(forResource: endpoint.fakeJSONPath, ofType: "json"),
              let data = try? String(contentsOfFile: bundlePath).data(using: .utf8) else {
            throw  NetworkError.noData
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            debugPrint(error)
            throw error
        }
    }

    func runMultipart<T>(_ endpoint: Endpoint, authorizationHeader: [String:String]?) async throws -> T {
        fatalError("Not implemented yet")
    }
}

enum NetworkError: Error {
    case serverError(APIErrorResponseModel)
    case statusCode
    case noData
    case decode
    case notImplemented
}

//MARK: - Extensions

extension Task where Failure == Error {
    @discardableResult
    static func retrying(
        priority: TaskPriority? = nil,
        maxRetryCount: Int = 3,
        retryDelay: TimeInterval = 1,
        operation: @Sendable @escaping () async throws -> Success
    ) -> Task {
        Task(priority: priority) {
            for _ in 0..<maxRetryCount {
                do {
                    return try await operation()
                } catch {
                    let oneSecond = TimeInterval(1_000_000_000)
                    let delay = UInt64(oneSecond * retryDelay)
                    try await Task<Never, Never>.sleep(nanoseconds: delay)

                    continue
                }
            }

            try Task<Never, Never>.checkCancellation()
            return try await operation()
        }
    }
}

@available(iOS, deprecated: 15.0, message: "Use the built-in API instead")
extension URLSession {
    func data(from urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            let task = self.dataTask(with: urlRequest) { data, response, error in
                guard let data = data, let response = response else {
                    let error = error ?? URLError(.badServerResponse)
                    return continuation.resume(throwing: error)
                }

                continuation.resume(returning: (data, response))
            }

            task.resume()
        }
    }
}

//extension URLSession {
//    func dataMultipart(from endpoint: Endpoint, header: [String: String]) async throws -> (Data, URLResponse) {
//         try await withCheckedThrowingContinuation { continuation in
//             let task = self.upload(for: endpoint.asURLRequest(with: header), from: endpoint.multipartData())
//             let task = self.uploadTask(with: , from: ) { data, response, error in
//                 guard let data = data, let response = response else {
//                     let error = error ?? URLError(.badServerResponse)
//                     return continuation.resume(throwing: error)
//                 }
//
//                 continuation.resume(returning: (data, response))
//             }
//
//             task.resume()
//        }
//    }
//}


import Foundation

extension URLRequest {
    public func cURL(pretty: Bool = false) -> String {
        let newLine = pretty ? "\\\n" : ""
        let method = (pretty ? "--request " : "-X ") + "\(self.httpMethod ?? "GET") \(newLine)"
        let url: String = (pretty ? "--url " : "") + "\'\(self.url?.absoluteString ?? "")\' \(newLine)"

        var cURL = "curl "
        var header = ""
        var data: String = ""

        if let httpHeaders = self.allHTTPHeaderFields, httpHeaders.keys.count > 0 {
            for (key,value) in httpHeaders {
                header += (pretty ? "--header " : "-H ") + "\'\(key): \(value)\' \(newLine)"
            }
        }

        if let bodyData = self.httpBody, let bodyString = String(data: bodyData, encoding: .utf8),  !bodyString.isEmpty {
            data = "--data '\(bodyString)'"
            let escaped = bodyString.replacingOccurrences(of: "'", with: "'\\''")   // important to escape ' so it become '\'' that would work in command line
            data = "--data '\(escaped)'"
        }

        cURL += method + url + header + data

        return cURL
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}

class OptionalFractionalSecondsDateFormatter: DateFormatter {

     // NOTE: iOS 11.3 added fractional second support to ISO8601DateFormatter,
     // but it behaves the same as plain DateFormatter. It is either enabled
     // and required, or disabled and... anti-required
     // let formatter = ISO8601DateFormatter()
     // formatter.timeZone = TimeZone(secondsFromGMT: 0)
     // formatter.formatOptions = [.withInternetDateTime ] // .withFractionalSeconds

    static let dateFormatter = OptionalFractionalSecondsDateFormatter()

    static let withoutSeconds: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return formatter
    }()

    func setup() {
        self.calendar = Calendar(identifier: .iso8601)
        self.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSXXX" // handle up to 6 decimal places, although iOS currently only preserves 2 digits of precision
    }

    override init() {
        super.init()
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func date(from string: String) -> Date? {

        if let result = super.date(from: string) {
            return result
        }
        return OptionalFractionalSecondsDateFormatter.withoutSeconds.date(from: string)
    }
}
