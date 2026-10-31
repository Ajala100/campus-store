import Foundation
import Security
import StoreCore

/// Saves the session token in the **Keychain**, not UserDefaults.
///
/// UserDefaults is a plain file that ends up in backups and is readable by anyone with
/// access to the device's files. The Keychain is an encrypted store managed by iOS.
/// `kSecAttrAccessibleWhenUnlockedThisDeviceOnly` means:
///   • WhenUnlocked — the token can only be read while the phone is unlocked;
///   • ThisDeviceOnly — it is never copied to iCloud backups or a new phone.
/// Only the token is stored. The password never is.
final class KeychainSessionStore: SessionStoring, @unchecked Sendable {

    enum KeychainError: Error { case unexpectedStatus(OSStatus) }

    private let service: String
    private let account = "session"

    init(service: String = Bundle.main.bundleIdentifier ?? "ng.edu.nutm.campusstore") {
        self.service = service
    }

    private var baseQuery: [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    func load() throws -> Session? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { return nil }
            return try JSONDecoder().decode(Session.self, from: data)
        case errSecItemNotFound:
            return nil
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }

    func save(_ session: Session) throws {
        let data = try JSONEncoder().encode(session)
        SecItemDelete(baseQuery as CFDictionary)           // delete-then-add = a simple "upsert"
        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw KeychainError.unexpectedStatus(status) }
    }

    func clear() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
