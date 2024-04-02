import RealmSwift

/// 点検データ用Realmデータ管理クラス
final class InspectionRealmDataSource {
    
    // MARK: - Injection
    
    private let realmDataSource: BaseRealmDataSourceProtocol
    
    // MARK: - Initializer
    
    init(_ realmDataSource: BaseRealmDataSourceProtocol) {
        self.realmDataSource = realmDataSource
    }
    
    // MARK: - Method
    
    /// 点検データ作成
    /// - Parameters:
    ///   - response: レスポンス
    ///   - parametersInfo: パラメータ情報
    /// - Returns: 点検データ
    
    private func createInspectionInspectionData(response: GetInspectionItemApiResponse, parametersInfo: ParametersInfo) throws -> TBL_T_INSPECTION {
        do {
            // 点検データの内容をRealmの方に設定
            // 点検データをインスタンス化
            let inspectionData = TBL_T_INSPECTION()
            // 各データのnilチェック
            guard let inspectionID = response.schedule?.id,
                  let status = response.schedule?.status,
                  let inspectionNameID = response.schedule?.inspectionNameId else {
                throw ErrorID.ID9999
            }
            // 点検ID
            inspectionData.inspection_id = inspectionID
            // 点検名ID
            inspectionData.inspection_name_id = inspectionNameID
            // WSCD
            inspectionData.worksheet_code = parametersInfo.WSHEETNO
            // 受付確定日
            inspectionData.receipt_confirmation_date = parametersInfo.UUKAKUTEIDATE
            // 点検日
            inspectionData.inspection_date = parametersInfo.YOTEIYMD
            // 品番
            inspectionData.model = parametersInfo.KATASIKI
            // お客様名称
            inspectionData.client_name = parametersInfo.KKNAME
            // 状態
            inspectionData.status = status
            // 会社CD
            inspectionData.company_code = parametersInfo.KAISHACD
            // 担当拠点CD
            inspectionData.base_code = parametersInfo.KYOTENCD
            // 担当者CD
            inspectionData.worker_code = parametersInfo.STANTOUCD
            // 作成日時
            inspectionData.mak_dt = Date()
            // 更新日時
            inspectionData.ren_dt = Date()
            
            return inspectionData
        } catch {
                throw error
            }
    }
    
    /// 点検データ、点検項目を保存
    /// - Parameters:
    ///   - response: サーバー情報
    ///   - parametersInfo: パラメータ情報
    ///   - inspectionItemRealmDataSource: 点検項目データソース
    func saveInspectionData(response: GetInspectionItemApiResponse, parametersInfo: ParametersInfo, inspectionItemRealmDataSource: InspectionItemRealmDataSource) throws {
        do {
            let realm = try realmDataSource.getRealm()
            try realm.write {
                // 既存の点検データを削除する
                realm.delete(realm.objects(TBL_T_INSPECTION.self))
                // 既存の点検項目データを削除する
                realm.delete(realm.objects(TBL_T_INSPECTION_ITEM.self))
                // 点検データ作成
                let inspectionData = try self.createInspectionInspectionData(response: response, parametersInfo: parametersInfo)
                // 点検項目作成
                let inspectionItemDataList = try inspectionItemRealmDataSource.createInspectionItemData(response: response)
                // 点検データを保存
                realm.add(inspectionData)
                // 点検項目を保存
                inspectionItemDataList.forEach { data in
                    realm.add(data)
                }
            }
        } catch {
            throw error
        }
    }
    
    /// 点検データを1つ取得
    /// - Parameter inspectionID: 点検ID
    /// - Returns: 点検データ
    func getInspectionData(inspectionID: Int) throws -> TBL_T_INSPECTION {
        do {
            let realm = try realmDataSource.getRealm()
            guard let inspectionData = realm.objects(TBL_T_INSPECTION.self).where({ $0.inspection_id == inspectionID }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            return inspectionData
        } catch {
            throw error
        }
    }
    
    /// 点検状態を更新する
    /// - Parameters:
    ///   - inspectionID: 点検ID
    ///   - status: 状態
    func updateInspectionDataStatus(inspectionID: Int, status: Int) throws {
        do {
            let realm = try realmDataSource.getRealm()
            // 点検データの取得
            guard let inspectionData = realm.objects(TBL_T_INSPECTION.self).where({ $0.inspection_id == inspectionID }).first else {
                // エラーを返却
                throw ErrorID.ID9999
            }
            // データ更新
            try realm.write {
                // 点検状態
                inspectionData.status = status
                // 更新日時
                inspectionData.ren_dt = Date()
            }
        } catch {
            throw error
        }
    }
}
