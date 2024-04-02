import Foundation
import RealmSwift

/// 点検項目Realmデータ管理クラス
final class InspectionItemRealmDataSource {
    
    // MARK: - Injection
    
    private let realmDataSource: BaseRealmDataSourceProtocol
    
    // MARK: - Initializer
    
    init(_ realmDataSource: BaseRealmDataSourceProtocol) {
        self.realmDataSource = realmDataSource
    }
    
    // MARK: - Method
    
    /// 点検項目データリスト作成
    /// - Parameter response: レスポンス
    /// - Returns: 点検項目データリスト
    func createInspectionItemData(response: GetInspectionItemApiResponse) throws -> [TBL_T_INSPECTION_ITEM] {
        do {
            // 結果保存用
            var result: [TBL_T_INSPECTION_ITEM] = []
            // nilチェック
            guard let inspectionItemData = response.items, let inspectionID = response.schedule?.id, let inspectionNameID = response.schedule?.inspectionNameId else {
                throw ErrorID.ID9999
            }
            // 点検項目の内容をRealmの方に設定
            // 点検項目数分、点検項目を生成し、点検IDを保存する
            try inspectionItemData.forEach { data in
                // nilチェック
                guard let version = data?.version else {
                    throw ErrorID.ID9999
                }
                // 日付変換
                let formatter = ISO8601DateFormatter.init()
                formatter.formatOptions = [.withFullDate,
                                           .withTime,
                                           .withDashSeparatorInDate,
                                           .withColonSeparatorInTime]
                // 点検項目を生成
                let inspectionItem = TBL_T_INSPECTION_ITEM()
                // 点検項目ID
                inspectionItem.inspection_item_id = data?.inspectionItemId
                // 点検ID
                inspectionItem.inspection_id = inspectionID
                // 点検項目名ID
                inspectionItem.item_name_id = data?.inspectionItemNameId
                // 点検項目名
                inspectionItem.item_name = data?.itemName
                // 作成日時
                inspectionItem.mak_dt = Date()
                // 更新日時
                inspectionItem.ren_dt = Date()
                // バージョン
                inspectionItem.version = version
                // 解析種別
                inspectionItem.analysis_type = try SettingDatasource.shared.getInspectionItemType(inspectionNameId: inspectionNameID, inspectionItemNameID: data?.inspectionItemNameId)
                // 撮影日時がnilか判断
                if (data?.takenDt != nil) {
                    // 撮影日時がnilではない場合、連携する
                    // 撮影日時
                    inspectionItem.taken_dt = formatter.date(from: (data?.takenDt)!)
                    // S3画像パス(オリジナル)
                    inspectionItem.s3_original_image_path = data?.s3ImagePath
                    // AI判定結果
                    inspectionItem.ai_result = data?.aiResult
                    // 品番
                    inspectionItem.model = data?.model
                    // 製造番号
                    inspectionItem.serial_number = data?.serialNumber
                    // 編集済品番
                    inspectionItem.edited_model = data?.editedModel
                    // 編集済製造番号
                    inspectionItem.edited_serial_number = data?.editedSerialNumber
                    // 進捗状況
                    inspectionItem.progress = data?.progress != INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue ? INSPECTION_PROGRESS.WAITING_SHOOTING.rawValue :  INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue
                    // NGコメント
                    inspectionItem.ng_comment = data?.ngComment
                } else {
                    // もし撮影日時がnilの場合、連携しない
                    // progressを撮影待ち(0)とする
                    inspectionItem.progress = INSPECTION_PROGRESS.WAITING_SHOOTING.rawValue
                }
                // 点検配列に点検項目を追加
                result.append(inspectionItem)
            }
            return result
        } catch {
            throw error
        }
    }

    /// 新しい点検項目を追加
    /// - Parameter tInspectionItem: 点検項目
    func addInspectionItemData(tInspectionItem: TBL_T_INSPECTION_ITEM) throws {
        do {
            let realm = try realmDataSource.getRealm()
            try realm.write {
                realm.add(tInspectionItem)
            }
        } catch {
            throw error
        }
    }
    
