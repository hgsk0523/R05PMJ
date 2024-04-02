import UIKit
import RealmSwift

/// Realmサービスクラス
class RealmService: NSObject {
    
    // MARK: - Property
    /// モデル全体の設定／固定値を保持
    private var modelConfiguration: ModelConfiguration?
    /// Realmオブジェクトの共通管理
    private var baseRealmDataSource: BaseRealmDataSource?
    /// 点検データソース
    private var inspectionRealmDataSource: InspectionRealmDataSource?
    /// 点検項目のデータソース
    private var inspectionItemRealmDataSource: InspectionItemRealmDataSource?
    /// キーチェインのデータソース
    private var keychainDataSource: KeychainDataSource?
    /// 撮影例のデータソース
    private var exampleImageRealmDataSource: ExampleImageDataSource?
    
    public static let shared = RealmService()
    
    /// シングルトン
    private override init() {
        /// モデル全体の設定／固定値を保持
        self.modelConfiguration = ModelConfiguration(modelFileDirectory: FileDirectory.modelFileDirectory)
        /// キーチェインのデータソース
        self.keychainDataSource = KeychainDataSource()
        /// Realmオブジェクトの共通管理
        self.baseRealmDataSource = BaseRealmDataSource(fileURL: modelConfiguration!.modelFileDirectory, keychainDataSource: self.keychainDataSource!)
        /// 点検データソース
        self.inspectionRealmDataSource = InspectionRealmDataSource(baseRealmDataSource!)
        /// 点検項目のデータソース
        self.inspectionItemRealmDataSource = InspectionItemRealmDataSource(baseRealmDataSource!)
        /// 撮影例のデータソース
        self.exampleImageRealmDataSource = ExampleImageDataSource(baseRealmDataSource!)
    }
    
    // MARK: - InspectionRealmDataSourceMethod
    
    /// 点検データ、点検項目をローカルに保存
    /// - Parameters:
    /// - Parameter quary: クエリ
    func saveInspectionData(response: GetInspectionItemApiResponse, parametersInfo: ParametersInfo) throws {
        // 点検項目データソースのnilチェック
        guard let inspectionItemRealmDataSource = self.inspectionItemRealmDataSource else {
            throw ErrorID.ID9999
        }
        do {
            try retry(task: {
                // 点検データ、点検項目を保存
                try self.inspectionRealmDataSource?.saveInspectionData(response: response, parametersInfo: parametersInfo, inspectionItemRealmDataSource: inspectionItemRealmDataSource)
            })
        } catch {
            errorLog(message: "点検データ保存失敗", error: error)
            throw error
        }
    }
    
    /// 点検画面に表示する時の取得処理
    /// - Parameter inspectionID: 点検ID
    /// - Returns: 点検データ
    func getInspectionData(inspectionID: Int) throws -> TBL_T_INSPECTION {
        do {
            // 結果保存用
            var data: TBL_T_INSPECTION?
            try retry(task: {
                data = try self.inspectionRealmDataSource?.getInspectionData(inspectionID: inspectionID)
            })
            // nilチェック
            guard let result = data else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            return result
        } catch {
            errorLog(message: "点検データ取得失敗", error: error)
            throw error
        }
    }
    
    /// 点検状態を更新する
    /// - Parameters:
    ///   - inspectionID: 点検ID
    ///   - status: 状態
    func updateInspectionDataStatus(inspectionID: Int, status: Int) throws {
        do {
            try retry(task: {
               try self.inspectionRealmDataSource?.updateInspectionDataStatus(inspectionID: inspectionID, status: status)
            })
            
        } catch {
            errorLog(message: "点検データ更新失敗", error: error)
            throw error
        }
    }
    
    // MARK: - InspectionItemRealmDataSourceMethod
    
    /// 点検項目を削除する
    /// - Parameter inspectionItemUUID: 点検項目ID
    func deleteInspectionItemData(inspectionItemUUID: UUID) throws {
        do {
            try retry(task: {
                try self.inspectionItemRealmDataSource?.deleteInspectionItemData(inspectionItemUUID: inspectionItemUUID)
            })
        } catch {
            errorLog(message: "点検項目削除失敗", error: error)
            throw error
        }
    }
    
