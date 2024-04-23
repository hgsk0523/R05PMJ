import Foundation
import UIKit
import RealmSwift

// MARK: - 点検画面ViewModel

/// 点検画面ViewModelのプロトコル
protocol InspectionViewModelProtocol {
    //MARK: -  ゲッター
    /// 設定値情報の取得
    func getSettingValues() -> SettingValues
    /// 点検Infoを取得
    func getInspectionViewInfo() -> InspectionViewInfo
    /// 画面に点検情報を取得
    func getInspectionInfo() -> InspectionView
    /// 点検項目を取得する処理
    func getInspectionItemDataList() throws -> [TBL_T_INSPECTION_ITEM]
    /// 点検項目の設定
    func getInspectionItem(inspectionItemDataList: [TBL_T_INSPECTION_ITEM]) -> [UIView]
    /// ポップアップ取得
    func getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER, inspectionItemUUID: UUID?, uiImage: UIImage?) throws -> UIView
    /// 削除する点検項目データリストを取得する
    func getDeleteInspectionItemDataList() throws -> [DeleteList]
    /// 点検結果項目リストの取得
    func getInspectionResultItems(inspectionItemDataList: [TBL_T_INSPECTION_ITEM]) -> [InspectionResultItems]
    
    //MARK: -  セッター
    /// 点検項目ID(UUID)をセットする
    func setInspectionItemUUID(inspectionItemUUID: UUID)
    /// 点検項目ID(Int)をセットする
    func setInspectionItemID(inspectionItemID: Int?)
    /// 点検項目名をセットする
    func setInspectionItemName(inspectionItemName: String)
    /// 解析種別をセットする
    func setInspectionItemAnalysisType(analysisType: String?)
    /// 点検項目名IDをセットする
    func setInspectionItemNameID(inspectionItemNameID: Int?)
    
    //MARK: -  その他
    /// ローカルに点検データ、点検項目を追加する
    func saveInspectionData(parameterInfo: ParametersInfo, inspectionItemApiResponse: GetInspectionItemApiResponse) throws
    /// 点検Info初期化処理
    func initInfo(parameterInfo: ParametersInfo, inspectionItemApiResponse: GetInspectionItemApiResponse) throws
    /// 点検項目を削除する
    func deleteInspectionItemData(inspectionItemUUID: UUID) throws
    /// 点検項目追加
    func addInspectionItem(inspectionItemName: String) throws
    /// 点検結果編集
    func exitInspectionResult(exitInspectionResultView: ExitInspectionResultView) throws
    /// NGコメントを保存する
    func saveNGComment(ngComment: String) throws
    /// 画像解析
    func imageAnalysis(inspectionItemID: Int, successHandler: @escaping () -> Void, failureHandler: @escaping (Error?) -> Void) throws
    /// 再送
    func resendImage(inspectionItemUUID: UUID, success: @escaping() -> Void, failure: @escaping(Error?) -> Void)
    /// 画像がローカル上に保存されているか確認する
    func checkSsavedLocally(inspectionItemUUID: UUID) throws
    /// 検査完了API
    func inspectionResultApiRequest(evidenceID: Int, status: INSPECTION_STATUS, inspectionResultItems: [InspectionResultItems], deleteList: [DeleteList], successHandler: @escaping() -> Void, failureHandler: @escaping(Error?) -> Void)
    /// サーバーから画像解析結果を取得するApi
    func getAnalysisResultApi(lastUpdatedAt: String, successHandler: @escaping() -> Void, failureHandler: @escaping(Error?) -> Void) throws
    /// ローカル画像サイズ確認
    func checkLocalImageSize(inspectionItemId: Int) throws -> Bool
}

/// 点検画面ViewModel
final class InspectionViewModel {
    
    /// 顧客名最大表示文字数
    private let MAX_NAME_COUNT: Int = 10

    /// 画像解析結果レスポンス
    var analysisResultResponse: GetAnalysisResultApiResponse?
    
    //MARK: - Method
    /// ローカルに画像が保存されているかの確認メソッド
    private func checkSsavedImage(path: String?) throws {
        do {
            if let fileName = path {
                let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(fileName)
                guard let _ = try? Data(contentsOf: url) else {
                    errorLog(message: "ローカル画像取得失敗", error: ErrorCause.noObject)
                    // 画像なし
                    throw ErrorID.ID9999
                }
            } else {
                errorLog(message: "ローカル画像取得失敗", error: ErrorCause.noObject)
                // 画像なし
                throw ErrorID.ID9999
            }
        } catch {
            throw error
        }
    }
    
