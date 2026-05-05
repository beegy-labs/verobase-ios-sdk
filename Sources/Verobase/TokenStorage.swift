import Foundation
import Security

/// Stores tokens securely in the iOS Keychain.
final class TokenStorage {
    private let service: String
    private let accessTokenKey = "verobase_access_token"
    private let refreshTokenKey = "verobase_refresh_token"
    private let anonymousIdKey  = "verobase_anonymous_id"

    init(service: String) {
        self.service = service
    }

    func getAccessToken() -> String? {
        return read(key: accessTokenKey)
    }

    func getRefreshToken() -> String? {
        return read(key: refreshTokenKey)
    }

    func setTokens(accessToken: String, refreshToken: String) {
        write(key: accessTokenKey, value: accessToken)
        write(key: refreshTokenKey, value: refreshToken)
    }

    func clearTokens() {
        delete(key: accessTokenKey)
        delete(key: refreshTokenKey)
    }

    /// Returns the persisted anonymous ID, creating and storing a new UUID if none exists.
    func getOrCreateAnonymousId() -> String {
        if let existing = read(key: anonymousIdKey) { return existing }
        let newId = UUID().uuidString
        write(key: anonymousIdKey, value: newId)
        return newId
    }

    // MARK: - Keychain helpers

    private func read(key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String:            kSecClassGenericPassword,
            kSecAttrService as String:      service,
            kSecAttrAccount as String:      key,
            kSecReturnData as String:       true,
            kSecMatchLimit as String:       kSecMatchLimitOne,
        ]
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        return value
    }

    private func write(key: String, value: String) {
        guard let data = value.data(using: .utf8) else { return }
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key,
        ]
        let attrs: [String: Any] = [kSecValueData as String: data]
        if SecItemUpdate(query as CFDictionary, attrs as CFDictionary) == errSecItemNotFound {
            var addQuery = query
            addQuery[kSecValueData as String] = data
            SecItemAdd(addQuery as CFDictionary, nil)
        }
    }

    private func delete(key: String) {
        let query: [String: Any] = [
            kSecClass as String:        kSecClassGenericPassword,
            kSecAttrService as String:  service,
            kSecAttrAccount as String:  key,
        ]
        SecItemDelete(query as CFDictionary)
    }
}
