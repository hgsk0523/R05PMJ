import Foundation
import APIKit

/// Apiサービスクラス
class ApiService: NSObject {
    
    /// APIのデータソース
    private var apiDataSource: ApiDataSource = ApiDataSource()
    
    /// シングルトン
    private override init() {}
    public static let shared = ApiService()
    
    /// 画像解析指示
    func beginImageAnalysisApi(body: BeginImageAnalysistApiRequestBody,
                               successHandler: @escaping (BeginImageAnalysisApiResponse) -> Void,
                               failureHandler: @escaping (ErrorCause?) -> Void) {
        
        apiDataSource.beginImageAnalysisApi(body: body) { result in
            switch result {
            case .success(let getBeginImageAnalysisResponse):
                // 取得したデータ
                let response = getBeginImageAnalysisResponse as? BeginImageAnalysisApiResponse
                // 後続処理
                successHandler(response!)
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    /// 検査完了API
    func inspectionResultApi(body: InspectionResultApiRequestBody,
                             successHandler: @escaping (InspectionResultApiResponse) -> Void,
                             failureHandler: @escaping (ErrorCause?) -> Void) {
        
        apiDataSource.inspectionResultApi(body: body) { result in
            switch result {
            case .success(let getInspectionResultApiResponse):
                // 取得したデータ
                let response = getInspectionResultApiResponse as? InspectionResultApiResponse
                // 後続処理
                successHandler(response!)
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    /// 画像解析結果取得
    func getAnalysisResultApi(query: GetAnalysisResultApiRequestQuery,
                              successHandler: @escaping (GetAnalysisResultApiResponse) -> Void,
                              failureHandler: @escaping (ErrorCause?) -> Void) {
        self.apiDataSource.getAnalysisResultApi(query: query) { result in
            switch result {
            case .success(let getAnalysisResultAPIResponse):
                // 取得したデータ
                let response  = getAnalysisResultAPIResponse as? GetAnalysisResultApiResponse
                // 後続処理
                successHandler(response!)
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    /// S3へ画像を保存
    /// - Parameters:
    ///   - path: 画像保存パス
    ///   - image: 保存画像
    func saveS3ImageApi(path: String, image: UIImage,
                        successHandler: @escaping () -> Void,
                        failureHandler: @escaping (ErrorCause?) -> Void) {
        self.apiDataSource.saveS3ImageApi(path: path, image: image) { result in
            switch result {
            case .success(_):
                // 後続処理
                successHandler()
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    ///  点検データ、点検項目をサーバーから取得
    func getInspectionItemApiRequest(body: GetInspectionItemApiRequestBody,
                                     successHandler: @escaping (GetInspectionItemApiResponse) -> Void,
                                     failureHandler: @escaping (ErrorCause?) -> Void) {
        
        apiDataSource.getInspectionItemApi(body: body) { result in
            switch result {
            case .success(let getInspectionItemApiResponse):
                // 取得したデータ
                let response = getInspectionItemApiResponse as? GetInspectionItemApiResponse
                // 後続処理
                successHandler(response!)
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    /// Jsonファイル取得
    func getS3JsonFileData(s3Path: String,
                           successHandler: @escaping (Data) -> Void,
                           failureHandler: @escaping (ErrorCause?) -> Void) {

        self.apiDataSource.getS3ObjectApi(bucketName: S3_BUCKET_NAME, path: s3Path) { result in
            switch(result) {
            case .success(let objectData):
                if let response = objectData as? Data {
                    successHandler(response)
                    
                } else {
                    failureHandler(ErrorCause.ApiError)
                }
                
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
    
    /// 画像取得
    func getS3ImageData(bucketName: String,
                        s3Path: String,
                        successHandler: @escaping (UIImage?) -> Void,
                        failureHandler: @escaping (ErrorCause?) -> Void) {
        self.apiDataSource.getS3ObjectApi(bucketName: bucketName, path: s3Path) { result in
            switch(result) {
            case .success(let objectData):
                if let response = objectData as? Data {
                    successHandler(UIImage(data: response))
                    
                } else {
                    failureHandler(ErrorCause.ApiError)
                }
                
            case .failure(let error):
                failureHandler(error)
            }
        }
    }
}

