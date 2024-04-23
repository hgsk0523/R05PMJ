import Foundation

/// モデル全体の設定／固定値を保持
struct ModelConfiguration {
    
    // MARK: - Property
    
    /// 接続先環境
    static var environment: URL {
        let environmentStr: String
        environmentStr = BASE_URL
        
        guard let environment = URL(string: environmentStr) else {
            fatalError("failed to create url. url: \(environmentStr)")
        }
        
        return environment
    }
    
    /// ルートディレクトリ
    let modelFileDirectory: URL
    
    // MARK: - Initializer
    
    init(modelFileDirectory: URL) {
        self.modelFileDirectory = modelFileDirectory
    }
}

