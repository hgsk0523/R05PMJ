import Foundation
import Security

/// Keychainデータの共通管理プロトコル
protocol KeychainDataSourceProtocol {
    /// Realm暗号化キー取得
    func getRealmEncryptionKeys() throws -> Data
    /// キー取得
    func getKey(for name: String) -> Data?
    /// キー保存
    func saveKey(for name: String, data: Data)
}

/// Keychainデータの共通管理
final class KeychainDataSource: KeychainDataSourceProtocol {
    
    // MARK: - Property
    
    /// Realm暗号化キー名
    private static let realmEncryptionKeyName = "EncryptionKey"
    /// Realm暗号化キー保存用のキーの長さ
    private static let keyLength = 64
    /// 暗号化されたキーの長さ
    private static let cryptographicKeyLength = 512
    /// キーチェイン
    private let keychain = "keychain"
    
    // MARK: - Method
    
    /// KeychainのID生成
    /// - NOTE: Bundle ID + ".keys." + name
    ///
    /// - Parameter name: キー名
    /// - Returns: 生成したID
    private func generateIdentifier(with name: String) -> Data? {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? self.keychain
        let identifier = "\(bundleIdentifier).keys.\(name)"
        return identifier.data(using: .utf8, allowLossyConversion: false)
    }
    
    /// Realm暗号化キー取得
    /// - NOTE: キーがない場合は新規作成
    ///
    /// - Returns: 取得したキー
    func getRealmEncryptionKeys() throws -> Data {
        do {
            if let key = getKey(for: KeychainDataSource.realmEncryptionKeyName) {
                return key
            }
            
            // キー生成
            let keyLength = KeychainDataSource.keyLength
            guard let data = NSMutableData(length: keyLength) else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            let status = SecRandomCopyBytes(kSecRandomDefault, keyLength, data.mutableBytes.bindMemory(to: UInt8.self, capacity: keyLength))
            guard status == errSecSuccess else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            // キー保存
            saveKey(for: KeychainDataSource.realmEncryptionKeyName, data: data as Data)
            
            return data as Data
        } catch {
            throw error
        }
    }
    
    /// キー取得
    ///
    /// - Parameter name: キー名
    /// - Returns: 取得したキー(取得できない場合はnil)
    func getKey(for name: String) -> Data? {
        let query = [
            kSecClass: kSecClassKey,
            kSecAttrApplicationTag: generateIdentifier(with: name) as AnyObject,
            kSecAttrKeySizeInBits: KeychainDataSource.cryptographicKeyLength as AnyObject,
            kSecReturnData: true as AnyObject
        ] as CFDictionary
        
        var dataTypeRef: AnyObject?
        let status = withUnsafeMutablePointer(to: &dataTypeRef) { SecItemCopyMatching(query, UnsafeMutablePointer($0)) }
        if status == errSecSuccess {
            return dataTypeRef as? Data
        }
        return nil
    }
    
    /// キー保存
    ///
    /// - Parameters:
    ///   - name: キー名
    ///   - data: キーデータ
    func saveKey(for name: String, data: Data) {
        do {
            let query = [
                kSecClass: kSecClassKey,
                kSecAttrApplicationTag: generateIdentifier(with: name) as AnyObject,
                kSecAttrKeySizeInBits: KeychainDataSource.cryptographicKeyLength as AnyObject,
                kSecValueData: data as AnyObject,
                kSecAttrSynchronizable: false as AnyObject,
                kSecAttrAccessible: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            ] as CFDictionary
            
            let status = SecItemAdd(query, nil)
            if status != errSecSuccess {
                // エラーを返却
                throw ErrorID.ID9999
            }
        } catch {
            // エラーログ出力
            errorLog(message: "キーの保存に失敗しました。", error: error)
        }
    }
}
