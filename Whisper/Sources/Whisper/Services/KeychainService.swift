import Foundation
import Security

// MARK: - KeychainService

/// macOS Keychain を使用して API キーを安全に管理するサービス
final class KeychainService {

    // MARK: - 定数

    private static let serviceName = "com.whisper.app"

    enum KeychainKey: String {
        case geminiAPIKey = "gemini-api-key"
    }

    // MARK: - 保存

    /// Keychain にデータを保存する
    /// - Parameters:
    ///   - key: キー名
    ///   - value: 保存する文字列値
    /// - Returns: 保存に成功した場合 true
    @discardableResult
    static func save(key: KeychainKey, value: String) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // 既存のアイテムを削除
        delete(key: key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - 取得

    /// Keychain からデータを取得する
    /// - Parameter key: キー名
    /// - Returns: 保存された文字列値。見つからない場合は nil
    static func load(key: KeychainKey) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }

    // MARK: - 削除

    /// Keychain からデータを削除する
    /// - Parameter key: キー名
    /// - Returns: 削除に成功した場合 true
    @discardableResult
    static func delete(key: KeychainKey) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - 存在確認

    /// Keychain にデータが存在するかを確認する
    /// - Parameter key: キー名
    /// - Returns: 存在する場合 true
    static func exists(key: KeychainKey) -> Bool {
        return load(key: key) != nil
    }
}
