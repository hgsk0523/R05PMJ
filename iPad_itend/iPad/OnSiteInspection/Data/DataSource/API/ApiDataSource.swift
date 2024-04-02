import Foundation
import APIKit

enum ApiDataSourceResult {
    case success(Any)
    case failure(ErrorCause)
}

/// APIリクエスト共通のデータソースクラス用プロトコル
protocol ApiDataSourceProtocol {
    
    /// 点検情報取得API
    func getInspectionItemApi(body: GetInspectionItemApiRequestBody, handler: @escaping (ApiDataSourceResult) -> Void)
    
    /// 検査完了API
    func inspectionResultApi(body: InspectionResultApiRequestBody, handler: @escaping (ApiDataSourceResult) -> Void)
    
    /// 画像解析指示API
    func beginImageAnalysisApi(body: BeginImageAnalysistApiRequestBody, handler: @escaping (ApiDataSourceResult) -> Void)
    
    /// 画像解析結果取得API
    func getAnalysisResultApi(query: GetAnalysisResultApiRequestQuery, handler: @escaping (ApiDataSourceResult) -> Void)
    
    /// S3オブジェクト取得API
    func getS3ObjectApi(bucketName: String, path: String, handler: @escaping (ApiDataSourceResult) -> Void)
    
    /// S3Image保存
    func saveS3ImageApi(path: String, image: UIImage, handler: @escaping (ApiDataSourceResult) -> Void)
}

/// APIリクエスト共通のデータソースクラス
class ApiDataSource: ApiDataSourceProtocol {
    
    // MARK: - Property
    
    private let session: Session
    private let config = URLSessionConfiguration.default
    /// タイムアウト時間
    private let TIMEOUT: Double = 32
    
    // MARK: - Initializer
    
    init() {
        self.session = Session.shared
        // Request Timeout Setting
        self.config.timeoutIntervalForRequest = TIMEOUT
        // プロトコルをTLSv1.2を指定
        self.config.tlsMinimumSupportedProtocol = .tlsProtocol12
    }
    
    // MARK: - Method
    
    /// 点検情報取得API
    func getInspectionItemApi(body: GetInspectionItemApiRequestBody,
                              handler: @escaping (ApiDataSourceResult) -> Void) {
        log.info("点検情報取得API実施")
        self.recursiveSend(GetInspectionItemApiRequest(body: body),
                           successHandler: { handler(.success($0)) },
                           failureHandler: { handler(.failure($0)) })
    }
    
    /// 検査完了API
    func inspectionResultApi(body: InspectionResultApiRequestBody,
                             handler: @escaping (ApiDataSourceResult) -> Void) {
        log.info("検査完了API実施")
        self.recursiveSend(InspectionResultApiRequest(body: body),
                           successHandler: { handler(.success($0)) },
                           failureHandler: { handler(.failure($0)) })
    }
    
    /// 画像解析指示API
    func beginImageAnalysisApi(body: BeginImageAnalysistApiRequestBody,
                               handler: @escaping (ApiDataSourceResult) -> Void) {
        log.info("画像解析指示API実施")
        self.recursiveSend(BeginImageAnalysisApiRequest(body: body),
                           successHandler: { handler(.success($0)) },
                           failureHandler: { handler(.failure($0)) })
    }
    
    /// 画像解析結果取得API
    func getAnalysisResultApi(query: GetAnalysisResultApiRequestQuery,
                              handler: @escaping (ApiDataSourceResult) -> Void) {
        log.info("画像解析結果取得API実施")
        self.recursiveSend(GetAnalysisResultApiRequest(query: query),
                           successHandler: { handler(.success($0)) },
                           failureHandler: { handler(.failure($0)) })
    }
    