    /// 画像解析指示
    /// - Parameters:
    ///   - inspectionId: 点検ID
    ///   - inspectionItemId: 点検項目ID
    ///   - bucketName: バケット名
    ///   - originalPath: オリジナル画像パス
    ///   - trimmingPath: トリミング画像パス
    ///   - handler: ハンドラー
    ///   - horizontalFlag: 向きフラグ
    private func beginImageAnalysisApiRequest(inspectionId: Int, inspectionItemId: Int, bucketName: String, originalPath: String, trimmingPath: String, successHandler: @escaping (_ response: BeginImageAnalysisApiResponse) -> Void, failureHandler: @escaping (_ error: Error?) -> Void) {
        // ボディの登録
        let body = BeginImageAnalysistApiRequestBody(inspectionId: inspectionId,
                                                     inspectionItemId: inspectionItemId,
                                                     bucketName: bucketName,
                                                     originalImagePath: originalPath,
                                                     trimmingImagePath: trimmingPath)
        // 画像解析指示
        ApiService.shared.beginImageAnalysisApi(body: body) { response in
            // 後続処理
            successHandler(response)
        } failureHandler: { error in
            failureHandler(error)
        }
    }
}

// MARK: - InspectionViewModelProtocol

extension InspectionViewModel : InspectionViewModelProtocol {
    //MARK: - ゲッター
    /// 設定値情報の取得
    /// - Returns: 設定値情報
    func getSettingValues() -> SettingValues {
        return SettingDatasource.shared.getSettingValuesInfo()
    }
    
    /// 点検Infoを取得
    func getInspectionViewInfo() -> InspectionViewInfo {
        return InspectionViewDataSource.shared.getInspectionViewInfo()
    }
    
    /// 画面に点検情報を取得
    /// - Parameter inspectionData: 点検データ
    /// - Returns: 点検データコンテンツ
    func getInspectionInfo() -> InspectionView {
        // 点検情報取得
        let data = getInspectionViewInfo()
        // パラメータ情報取得
        let parametersInfo = CustomURLSchemeDatasource.shared.getCustomURLSchemeParameters()
        // 点検データの情報をローカルから取得し、設定
        let inspectionContent = InspectionView.initFromNib()
        inspectionContent.view.backgroundColor = .systemGray5
        // 点検名
        inspectionContent.inspectionName.text = parametersInfo.MEISHO
        // 点検日
        inspectionContent.date.text = fixDateFormat(date: data.inspectionDate)
        // WSCD
        inspectionContent.wscd.text = data.wscd
        // 品番
        inspectionContent.model.text = data.model
        // 顧客名
        var name = data.customerName ?? ""
        if name.count > MAX_NAME_COUNT {
            name = String(name.prefix(MAX_NAME_COUNT)) + "…"
        }
        inspectionContent.name.text = name
        
        return inspectionContent
    }
    
    /// 点検項目を取得する処理
    /// - Returns: 点検項目データ
    func getInspectionItemDataList() throws -> [TBL_T_INSPECTION_ITEM] {
        do {
            return try RealmService.shared.getInspectionItemDataList(inspectionID: self.getInspectionViewInfo().inspectionId)
        } catch {
            throw error
        }
    }
    
    /// 点検項目の設定
    func getInspectionItem(inspectionItemDataList: [TBL_T_INSPECTION_ITEM]) -> [UIView] {
        // 点検情報
        let inspectioninfo = getInspectionViewInfo()
        // 表示する点検項目リスト
        var inspectionItemViewList: [UIView] = []
        // 点検項目のタイプごとにViewを作成する
        inspectionItemDataList.forEach { inspectionItemData in
            switch inspectionItemData.analysis_type {
                // OCR
            case INSPECTION_ITEM_TYPE.OCR.rawValue:
                // OCR点検項目設定
                let ocrView = OCRInspectionItemView()
                // 初期化
                ocrView.initialize(inspectionItemData: inspectionItemData, inspectionData: inspectioninfo)
                // 点検項目リストに追加
                inspectionItemViewList.append(ocrView)
                
                // AI
            case INSPECTION_ITEM_TYPE.AI.rawValue:
                // AI点検項目設定
                let aiView = AIInspectionItemView()
                // 初期化
                aiView.initialize(inspectionItemData: inspectionItemData, inspectionData: inspectioninfo)
                // 点検項目リストに追加
                inspectionItemViewList.append(aiView)
                
                // その他
            case INSPECTION_ITEM_TYPE.OTHER.rawValue:
                // その他の点検項目設定
                let otherView = OtherInspectionItemView()
                // 初期化
                otherView.initialize(inspectionItemData: inspectionItemData, inspectionData: inspectioninfo)
                // 点検項目リストに追加
                inspectionItemViewList.append(otherView)
                
                // 新規追加
            default:
                // 新規追加した点検項目設定
                let newView = NewInspectionItemView()
                // 初期化
                newView.initialize(inspectionItemData: inspectionItemData, inspectionData: inspectioninfo)
                // 点検項目リストに追加
                inspectionItemViewList.append(newView)
                
            }
        }
        return inspectionItemViewList
    }
    
