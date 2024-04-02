import Foundation
import APIKit

/// 画像解析結果取得API
struct GetAnalysisResultApiRequest: BaseApiRequst {
    
    typealias Response = GetAnalysisResultApiResponse
    
    let path = "analysis-result"
    
    let method : HTTPMethod = .get
    
    var queryParameters: [String : Any]?
    
    let headerFields: [String : String] = X_API_KEY
    
    init(query: GetAnalysisResultApiRequestQuery) {
        self.queryParameters = query.toDictionary()
    }
}
/// リクエスト(Query)
struct GetAnalysisResultApiRequestQuery: BaseApiRequestQuery {
    /// 最後にデータを取得した日時
    let lastUpdatedAt: String
    /// 点検ID
    let inspectionId: Int
}

/// レスポンス
struct GetAnalysisResultApiResponse: Decodable {
    /// 結果コード
    let resultCode: Int
    let analysisResultItems: [AnalysisResultItems]?
}

struct AnalysisResultItems: Decodable {
    /// 点検ID
    let inspectionId: Int?
    /// 点検項目ID
    let inspectionItemId: Int?
    /// 判定結果
    let result: String?
    /// 品番
    let model: String?
    /// 製造番号
    let serialNumber: String?
    /// 進捗状況
    let progress: Int?
    /// 撮影画像パス(オリジナル)
    let s3ImagePath: String?
    /// バージョン番号
    let version: Int?
}
