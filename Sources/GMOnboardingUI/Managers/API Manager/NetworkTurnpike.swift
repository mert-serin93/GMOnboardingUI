//
//  NetworkTurnpike.swift
//  AI-Avatar
//
//  Created by Mert Serin on 2024-05-31.
//

import Foundation
import StoreKit

struct EmptyResponseModel: Decodable { }
//
struct NetworkTurnpike {
    var agent: RealAPIManager
    
    init(agent: RealAPIManager) {
        self.agent = agent
    }
    
    static func mock() -> NetworkTurnpike { NetworkTurnpike(agent: FakeAPIManager.init()) }
}

extension NetworkTurnpike {
    func run<T: Decodable>(_ request: Endpoint, authorizationHeader: [String: String]? = nil) async throws -> T {
        return try await agent.run(request, authorizationHeader: authorizationHeader, stubbedData: nil)
    }

    func initializeApp(with model: InitializeAppRequestModel, authorizationHeader: [String: String]? = nil) async throws -> InitializeAppResponseModel {
        return try await agent.run(.initializeApp(model), authorizationHeader: authorizationHeader, stubbedData: nil)
    }

    func sendEvent(with model: SendEventRequestModel, authorizationHeader: [String: String]? = nil) async throws -> EmptyResponseModel {
        return try await agent.run(.sendEvent(model), authorizationHeader: authorizationHeader, stubbedData: nil)
    }
}

extension Bundle {
    public var appName: String           { getInfo("CFBundleName") }
    public var displayName: String       { getInfo("CFBundleDisplayName") }
    public var language: String          { getInfo("CFBundleDevelopmentRegion") }
    public var identifier: String        { getInfo("CFBundleIdentifier") }
    public var copyright: String         { getInfo("NSHumanReadableCopyright").replacingOccurrences(of: "\\\\n", with: "\n") }
    
    public var appBuild: String          { getInfo("CFBundleVersion") }
    public var appVersionLong: String    { getInfo("CFBundleShortVersionString") }
    //public var appVersionShort: String { getInfo("CFBundleShortVersion") }
    
    fileprivate func getInfo(_ str: String) -> String { infoDictionary?[str] as? String ?? "⚠️" }
}

