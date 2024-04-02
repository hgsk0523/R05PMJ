import RealmSwift

/// 撮影例画像用Realmデータ管理クラス
final class ExampleImageDataSource {
    
    // MARK: - Injection
    private let realmDataSource: BaseRealmDataSourceProtocol
    
    // MARK: - Initializer
    
    init(_ realmDataSource: BaseRealmDataSourceProtocol) {
        self.realmDataSource = realmDataSource
        
    }
    
    // MARK: - Method

    /// 撮影例画像を保存
    /// - Parameters:
    ///   - photoData: 撮影例データ
    func saveExampleImageData(photoData: TBL_M_SAMPLE_PHOTO) throws {
        do {
            let realm =  try realmDataSource.getRealm()
            try realm.write {
                realm.add(photoData)
            }
        } catch {
            throw error
        }
    }
    
    /// 撮影例データを取得
    /// - Parameters:
    ///   - inspectionNameID: 点検名ID
    ///   - inspectionItemNameID: 点検項目名ID
    func getExampleImageData(inspectionNameID: Int, inspectionItemNameID: Int?) throws -> [TBL_M_SAMPLE_PHOTO]? {
        do {
            let realm =  try realmDataSource.getRealm()
            // 対象の点検データを取得
            return Array(realm.objects(TBL_M_SAMPLE_PHOTO.self).where({ $0.inspection_name_id == inspectionNameID }).where({ $0.item_name_id == inspectionItemNameID }))
        } catch {
            throw error
        }
    }
    
    /// 撮影例データ削除
    func deleteExampleImageData() throws {
        do {
            let realm = try realmDataSource.getRealm()
            try realm.write {
                // 撮影例マスタを全て取得
                let deleteUserData = realm.objects(TBL_M_SAMPLE_PHOTO.self)
                // 撮影例マスタを全て削除
                realm.delete(deleteUserData)
            }
        } catch {
            throw error
        }
    }
}