    /// ポップアップ取得
    func getPopUpView(popUpNo: INSPECTION_ITEM_POP_UP_NUMBER, inspectionItemUUID: UUID? = nil, uiImage: UIImage?) throws -> UIView {
        do{
            switch(popUpNo, inspectionItemUUID, uiImage) {
                /// 新規追加
            case (.ADD_NEW_RECORD, _, _):
                return InspectionItemService.shared.createAddInspectionItemView()
                /// コメント
            case (.SHOW_COMMENT, _, _):
                return InspectionItemService.shared.createDisplayCommentView()
                /// 点検結果編集
            case (.EXIT_INSPECTION_RESULT, let itemId, _) where itemId != nil:
                // 点検項目情報の取得
                let inspectionItemData = try RealmService.shared.getInspectionItemData(inspectionItemUUID: itemId!)
                return InspectionItemService.shared.createExitInspectionResultView(inspectionItemData: inspectionItemData)
                /// NGコメント登録
            case (.REGIST_NG_COMMENT, let itemId, _) where itemId != nil:
                // 点検項目情報の取得
                let inspectionItemData = try RealmService.shared.getInspectionItemData(inspectionItemUUID: itemId!)
                return InspectionItemService.shared.createRegisterNGCommentView(inspectionItemData: inspectionItemData)
                /// WSエビデンス
            case (.WS_EVIDENCE, _, _):
                let worksheetEvidenceItem = try SettingDatasource.shared.getWSEvidenceInfo(inspectionNameId: self.getInspectionViewInfo().inspectionNameID)
                return InspectionItemService.shared.createWSEvidenceView(worksheetEvidenceItem: worksheetEvidenceItem)
                ///画像拡大
            case (.ENLARGE_IMAGE, _, let image) where image != nil:
                return InspectionItemService.shared.createEnlargeImageView(image: image!)
            default:
                // エラーを返却
                errorLog(message: "表示画面情報取得失敗", error: nil)
                throw ErrorID.ID9999
                
            }
        }catch {
            throw error
        }
    }
    
    //MARK: - セッター
    /// 点検項目UUIDをセットする
    /// - Parameter inspectionItemUUID: 点検ID
    func setInspectionItemUUID(inspectionItemUUID: UUID) {
        InspectionViewDataSource.shared.setInspectionItemUUID(inspectionItemUUID: inspectionItemUUID)
    }
    
    /// 点検項目ID(Int)をセットする
    func setInspectionItemID(inspectionItemID: Int?) {
        InspectionViewDataSource.shared.setInspectionItemID(inspectionItemID: inspectionItemID)
    }
    
    /// 点検項目名をセットする
    /// - Parameter inspectionItemName: 点検項目名
    func setInspectionItemName(inspectionItemName: String) {
        InspectionViewDataSource.shared.setInspectionItemName(inspectionItemName: inspectionItemName)
    }
    
    /// 解析種別をセットする
    /// - Parameter analysisType: 解析種別
    func setInspectionItemAnalysisType(analysisType: String?) {
        PreviewDataSource.shared.setAnalysisType(type: analysisType)
    }
    
    /// 点検項目名IDをセットする
    /// - Parameter inspectionItemNameID: 点検項目名ID
    func setInspectionItemNameID(inspectionItemNameID: Int?) {
        PreviewDataSource.shared.setInspectionItemNameID(inspectionItemNameID: inspectionItemNameID)
    }
    
