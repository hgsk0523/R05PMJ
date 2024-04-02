import Foundation
import APIKit

// MARK: - Property

let BASE_URL: String = "https://dy9dljvib3.execute-api.ap-northeast-1.amazonaws.com/v2/"
let S3_BUCKET_NAME: String = "dev-pmj-configuration-bucket"
let X_API_KEY: [String:String] = ["x-api-key":"skwRJXan0m1oCBJePO33pam9hssSSink8axkP16W"]

/// 処理のリトライ回数
let MAX_RETRY: Int = 3

/// EncodableをJSONとしてBodyparamatersに変換する
final class EncodableBodyParamaters<T: Encodable>: BodyParameters {
    
    let contentType: String = "application/json"

    let encodable: T

    init(_ encodable: T) {
        self.encodable = encodable
    }

    func buildEntity() throws -> RequestBodyEntity {
        let encoder = JSONEncoder()
        // フォーマットを指定
        encoder.outputFormatting = .prettyPrinted
        // エンコード
        let jsonData = try encoder.encode(encodable)

        return .data(jsonData)
    }
}

/// リトライ処理
/// - Parameter task: 実際に行う処理
func retry(task: @escaping() throws -> Void) throws {
    // エラー返却用
    var errorInfo: Error?
    
    // 上限に達するか処理が成功するまでループ
    for _ in 0 ..< MAX_RETRY {
        do {
            try task()
            return
        } catch {
            // エラ-内容保存
            errorInfo = error
            // コンティニュー
            continue
        }
    }
    // リトライ回数上限内で処理が成功しなかったらエラーを返す
    throw errorInfo!
}
