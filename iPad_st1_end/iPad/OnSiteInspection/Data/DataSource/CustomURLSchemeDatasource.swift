import Foundation

/// カスタムURLスキーマデータソース
class CustomURLSchemeDatasource: NSObject {
    
    // MARK: - Property
    /// シングルトン
    private override init() {}
    public static let shared = CustomURLSchemeDatasource()
    
    /// パラメータ情報
    var parametersInfo = ParametersInfo()
        
    // MARK: - Method
 
    /// パラメータをセット
    func setCustomURLSchemeParameters(url: URL) throws {
        do {
            try parametersInfo.setParametersInfo(url: url)
        } catch {
            throw error
        }
    }
    
    /// パラメータ情報を返す
    /// - Returns: パラメータ情報
    func getCustomURLSchemeParameters() -> ParametersInfo {
        return self.parametersInfo
    }
    
    /// モデルチェックフラグをtrueにする
    func setModelCheckFlag(flag: Bool) {
        self.parametersInfo.modelCheckFlag = flag
    }
    
    /// モデルチェックフラグを取得
    /// - Returns: modelチェックフラグ
    func getModelCheckFlag() -> Bool {
        return self.parametersInfo.modelCheckFlag
    }
}