    //MARK: - その他
    /// ローカルに点検データ、点検項目を保存
    func saveInspectionData(parameterInfo: ParametersInfo, inspectionItemApiResponse: GetInspectionItemApiResponse) throws {
        do {
            // Realmに点検データ、点検項目を保存
            try RealmService.shared.saveInspectionData(response: inspectionItemApiResponse, parametersInfo: parameterInfo)
        } catch {
            throw error
        }
    }
    
    /// 点検Info初期化処理
    func initInfo(parameterInfo: ParametersInfo, inspectionItemApiResponse: GetInspectionItemApiResponse) throws {
        do {
            guard let inspectionData = inspectionItemApiResponse.schedule else {
                throw ErrorID.ID9999
            }
            
            let data = try RealmService.shared.getInspectionData(inspectionID: inspectionData.id)
            
            // 点検データinfoに情報を設定
            InspectionViewDataSource.shared.setInspectionViewInfo(inspectionID: data.inspection_id,
                                                                  inspectionName: parameterInfo.MEISHO,
                                                                  inspectionNameID: data.inspection_name_id,
                                                                  inspectionDate: data.inspection_date,
                                                                  wscd: data.worksheet_code,
                                                                  model: data.model,
                                                                  customerName: data.client_name,
                                                                  comment: try SettingDatasource.shared.getSettings(inspectionNameId: data.inspection_name_id).comment,
                                                                  status: data.status,
                                                                  companyCD: data.company_code,
                                                                  baseCD: data.base_code)
        } catch {
            throw ErrorID.ID9999
        }
    }
    
    /// 点検項目を削除する
    /// - Parameter inspectionItemUUID: 点検項目ID
    func deleteInspectionItemData(inspectionItemUUID: UUID) throws {
        do {
            // 点検項目IDに紐づく点検項目を削除
            try RealmService.shared.deleteInspectionItemData(inspectionItemUUID: inspectionItemUUID)
        } catch {
            throw error
        }
    }
    
    /// 点検項目追加
    /// - Parameter inspectionItemName: 新しい点検項目名
    func addInspectionItem(inspectionItemName: String) throws {
        do {
            try RealmService.shared.addInspectionItem(inspectionItemName: inspectionItemName, inspectionID: self.getInspectionViewInfo().inspectionId)
        } catch {
            throw error
        }
    }
    
    /// 点検結果編集
    /// - Parameters:
    ///   - exitInspectionResultView: 点検結果編集View
    func exitInspectionResult(exitInspectionResultView: ExitInspectionResultView) throws {
        do {
            try RealmService.shared.updateInspectionResult(inspectionItemUUID: self.getInspectionViewInfo().inspectionItemUUID, exitInspectionResultView: exitInspectionResultView)
        } catch {
            throw error
        }
    }
    
    /// NGコメントを保存する
    /// - Parameters:
    ///   - ngComment: NGコメント
    func saveNGComment(ngComment: String) throws {
        do {
            try RealmService.shared.updateNGComment(inspectionItemUUID: self.getInspectionViewInfo().inspectionItemUUID, ngComment: ngComment)
        } catch {
            throw error
        }
    }
    
    /// 画像解析
    func imageAnalysis(inspectionItemID: Int, successHandler: @escaping () -> Void, failureHandler: @escaping (Error?) -> Void) throws {
        do {
            // 点検ID取得
            guard let inspectionId = self.getInspectionViewInfo().inspectionId else { throw ErrorID.ID9999 }
            // 点検項目情報取得
            let item = try RealmService.shared.getInspectionItemData(inspectionItemID: inspectionItemID)
            // S3保存先バケット名の取得
            let bucketName = SettingDatasource.shared.getSettingValuesInfo().bucketName
            // 画像解析リクエストを送る
            self.beginImageAnalysisApiRequest(inspectionId: inspectionId, inspectionItemId: inspectionItemID, bucketName: bucketName, originalPath: item.s3_original_image_path ?? "", trimmingPath: item.s3_triming_image_path ?? "", successHandler: { response in
                do {
                    // ローカルのデータを更新
                    try RealmService.shared.updateBeginImageAnalysisResultToLocal(beginImageAnalysisResponse: response)
                    successHandler()
                } catch {
                    failureHandler(error)
                }
            }, failureHandler: { error in
                failureHandler(error)
            })
        } catch {
            throw error
        }
    }
    
