import RealmSwift

/// Realmオブジェクトの共通管理のプロトコル
protocol BaseRealmDataSourceProtocol {
    /// Realmオブジェクト生成
    func getRealm() throws -> Realm
}

/// Realmオブジェクトの共通管理
final class BaseRealmDataSource: BaseRealmDataSourceProtocol {
    
    // MARK: - Property
    
    /// 最新のスキームバージョン
    /// 最小は1
    /// 開発時は100から始め
    /// テスト時はフェーズの番号を入れる(例：フェーズ3 →3
    private static let latestSchemeVersion: UInt64 = 112
    
    private let realmConfiguration: Realm.Configuration
    /// データベース
    private let database = "Database"
    /// データベースRealm
    private let databaseRealm = "database.realm"
    
    // MARK: - Initializer
    
    init(fileURL: URL, keychainDataSource: KeychainDataSourceProtocol) {
        do {
            var configuration = Realm.Configuration()
            // ディレクトリ生成
            var directryURL = fileURL.appendingPathComponent("Database", isDirectory: true)

            try FileManager.default.createDirectory(at: directryURL, withIntermediateDirectories: true)
            
            // バックアップ対象外とする
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            try directryURL.setResourceValues(resourceValues)
            // バージョン設定
            configuration.schemaVersion = BaseRealmDataSource.latestSchemeVersion
            // ファイルURL設定
            configuration.fileURL = directryURL.appendingPathComponent(self.databaseRealm)
            // 暗号化キー設定
            configuration.encryptionKey = try keychainDataSource.getRealmEncryptionKeys()
            // realmインスタンス生成
            _ = try Realm(configuration: configuration)
            self.realmConfiguration = configuration
        } catch {
            // エラーログ出力
            errorLog(message: "Realmオブジェクトの初期化に失敗しました。", error: error)
            // デフォルトのコンフィギュレーションを設定
            self.realmConfiguration = Realm.Configuration()
        }
    }
    
    /// Realmオブジェクト生成
    /// - エラー時、RealmConnectFailedを返す
    /// - Returns: Realm オブジェクト
    func getRealm() throws -> Realm {
        do {
            return try Realm(configuration: self.realmConfiguration)
        } catch {
            throw error
        }
    }
}
