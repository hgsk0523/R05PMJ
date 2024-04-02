import UIKit
import APIKit

/// 点検項目リストAPI
struct GetInspectionItemApiRequest: BaseApiRequst {
    
    typealias Response = GetInspectionItemApiResponse
    
    let path = "get-inspection-item"
    
    let method : HTTPMethod = .post
    
    var bodyParameters: BodyParameters? = nil
    
    let headerFields: [String : String] = X_API_KEY
    
    init(body: GetInspectionItemApiRequestBody) {
        self.bodyParameters = EncodableBodyParamaters(body)
    }
}

/// リクエスト(Body)
struct GetInspectionItemApiRequestBody: Encodable {
    /// WSCD
    let worksheetCode: String
    /// 受付確定日
    let receiptConfirmationDate: Int
    /// 点検名
    let inspectionName: String
    /// 点検日
    let inspectionDate: Int
    /// 会社コード
    let companyCode: String
}

/// レスポンス
struct GetInspectionItemApiResponse: Decodable {
    /// 結果コード
    let resultCode: Int
    /// 点検データ
    let schedule: Schedule?
    /// 点検項目データ
    let items: [Items?]?
}

/// 点検情報
struct Schedule: Decodable {
    let id: Int
    let inspectionNameId: Int
    let status: Int
}

/// 点検項目情報
struct Items: Decodable {
    let inspectionItemId: Int
    let inspectionItemNameId: Int?
    let itemName: String
    let takenDt: String?
    let s3ImagePath: String?
    let aiResult: String?
    let model: String?
    let serialNumber: String?
    let editedModel: String?
    let editedSerialNumber: String?
    let ngComment: String?
    let progress: Int
    let version: Int
}