    /// 画像がローカル上に保存されているか確認する
    func checkSsavedLocally(inspectionItemUUID: UUID) throws {
        do {
            // 該当の点検項目データを取得
            let inspectionItemData = try RealmService.shared.getInspectionItemData(inspectionItemUUID: inspectionItemUUID)
            // オリジナルローカル画像の確認
            try self.checkSsavedImage(path: inspectionItemData.local_original_image_path)
            // トリミングローカル画像の確認
            try self.checkSsavedImage(path: inspectionItemData.local_triming_image_path)
        } catch {
            throw error
        }
    }
    
    /// 再送
    func resendImage(inspectionItemUUID: UUID, success: @escaping() -> Void, failure: @escaping(Error?) -> Void) {
        do {
            // 画像保存用
            var originalImage: UIImage?
            var trimmingImage: UIImage?
            // 対象の点検項目データを取得する
            let inspectionItemData = try RealmService.shared.getInspectionItemData(inspectionItemUUID: inspectionItemUUID)
            
            // ローカル上からオリジナル画像を取得する
            if let fileName = inspectionItemData.local_original_image_path {
                if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(fileName) {
                    if let data = try? Data(contentsOf: url) {
                        originalImage = UIImage(data: data)
                    }
                }
            }
            // ローカル上からトリミング画像を取得する
            if let fileName = inspectionItemData.local_triming_image_path {
                if let url = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(fileName) {
                    if let data = try? Data(contentsOf: url) {
                        trimmingImage = UIImage(data: data)
                    }
                }
            }
            
            // 画像のnil確認
            guard let originalImage = originalImage , let trimmingImage = trimmingImage else {
                throw ErrorID.ID0034
            }
            
            // s3pathのnilチェック
            guard let s3_original_image_path = inspectionItemData.s3_original_image_path, let s3_triming_image_path = inspectionItemData.s3_triming_image_path else {
                throw ErrorID.ID9999
            }
            
            // 更新する進捗の登録
            let progress = (inspectionItemData.analysis_type == INSPECTION_ITEM_TYPE.AI.rawValue || inspectionItemData.analysis_type == INSPECTION_ITEM_TYPE.OCR.rawValue) ? INSPECTION_PROGRESS.IMAGE_SAVED_REMOTE.rawValue : INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue
            
            // S3にオリジナル画像を保存
            ApiService.shared.saveS3ImageApi(path: s3_original_image_path, image: originalImage) {
                // S3にトリミング画像を保存
                ApiService.shared.saveS3ImageApi(path: s3_triming_image_path, image: trimmingImage, successHandler: {
                    do {
                        // ローカルDBに点検項目情報を更新
                        try RealmService.shared.updateSaveImageProcessResend(id: inspectionItemUUID, progress: progress)
                        // 点検infoの状態を更新
                        if InspectionViewDataSource.shared.getInspectionViewInfo().status == INSPECTION_STATUS.WAITING.rawValue {
                            // 撮影待ちになっていたらinfoの状態を点検中にする
                            InspectionViewDataSource.shared.setStatus(status: INSPECTION_STATUS.UNDER_INSPECTION.rawValue)
                            // RealmDBの状態を更新
                            try RealmService.shared.updateInspectionDataStatus(inspectionID: InspectionViewDataSource.shared.getInspectionViewInfo().inspectionId, status: INSPECTION_STATUS.UNDER_INSPECTION.rawValue)
                        }                        
                        success()
                    } catch {
                        failure(error)
                    }
                }, failureHandler: { error in
                    failure(error)
                })
            } failureHandler: { error in
                failure(error)
            }
        } catch {
            failure(error)
        }
    }
    
    /// 点検結果項目リストの取得
    /// - Parameter inspectionItemDataList: 点検項目データリスト
    /// - Returns: 点検結果項目リスト
    func getInspectionResultItems(inspectionItemDataList: [TBL_T_INSPECTION_ITEM]) -> [InspectionResultItems] {
        // 検査完了ボディの点検項目リスト
        var inspectionResultItems: [InspectionResultItems] = []
        // S3保存先バケット名の取得
        let bucketName = SettingDatasource.shared.getSettingValuesInfo().bucketName
        // 点検項目ボディを生成
        inspectionItemDataList.forEach { data in
            // progressが5でない時、リストに含めない
            if data.progress != INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue { return }
            // 画像パスの作成
            let imagePath = data.s3_original_image_path == nil ? nil : ("\(bucketName)/\(data.s3_original_image_path!)")
            let inspectionResultItem: InspectionResultItems = InspectionResultItems(inspectionItemId: data.inspection_item_id,
                                                                                    inspectionItemName: data.item_name!,
                                                                                    takenDt: data.taken_dt?.ISO8601Format(),
                                                                                    editedModel: data.edited_model,
                                                                                    editedSerialNumber: data.edited_serial_number,
                                                                                    ngComment: data.ng_comment,
                                                                                    s3ImagePath: imagePath)
            inspectionResultItems.append(inspectionResultItem)
        }
        return inspectionResultItems
    }
    