    /// S3オブジェクト取得
    func getS3ObjectApi(bucketName: String, path: String, handler: @escaping (ApiDataSourceResult) -> Void) {
        log.info("S3オブジェクト取得API実施")
        
        // 変換対象外とする文字列（英数字と-._~）
        let allowedCharacters = NSCharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        let s3Path = path.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        let url = URL(string: "\(BASE_URL)\(bucketName)/\(s3Path ?? "")")!
        
        var request = URLRequest(url:url)
        request.httpMethod = "GET"
        request.allHTTPHeaderFields = X_API_KEY
        
        // 画像取得処理
        let urlSession = URLSession(configuration: config)
        urlSession.dataTask(with: request) { data, response, error in
            // リクエストに失敗
            if let errorContent = error {
                errorLog(message: "APIリクエスト失敗", error: error)
                let nsError = errorContent as NSError
                if nsError.code == -1009 {
                    // 接続エラー
                    handler(.failure(.ConnectionError))
                } else {
                    // 接続エラー以外
                    handler(.failure(.ApiError))
                }
                return
            }

            // レスポンスが受信できていなければ失敗
            guard let data = data, let response = response as? HTTPURLResponse else {
                errorLog(message: "API失敗", error: ErrorCause.noResponse)
                // エラーを返却
                handler(.failure(.ApiError))
                return
            }
            // リクエスト成功
            if response.statusCode == 200 {
                handler(.success(data))
            } else {
                errorLog(message: "API失敗", error: ResponseError.unacceptableStatusCode(response.statusCode))
                // エラーを返却
                handler(.failure(.ApiError))
                return
            }
        }.resume()
    }
    
    /// S3Image保存
    func saveS3ImageApi(path: String, image: UIImage, handler: @escaping (ApiDataSourceResult) -> Void) {
        log.info("撮影画像保存API実施")
        
        // 変換対象外とする文字列（英数字と-._~）
        let allowedCharacters = NSCharacterSet.alphanumerics.union(.init(charactersIn: "-._~"))
        // S3保存先バケット名の取得
        let bucketName = SettingDatasource.shared.getSettingValuesInfo().bucketName
        let s3Path = path.addingPercentEncoding(withAllowedCharacters: allowedCharacters)
        let url = URL(string: "\(BASE_URL)\(bucketName)/\(s3Path ?? "")")!
        
        var request = URLRequest(url:url)
        request.httpMethod = "PUT"
        request.allHTTPHeaderFields = X_API_KEY
        request.setValue("image/jpeg", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = TIMEOUT
        
        // 画像取得処理
        let urlSession = URLSession(configuration: config)
        urlSession.uploadTask(with: request, from: image.jpegData(compressionQuality: SAVE_IMAGE_QUALITY)) { data, response, error in
            // リクエストに失敗
            if let errorContent = error {
                errorLog(message: "APIリクエスト失敗", error: error)
                let nsError = errorContent as NSError
                if nsError.code == -1009 {
                    // 接続エラー
                    handler(.failure(.ConnectionError))
                } else {
                    // 接続エラー以外
                    handler(.failure(.ApiError))
                }
                return
            }
            // レスポンスが受信できていなければ失敗
            guard let _ = data, let response = response as? HTTPURLResponse else {
                errorLog(message: "API失敗", error: ErrorCause.noResponse)
                // エラーを返却
                handler(.failure(.ApiError))
                return
            }
            // リクエスト成功
            if response.statusCode == 200 {
                handler(.success(response))
            } else {
                errorLog(message: "API失敗", error: ResponseError.unacceptableStatusCode(response.statusCode))
                // エラーを返却
                handler(.failure(.ApiError))
            }
        }.resume()
    }
    
    // MARK: - Private Method
    /// 再帰呼び出し用のメソッド
    private func recursiveSend<Request: BaseApiRequst>(_ request: Request,
                                                       availableRetryTimes: Int = MAX_RETRY - 1,
                                                       successHandler: @escaping (Request.Response) -> Void,
                                                       failureHandler: @escaping (ErrorCause) -> Void) {
        
        // セッション送信
        session.send(request) { result in
            switch result {
                // 成功
            case .success(let response):
                successHandler(response)
                
            case .failure(let error):
                
                // 失敗
                // 再実行回数上限に達していなければ再実行
                if availableRetryTimes > 0 {
                    self.recursiveSend(request, availableRetryTimes: availableRetryTimes - 1, successHandler: successHandler, failureHandler: failureHandler)
                } else {
                    errorLog(message: "API失敗", error: error)
                    // 再実行回数上限に達していればエラーを返す
                    failureHandler(self.convertError(error))
                }
            }
        }
    }

    /// エラー内容変換
    private func convertError(_ error: SessionTaskError) -> ErrorCause {
        switch error {
        case .responseError:
            return .ApiError
        case .connectionError:
            return .ConnectionError
        default:
            return .Other
        }
    }
}

