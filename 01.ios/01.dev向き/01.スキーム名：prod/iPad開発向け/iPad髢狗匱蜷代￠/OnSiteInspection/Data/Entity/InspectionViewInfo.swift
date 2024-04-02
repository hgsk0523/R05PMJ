import Foundation
import UIKit

/// 点検画面情報
struct InspectionViewInfo {
    
    // MARK: - Property
    
    /// 表示している点検リストのID
    var inspectionId: Int!
    /// 指定した点検項目ID(UUID)
    var inspectionItemUUID: UUID!
    /// 指定した点検項目ID(Int)
    var inspectionItemID: Int?
    /// 指定した点検項目名
    var inspectionItemName: String!
    /// 点検名
    var inspectionName: String!
    /// 点検名ID
    var inspectionNameID: Int!
    /// 点検日
    var inspectionDate: String!
    /// WSCD
    var wscd: String!
    /// 品番
    var model: String!
    /// 名称
    var customerName: String!
    /// コメント
    var comment: String!
    /// 状態
    var status: Int!
    /// 会社CD
    var companyCD: String!
    /// 担当拠点CD
    var baseCD: String!
    /// 点検レコード作成時間
    var createDate: Date?
    
    // MARK: - Method
    
    /// 表示する点検リストの設定
    /// - Parameter inspection_id: 点検ID
    mutating func setInspectionID(inspection_id: Int) {
        self.inspectionId = inspection_id
    }
    
    /// 選択した点検項目IDの設定
    /// - Parameter inspectionItemUUID: 点検項目ID
    mutating func setInspectionItemUUID(inspectionItemUUID: UUID) {
        self.inspectionItemUUID = inspectionItemUUID
    }
    
    /// 選択した点検項目IDの設定
    /// - Parameter inspectionItemName: 点検項目名
    mutating func setInspectionItemName(inspectionItemName: String) {
        self.inspectionItemName = inspectionItemName
    }
    
    /// 状態を保存する
    /// - Parameter status: 状態
    mutating func setStatus(status: Int) {
        self.status = status
    }
    
    /// 作成時間を保存する
    /// - Parameter status: 状態
    mutating func setCreateDate(date: Date) {
        self.createDate = date
    }
    
    /// 点検データを設定
    mutating func setInspectionInspectionInfo(inspectionID: Int, inspectionName: String, inspectionNameID: Int, inspectionDate: String, wscd: String, model: String, customerName: String, comment: String, status: Int, companyCD: String, baseCD: String) {
        /// 点検ID
        self.inspectionId = inspectionID
        /// 点検名
        self.inspectionName = inspectionName
        /// 点検名ID
        self.inspectionNameID = inspectionNameID
        /// 点検日
        self.inspectionDate = inspectionDate
        /// WSCD
        self.wscd = wscd
        /// 品番
        self.model = model
        /// 名称
        self.customerName = customerName
        /// コメント
        self.comment = comment
        /// 状態
        self.status = status
        /// 会社CD
        self.companyCD = companyCD
        /// 担当拠点CD
        self.baseCD = baseCD
    }
}
