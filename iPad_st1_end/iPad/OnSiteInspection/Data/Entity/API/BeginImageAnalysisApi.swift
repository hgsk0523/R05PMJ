import Foundation
import APIKit

/// AI解析指示API
struct BeginImageAnalysisApiRequest: BaseApiRequst {
    
    typealias Response = BeginImageAnalysisApiResponse
    
    let path = "begin-image-analysis"
    
    let method : HTTPMethod = .post
    
    var bodyParameters: BodyParameters? = nil
    
    let headerFields: [String : String] = X_API_KEY
    
    init(body: BeginImageAnalysistApiRequestBody) {
        self.bodyParameters = EncodableBodyParamaters(body)
    }
}

/// リクエスト(Body)
struct BeginImageAnalysistApiRequestBody: Encodable {
    /// 点検ID
    let inspectionId: Int
    /// 点検項目ID
    let inspectionItemId: Int
    /// バケット名
    let bucketName: String
    /// オリジナル画像パス
    let originalImagePath: String
    /// トリミング画像パス
    let trimmingImagePath: String
}

/// レスポンス
struct BeginImageAnalysisApiResponse: Decodable {
    /// 結果コード
    let resultCode: Int
    /// 点検ID
    let inspectionId: Int?
    /// 点検項目ID
    let inspectionItemId: Int?
    /// 進捗状況
    let progress: Int?
    /// バージョン番号
    let version: Int?
}
