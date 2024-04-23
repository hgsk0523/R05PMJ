import Foundation

/// 点検データソース
class InspectionViewDataSource: NSObject {
    
    // MARK: - Property
    /// シングルトン
    private override init() {}
    public static let shared = InspectionViewDataSource()
    
    /// パラメータ情報
    var inspectionViewInfo = InspectionViewInfo()
        
    // MARK: - Method
    
    /// 点検情報保存
    /// - Parameters:
    ///   - inspectionName: 点検名
    ///   - inspectionNameID: 点検名ID
    ///   - inspectionDate: 点検日
    ///   - wscd: WSCD
    ///   - model: 品番
    ///   - customerName: 名称
    ///   - comment: コメント
    ///   - status: 状態
    func setInspectionViewInfo(inspectionID: Int, inspectionName: String, inspectionNameID: Int, inspectionDate: String, wscd: String, model: String, customerName: String, comment: String, status: Int,companyCD: String, baseCD: String) {
        self.inspectionViewInfo.setInspectionInspectionInfo(inspectionID: inspectionID, inspectionName: inspectionName, inspectionNameID: inspectionNameID, inspectionDate: inspectionDate, wscd: wscd, model: model, customerName: customerName, comment: comment, status: status,companyCD: companyCD, baseCD: baseCD)
    }
    
    /// 点検データ情報を返す
    /// - Returns: 点検情報
    func getInspectionViewInfo() -> InspectionViewInfo {
        return self.inspectionViewInfo
    }
    
    /// 点検項目ID(UUID)をinfoに保存
    /// - Parameter inspectionItemUUID: 点検項目ID(UUID)
    func setInspectionItemUUID(inspectionItemUUID: UUID) {
        self.inspectionViewInfo.inspectionItemUUID = inspectionItemUUID
    }
    
    /// 点検項目ID(Int)をinfoに保存
    /// - Parameter inspectionItemID: 点検項目ID(Int)
    func setInspectionItemID(inspectionItemID: Int?) {
        self.inspectionViewInfo.inspectionItemID = inspectionItemID
    }
    
    /// 点検項目名をinfoに保存
    /// - Parameter inspectionItemName: 点検項目名
    func setInspectionItemName(inspectionItemName: String) {
        self.inspectionViewInfo.inspectionItemName = inspectionItemName
    }
    
    /// 点検IDをセットする
    /// - Parameter inspectionID: 点検ID
    func setInspectionID(inspectionID: Int) {
        self.inspectionViewInfo.setInspectionID(inspection_id: inspectionID)
    }
    
    /// 状態をセットする
    /// - Parameter status: 状態
    func setStatus(status: Int) {
        self.inspectionViewInfo.setStatus(status: status)
    }
    
    /// 作成日時をセットする
    /// - Parameter date: 日時
    func setCreateDate(date: Date) {
        self.inspectionViewInfo.setCreateDate(date: date)
    }
}