    /// 削除フラグが立っている点検項目データを取得する
    /// - Parameter inspectionID: 点検ID
    func getDeleteInspectionItemDataList(inspectionID: Int) throws -> [TBL_T_INSPECTION_ITEM] {
        do {
            // 結果保存用
            var data: [TBL_T_INSPECTION_ITEM]?
            
            try retry(task: {
                data = try self.inspectionItemRealmDataSource?.getDeleteInspectionItemDataList(inspectionID: inspectionID)
            })
            // nilチェック
            guard let result = data else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            return result
            
        } catch {
            errorLog(message: "削除点検項目取得失敗", error: error)
            throw error
        }
    }
    
    /// 点検IDに紐づく点検項目を取得する処理
    func getInspectionItemDataList(inspectionID: Int) throws -> [TBL_T_INSPECTION_ITEM] {
        do {
            // 結果保存用
            var data: [TBL_T_INSPECTION_ITEM]?
            
            try retry(task: {
                data = try self.inspectionItemRealmDataSource?.getInspectionItemDataList(inspectionID: inspectionID)
            })
            // nilチェック
            guard let result = data else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            return result
        } catch {
            errorLog(message: "点検項目取得失敗", error: error)
            throw error
        }
    }
    
    /// 点検項目１つを取得する処理
    /// - Parameter inspectionID: 点検項目ID
    /// - Returns: 点検項目
    func getInspectionItemData(inspectionItemUUID: UUID) throws -> TBL_T_INSPECTION_ITEM {
        do {
            // 結果保存用
            var data: TBL_T_INSPECTION_ITEM?
            
            try retry(task: {
                data = try self.inspectionItemRealmDataSource?.getInspectionItemData(inspectionItemUUID: inspectionItemUUID)
            })
            // nilチェック
            guard let result = data else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            return result
        } catch {
            errorLog(message: "点検項目取得失敗", error: error)
            throw error
        }
    }
    
    ///  inspectionItemID(Int)から点検項目を取得する
    func getInspectionItemData(inspectionItemID: Int) throws -> TBL_T_INSPECTION_ITEM {
        do {
            // 結果保存用
            var data: TBL_T_INSPECTION_ITEM?
            
            try retry(task: {
                data = try self.inspectionItemRealmDataSource?.getInspectionItemData(inspectionItemID: inspectionItemID)
            })
            // nilチェック
            guard let result = data else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            return result
        } catch {
            errorLog(message: "点検項目取得失敗", error: error)
            throw error
        }
    }
    
    /// NGコメントを保存する
    /// - Parameters:
    ///   - inspectionItemUUID: 点検項目ID
    ///   - ngComment: NGコメント
    func updateNGComment(inspectionItemUUID: UUID, ngComment: String) throws {
        do {
            try retry(task: {
                try self.inspectionItemRealmDataSource?.updateNGComment(inspectionItemUUID: inspectionItemUUID, ngComment: ngComment)
            })
        } catch {
            errorLog(message: "NGコメント保存失敗", error: error)
            throw error
        }
    }
    
    /// 点検結果編集
    /// - Parameters:
    ///   - inspectionID: 点検ID
    ///   - exitInspectionResultView: 点検結果編集View
    func updateInspectionResult(inspectionItemUUID: UUID, exitInspectionResultView: ExitInspectionResultView) throws {
        do {
            try retry(task: {
                try self.inspectionItemRealmDataSource?.updateInspectionResult(inspectionItemUUID: inspectionItemUUID, exitInspectionResult: exitInspectionResultView)
            })
        } catch {
            errorLog(message: "点検項目更新失敗", error: error)
            throw error
        }
    }
    
    /// 画像保存時の更新処理
    /// - Parameters:
    ///   - inspectionItemUUID: 点検項目ID
    ///   - takenAt: 撮影日時
    ///   - localOriginalImagePath: オリジナルローカルパス
    ///   - localTrimingImagePath: トリミングローカルパス
    ///   - s3OriginalImagePath: s3オリジナルパス
    ///   - s3TrimingImagePath: s3トリミングパス
    ///   - progress: 進捗状況
    func updateSaveImageProcess(inspectionItemUUID: UUID,takenAt: String, localOriginalImagePath: String, localTrimingImagePath: String, s3OriginalImagePath: String, s3TrimingImagePath: String, progress: Int) throws {
        do {
            guard let inspectionID = InspectionViewDataSource.shared.getInspectionViewInfo().inspectionId else {
                throw ErrorID.ID9999
            }
            try retry(task: {
                try self.inspectionItemRealmDataSource?.updateSaveImageProcess(inspectionItemUUID: inspectionItemUUID, takenAt: takenAt, localOriginalImagePath: localOriginalImagePath, localTrimingImagePath: localTrimingImagePath, s3OriginalImagePath: s3OriginalImagePath, s3TrimingImagePath: s3TrimingImagePath, progress: progress, inspectionID: inspectionID)
            })
        } catch {
            errorLog(message: "点検項目更新失敗", error: error)
            throw error
        }
    }
    
