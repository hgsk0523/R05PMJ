import UIKit

/// プレビュー
struct PreviewInfo {
    /// 表示画像
    var image: UIImage? = nil
    /// 撮影日時
    var date: Date = Date()
    /// 解析種別
    var analysisType: String?
    /// 点検項目名IDを保存
    var inspectionItemNameID: Int?
    
    /// 表示内容の設定
    /// - Parameter image:撮影画像
    mutating func setPreviewInfo(image: UIImage, date: Date) {
        self.image = image
        self.date = date
    }
    
    /// 解析種別の設定
    /// - Parameter type: 解析種別
    mutating func setAnalysisType(type: String?) {
        self.analysisType = type
    }
    
    /// 点検項目名IDの設定
    /// - Parameter inspectionItemNameID: 点検項目名IDの設定
    mutating func setInspectionItemNameID(inspectionItemNameID: Int?) {
        self.inspectionItemNameID = inspectionItemNameID
    }
}
