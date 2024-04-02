import UIKit

/// 撮影例説明画面
struct DescriptionOfShootingInfo {

    /// 説明タイトル
    var title: String = ""
    /// 説明リスト（説明画像：説明文）
    var descriptionList: [ExplanationInfo] = []
    
    /// 表示内容の設定
    mutating func setDescriptionOfShootingInfo(title: String, explanationInfo: [ExplanationInfo]) {
        // タイトルの設定
        self.title = title
        //　説明リストの初期化
        self.descriptionList = explanationInfo
    }
}

/// 撮影例説明情報
struct ExplanationInfo {
    let image: UIImage
    let explanation: String
}
