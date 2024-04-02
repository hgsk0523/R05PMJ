import Foundation
import APIKit

/// API共通のリクエストデータ型
protocol BaseApiRequst: Request where Response: Decodable {
    
}

extension BaseApiRequst {
    
    /// API接続環境
    var environment: URL {
        return ModelConfiguration.environment
    }
    
    /// API接続先URL
    var baseURL: URL {
        return environment
    }
    
    /// DataParser
    /// intercept／responseに渡されるobjectの値を設定
    var dataParser: DataParser {
        return BaseApiDataParser()
    }
    
    func intercept(object: Any, urlResponse: HTTPURLResponse) throws -> Any {
        // 共通バリデーション処理
        let _ = try validation(object, urlResponse: urlResponse)
        return object
    }
    
    /// API共通バリデーション処理
    func validation(_ object: Any, urlResponse: HTTPURLResponse) throws -> Data {
        
        // ステータスコード判定
        guard 200 ..< 300 ~= urlResponse.statusCode else {
            throw ResponseError.unacceptableStatusCode(urlResponse.statusCode)
        }
        
                // レスポンスオブジェクトの形式チェック
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        return data
    }
    
    /// レスポンス受信
    func response(from object: Any, urlResponse: HTTPURLResponse) throws -> Response {
        // レスポンスオブジェクトの形式チェック
        guard let data = object as? Data else {
            throw ResponseError.unexpectedObject(object)
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}
