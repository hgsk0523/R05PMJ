import Foundation
import APIKit

/// API共通で使用するDataPaser
/// Data型をそのまま返却
struct BaseApiDataParser: DataParser {
    
    let contentType: String? = "application/json"
    
    /// intercept／responseに渡されるobjectの値を設定
    func parse(data: Data) throws -> Any {
        data
    }
}