    /// 画像再送信時の更新処理
    /// - Parameters:
    /// - id: 点検項目ID
    ///  - progress: 進捗
    func updateSaveImageProcessResend(id: UUID, progress: Int) throws {
        do {
            try retry(task: {
                try self.inspectionItemRealmDataSource?.updateSaveImageProcessResend(id: id, progress: progress)
            })
        } catch {
            errorLog(message: "点検項目更新失敗", error: error)
            throw error
        }
    }
    
    /// 点検項目追加
    /// - Parameter inspectionItemName: 新しい点検項目名
    func addInspectionItem(inspectionItemName: String, inspectionID: Int) throws {
        do {
            // 点検項目を生成
            let newInspectionItem = TBL_T_INSPECTION_ITEM()
            // 点検ID
            newInspectionItem.inspection_id = inspectionID
            // 点検項目名
            newInspectionItem.item_name = inspectionItemName
            // 進捗状況
            newInspectionItem.progress = INSPECTION_PROGRESS.WAITING_SHOOTING.rawValue
            // 作成日時
            newInspectionItem.mak_dt = Date()
            // 更新日時
            newInspectionItem.ren_dt = Date()
            try retry(task: {
                try self.inspectionItemRealmDataSource?.addInspectionItemData(tInspectionItem: newInspectionItem)
            })
        } catch {
            errorLog(message: "点検項目追加失敗", error: error)
            throw error
        }
    }
    
    
    /// ローカルに画像解析結果を保存する
    /// - Parameters:
    ///   - analysisResultResponse: 画像解析結果
    func updateAnalysisResultToLocal(analysisResultResponse: GetAnalysisResultApiResponse) throws {
        do {
            try self.inspectionItemRealmDataSource?.updateAnalysisResultToLocal(analysisResultResponse: analysisResultResponse)
        } catch {
            errorLog(message: "画像解析結果更新失敗", error: error)
            throw error
        }
    }
    
    /// 進捗状況更新
    /// - Parameter beginImageAnalysisResponse: 画像解析指示結果
    func updateBeginImageAnalysisResultToLocal(beginImageAnalysisResponse: BeginImageAnalysisApiResponse) throws {
        do {
            try self.inspectionItemRealmDataSource?.updateBeginImageAnalysisResultToLocal(beginImageAnalysisResponse: beginImageAnalysisResponse)
        } catch {
            errorLog(message: "解析進捗更新失敗", error: error)
            throw error
        }
    }
    
    // MARK: ExampleImageDataSource
    
    /// 撮影例画像を保存
    /// - Parameters:
    ///   - photoInfo: 撮影例情報
    func saveExampleImageData(exampleImageData: TBL_M_SAMPLE_PHOTO) throws {
        do {
            try retry(task: {
                // 撮影例画像を保存
                try self.exampleImageRealmDataSource?.saveExampleImageData(photoData: exampleImageData)
            })
        } catch {
            throw error
        }
    }
    
    /// 該当の撮影データを取得
    /// - Parameters:
    ///   - inspectionNameID: 点検名ID
    ///   - inspectionItemNameID: 点検項目名ID
    func getExampleImageData(inspectionNameID: Int, inspectionItemNameID: Int?) throws -> [TBL_M_SAMPLE_PHOTO]? {
        do {
            var data: [TBL_M_SAMPLE_PHOTO]?
            try retry(task: {
                // 撮影例画像を取得
                 data = try self.exampleImageRealmDataSource!.getExampleImageData(inspectionNameID: inspectionNameID, inspectionItemNameID: inspectionItemNameID)
            })
            return data
        } catch {
            throw error
        }
    }
    
    /// 撮影例画像を削除
    func deleteExampleImageData() throws {
        do {
            try retry(task: {
                // 撮影例画像を保存
                try self.exampleImageRealmDataSource?.deleteExampleImageData()
            })
        } catch {
            throw error
        }
    }
}