    /// 進捗状況更新
    /// - Parameter beginImageAnalysisResponse: 画像解析指示結果
    func updateBeginImageAnalysisResultToLocal(beginImageAnalysisResponse: BeginImageAnalysisApiResponse) throws {
        do {
            let realm = try realmDataSource.getRealm()
            try realm.write {
                // レスポンスnilチェック
                guard let inspectionId = beginImageAnalysisResponse.inspectionId,
                      let inspectionItemId = beginImageAnalysisResponse.inspectionItemId,
                      let progress = beginImageAnalysisResponse.progress,
                      let version = beginImageAnalysisResponse.version else {
                    // エラーを返却
                    throw ErrorID.ID9999
                }
                // 点検IDが同じ、かつ該当の項目名の点検項目を取得する(必ず1つ)
                guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_id == inspectionId })
                    .where({ $0.inspection_item_id == inspectionItemId }).where({ $0.delete_flg != 1 }).first else {
                    // エラーを返却
                    throw ErrorID.ID9999
                }
                // 進捗状況
                inspectionItemData.progress = progress
                // 更新日時
                inspectionItemData.ren_dt = Date()
                // バージョン
                inspectionItemData.version = version
            }
        } catch {
            throw error
        }
    }
    
    /// 画像解析指示結果更新
    /// - Parameters:
    ///   - analysisResultResponse: 画像解析結果
    func updateAnalysisResultToLocal(analysisResultResponse: GetAnalysisResultApiResponse) throws {
        do {
            // レスポンスの点検項目のnilチェック
            guard let analysisItem = analysisResultResponse.analysisResultItems else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            // レスポンスのitem配列が空配列の時、何もしない
            if (analysisItem.isEmpty) { return }
            let realm = try realmDataSource.getRealm()
            try realm.write {
                try analysisItem.forEach { response in
                    // 点検項目名のnilチェック
                    // レスポンスnilチェック
                    guard let inspectionId = response.inspectionId,
                          let inspectionItemId = response.inspectionItemId,
                          let progress = response.progress,
                          let version = response.version else {
                        // エラーを返却
                        throw ErrorID.ID9999
                    }
                    
                    // 点検IDが同じ、かつ該当の項目を取得する
                    guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_id == inspectionId })
                        .where({ $0.inspection_item_id == inspectionItemId }).first else {
                        // エラーを返却
                        throw ErrorID.ID9999
                    }
                    
                    // versionが更新されていたら該当する項目を更新する
                    if inspectionItemData.version < version {
                        // 判定結果
                        inspectionItemData.ai_result = response.result
                        // 品番
                        inspectionItemData.model = response.model
                        // 製造番号
                        inspectionItemData.serial_number = response.serialNumber
                        // 進捗状況
                        inspectionItemData.progress = progress
                        // オリジナル画像パス
                        inspectionItemData.s3_original_image_path = response.s3ImagePath
                        // 更新日時
                        inspectionItemData.ren_dt = Date()
                        // バージョン
                        inspectionItemData.version = response.version ?? 0
                    }
                }
            }
        } catch {
            throw error
        }
    }
    
    /// 点検IDが一致する点検項目データを取得
    /// - Parameter inspectionID: 点検ID
    /// - Returns: 点検項目リスト
    func getInspectionItemDataList(inspectionID: Int) throws -> [TBL_T_INSPECTION_ITEM] {
        do {
            let realm = try realmDataSource.getRealm()
            // 現在ある点検IDが一致する点検項目データ
            let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self)
                .where({ $0.inspection_id == inspectionID })
                .where({ $0.delete_flg != 1 })
                .sorted(byKeyPath: "mak_dt", ascending: true)
            
            return Array(inspectionItemData)
        } catch {
            throw error
        }
    }
    
    /// 削除する予定の点検項目データリストを取得
    /// - Parameter inspectionID: 点検ID
    func getDeleteInspectionItemDataList(inspectionID: Int) throws -> [TBL_T_INSPECTION_ITEM] {
        do {
            let realm = try realmDataSource.getRealm()
            // 現在ある点検IDが一致する点検項目データ
            let inspectionItemData = Array(realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_id == inspectionID }).where({ $0.delete_flg == 1 }))
                
            return inspectionItemData
        } catch {
            throw error
        }
    }
    
    /// 1つの点検項目取得
    /// - Parameter inspectionID: 点検項目ID
    /// - Returns: 点検項目
    func getInspectionItemData(inspectionItemUUID: UUID) throws -> TBL_T_INSPECTION_ITEM {
        do {
            let realm = try realmDataSource.getRealm()
            // 対象の点検項目を取得
            guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_uuid == inspectionItemUUID }).where({ $0.delete_flg != 1 }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            return inspectionItemData
        } catch {
            throw error
        }
    }
    
    ///  inspectionItemID(Int)から点検項目を取得する
    func getInspectionItemData(inspectionItemID: Int) throws -> TBL_T_INSPECTION_ITEM {
        do {
            let realm = try realmDataSource.getRealm()
            // 対象の点検項目を取得
            guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_id == inspectionItemID }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            
            return inspectionItemData
        } catch {
            throw error
        }
    }
    
    /// NGコメント保存
    /// - Parameters:
    ///   - inspectionItemUUID: 点検項目ID
    ///   - ngComment: NGコメント
    func updateNGComment(inspectionItemUUID: UUID, ngComment: String) throws {
        do {
            let realm = try realmDataSource.getRealm()
            // 対象の点検項目を取得
            guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_uuid == inspectionItemUUID }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            try realm.write {
                // NGコメント更新
                inspectionItemData.ng_comment = ngComment
            }
        } catch {
            throw error
        }
    }
    
    /// 点検結果編集処理
    /// - Parameters:
    ///   - inspectionItemUUID: 点検項目ID
    ///   - exitInspectionResult: 点検結果編集View
    func updateInspectionResult(inspectionItemUUID: UUID, exitInspectionResult: ExitInspectionResultView) throws {
        do {
            let realm = try realmDataSource.getRealm()
            // 現在ある点検IDが一致する点検項目データ
            guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_uuid == inspectionItemUUID }).first else {
                throw ErrorID.ID9999
            }
            try realm.write {
                //点検項目更新
                // 品番を編集
                inspectionItemData.edited_model = exitInspectionResult.model.text
                // 製造番号を編集
                inspectionItemData.edited_serial_number = exitInspectionResult.serialNumber.text
            }
        } catch {
            throw error
        }
    }
    
    /// 画像保存時の更新処理
    /// - Parameters:
    /// - id: 点検項目ID
    /// - takenAt: 撮影日時
    /// - localImagePath: ローカルパス
    /// - s3ImagePath: S3画像パス
    /// - progress: 進捗
    /// - inspectionID: 点検ID
    func updateSaveImageProcess(inspectionItemUUID: UUID, takenAt: String, localOriginalImagePath: String, localTrimingImagePath: String, s3OriginalImagePath: String, s3TrimingImagePath: String, progress: Int, inspectionID: Int) throws {
        do {
            let realm = try realmDataSource.getRealm()
            // 対象の点検データ取得
            guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_uuid == inspectionItemUUID }).where({ $0.delete_flg != 1 }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            try realm.write {
                // 点検項目更新
                // 撮影日時
                inspectionItemData.taken_dt = fixDateFromString(date: takenAt, format: DRAW_DATE_FORMAT)
                // ローカルオリジナルパス
                inspectionItemData.local_original_image_path = localOriginalImagePath
                // ローカルトリミングパス
                inspectionItemData.local_triming_image_path = localTrimingImagePath
                // S3オリジナル画像パス
                inspectionItemData.s3_original_image_path = s3OriginalImagePath
                // S3トリミング画像パス
                inspectionItemData.s3_triming_image_path = s3TrimingImagePath
                // AI判定結果
                inspectionItemData.ai_result = nil
                // 品番
                inspectionItemData.model = nil
                // 製造番号
                inspectionItemData.serial_number = nil
                // 編集済品番
                inspectionItemData.edited_model = nil
                // 編集済製造番号
                inspectionItemData.edited_serial_number = nil
                // 進捗状況
                inspectionItemData.progress = progress
                // NGコメント
                inspectionItemData.ng_comment = nil
                // 更新日時
                inspectionItemData.ren_dt = Date()
            }
        } catch {
            throw error
        }
    }
    
    /// 画像再送信時の更新処理
    /// - Parameters:
    /// - id: 点検項目ID
    ///  - progress: 進捗
    func updateSaveImageProcessResend(id: UUID, progress: Int) throws {
        do {
            let realm = try realmDataSource.getRealm()
            // 対象の点検項目を取得
            guard let inspectionItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_uuid == id }).where({ $0.delete_flg != 1 }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            try realm.write {
                // 点検項目更新
                // 進捗状況
                inspectionItemData.progress = progress
                // 更新日時
                inspectionItemData.ren_dt = Date()
            }
        } catch {
            throw error
        }
    }
    
    /// 点検項目を削除する
    /// - Parameter inspectionItemUUID: 点検項目ID
    func deleteInspectionItemData(inspectionItemUUID: UUID) throws {
        do {
            let realm = try realmDataSource.getRealm()
            try realm.write {
                // 削除する点検項目データ
                guard let targetItemData = realm.objects(TBL_T_INSPECTION_ITEM.self).where({ $0.inspection_item_uuid == inspectionItemUUID }).where({ $0.delete_flg != 1 }).first else {
                    // エラーを返却
                    throw ErrorID.ID9999
                }
                // 点検IDがnilかどうかをチェックする
                // 点検項目IDがnil以外なら論理削除する
                // 点検項目IDがnilなら物理削除
                targetItemData.inspection_item_id != nil ? targetItemData.delete_flg = 1 : realm.delete(targetItemData)
            }
        } catch {
            throw error
        }
    }
}