    /// 削除する点検項目データリストを取得する
    /// - Returns: 点検項目データリスト
    func getDeleteInspectionItemDataList() throws -> [DeleteList] {
        do {
            // 検査完了ボディの削除リスト
            var deleteList: [DeleteList] = []
            // 削除するデータを取得
            let inspectionItemDeleteDataList = try RealmService.shared.getDeleteInspectionItemDataList(inspectionID: self.getInspectionViewInfo().inspectionId)
            // 削除データIDリストを生成
            try inspectionItemDeleteDataList.forEach { data in
                // 点検項目IDのnilチェック
                guard let inspection_item_id = data.inspection_item_id else {
                    // 入らない想定
                    throw ErrorID.ID9999
                }
                let deleteData: DeleteList = DeleteList(inspectionItemId: inspection_item_id)
                deleteList.append(deleteData)
            }
            
            return deleteList
        } catch {
            throw error
        }
    }

    /// 検査完了API
    func inspectionResultApiRequest(evidenceID: Int, status: INSPECTION_STATUS, inspectionResultItems: [InspectionResultItems], deleteList: [DeleteList], successHandler: @escaping() -> Void, failureHandler: @escaping(Error?) -> Void) {
        // ボディ作成
        let body = InspectionResultApiRequestBody(inspectionId: self.getInspectionViewInfo().inspectionId,
                                                  status: status.rawValue,
                                                  evidenceId: evidenceID,
                                                  inspectionResultItems: inspectionResultItems,
                                                  deleteList: deleteList)
        // 検査完了API
        ApiService.shared.inspectionResultApi(body: body) { _ in
            successHandler()
        } failureHandler: { error in
            failureHandler(error)
        }
    }
    
    /// サーバーから画像解析結果を取得する
    /// - Parameters:
    ///   - lastUpdatedAt: 最終更新日時
    func getAnalysisResultApi(lastUpdatedAt: String, successHandler: @escaping() -> Void, failureHandler: @escaping(Error?) -> Void) throws {
        do {
            // 点検ID取得
            guard let inspectionId = self.getInspectionViewInfo().inspectionId else { throw ErrorID.ID9999 }
            // クエリの登録
            let query = GetAnalysisResultApiRequestQuery(lastUpdatedAt: lastUpdatedAt, inspectionId: inspectionId)
            // 画像解析結果取得API
            ApiService.shared.getAnalysisResultApi(query: query) { response in
                do {
                    try RealmService.shared.updateAnalysisResultToLocal(analysisResultResponse: response)
                    // 後続処理
                    successHandler()
                } catch {
                    failureHandler(error)
                }
            } failureHandler: { error in
                failureHandler(error)
            }
        } catch {
            throw error
        }
    }
    
    /// ローカル画像サイズ確認
    func checkLocalImageSize(inspectionItemId: Int) throws -> Bool {
        
        var uiImage: UIImage? = nil
        
        do {
            // 点検スケジュールの取得
            let schedule = try RealmService.shared.getInspectionData()
            // 点検項目の取得
            let item = try RealmService.shared.getInspectionItemData(inspectionItemID: inspectionItemId)
            
            // ai解析種別か確認
            if schedule.inspection_name_id != 1 {
                return true
            }
            if item.analysis_type != "ai" {
                // Qプロのai解析処理のみ後続処理実施
                return true
            }
            
            // 画像をローカルから取得
            let url = try FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent(item.local_original_image_path ?? "")

            print(url)
            if let data = try? Data(contentsOf: url) {
                uiImage = UIImage(data: data)
                guard let width = uiImage?.size.width else {
                    return true
                }
                
                guard let height = uiImage?.size.height else {
                    return true
                }
                
                if width == RESOLUTION_1280 && height == RESOLUTION_720 {
                    return false
                } else {
                    return true
                }
            }
            return true
        } catch {
            return true
        }
    }
}
