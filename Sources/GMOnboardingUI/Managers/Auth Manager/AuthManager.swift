//
//  AuthManager.swift
//  GMOnboardingUI
//
//  Created by Mert Serin on 2024-12-03.
//

import SwiftKeychainWrapper
import SwiftUI

final class AuthManager: ObservableObject {
    @AppStorage("hasStartedOnboarding")
    private var hasStartedOnboarding: Bool = false

    @KeychainStorage("onboarding", credentialsManager: UserCredentialsManager())
    private var onboarding: InitializeAppResponseModel?

    init() {
        if !hasStartedOnboarding {
            save(with: nil)
        }
    }

    func save(with onboarding: InitializeAppResponseModel?) {
        self.onboarding = onboarding
    }

    func getOnboarding() -> InitializeAppResponseModel? {
        return onboarding
    }

    func getAuthHeader() -> [String: String] {
        guard let onboarding else { return [:] }
        return ["Authorization": "Bearer \(onboarding.session.token)"]
    }

    func setHasStartedOnboarding(with value: Bool) {
        hasStartedOnboarding = true
    }
}

@propertyWrapper
struct KeychainStorage<T: Codable>: DynamicProperty {
    let key: String
    let credentialsManager: UserCredentialsManagerImpl
    @State private var value: T?

    init(wrappedValue: T? = nil, _ key: String, credentialsManager: UserCredentialsManagerImpl) {
        self.key = key
        var initialValue = wrappedValue
        self._value = State<T?>(initialValue: initialValue)
        self.credentialsManager = credentialsManager
        initialValue = getInitialValue()
    }
    var wrappedValue: T? {
        get  {
            return getInitialValue()
        }
        set {
            guard let newValue = newValue,
                  let encoded = try? JSONEncoder().encode(newValue)
            else {
                self.value = nil
                credentialsManager.remove(forKey: key)
                return
            }
            credentialsManager.set(value: encoded, forKey: key)
        }
    }

    func getInitialValue() -> T? {
        if let data = credentialsManager.get(forKey: key) {
            return try? JSONDecoder().decode(T.self, from: data)
        }
        return nil
    }
}

protocol UserCredentialsManagerImpl {
    func set(value: Data, forKey: String)
    func remove(forKey: String)
    func get(forKey: String) -> Data?
}

struct UserCredentialsManager: UserCredentialsManagerImpl {

    init(keychainManager: KeychainWrapper = .standard) {
        self.keychainManager = keychainManager
    }

    private let keychainManager: KeychainWrapper

    func set(value: Data, forKey: String) {
        keychainManager.set(value, forKey: forKey)
    }

    func get(forKey: String) -> Data? {
        let data = keychainManager.data(forKey: forKey)
        return data
    }

    func remove(forKey: String) {
        keychainManager.removeObject(forKey: forKey)
    }
}

struct MockUserCredentialsManager: UserCredentialsManagerImpl {
    init(keychainManager: KeychainWrapper = .init(serviceName: "MockUserCredentialsManager",
                                                  accessGroup: nil)) {
        self.keychainManager = keychainManager
    }

    private let keychainManager: KeychainWrapper

    func set(value: Data, forKey: String) {
        keychainManager.set(value, forKey: forKey)
    }

    func get(forKey: String) -> Data? {
        keychainManager.data(forKey: "")
    }

    func remove(forKey: String) {
        keychainManager.removeObject(forKey: forKey)
    }
}
