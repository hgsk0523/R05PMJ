import Foundation
import APIKit

/// 検査完了API
struct InspectionResultApiRequest: BaseApiRequst {
    
    typealias Response = InspectionResultApiResponse
    
    let path = "inspection-result"
    
    let method : HTTPMethod = .post
    
    var bodyParameters: BodyParameters? = nil
    
    let headerFields: [String : String] = X_API_KEY
    
    init(body: InspectionResultApiRequestBody) {
        self.bodyParameters = EncodableBodyParamaters(body)
    }
}

///リクエスト(body)
struct InspectionResultApiRequestBody: Encodable {
    /// 点検ID
    let inspectionId: Int
    /// 状態
    let status: Int
    /// エビデンスID
    let evidenceId: Int
    /// 点検項目リスト
    let inspectionResultItems: [InspectionResultItems]?
    /// 削除リスト
    let deleteList: [DeleteList]?
}

/// 点検項目リスト
struct InspectionResultItems: Codable {
    /// 点検項目ID
    let inspectionItemId: Int?
    /// 点検項目名
    let inspectionItemName: String
    /// 撮影日時
    let takenDt: String?
    /// 編集済品番
    let editedModel: String?
    /// 編集埋製造番号
    let editedSerialNumber: String?
    /// NGコメント
    let ngComment: String?
    /// S3画像パス（オリジナル）
    let s3ImagePath: String?
}

/// 削除リスト
struct DeleteList: Codable {
    /// 点検項目ID
    let inspectionItemId: Int
}

/// レスポンス
struct InspectionResultApiResponse: Decodable {
    /// 結果コード
    let resultCode: Int
}


