import UIKit
import Combine

/// 撮影例説明画面のサービスクラス
class DescriptionOfShootingService: NSObject {
    /// シングルトン
    private override init() {}
    public static let shared = DescriptionOfShootingService()
    
    /// 撮影例説明画面情報
    var descriptionOfShootingInfo = DescriptionOfShootingInfo()
    
    /// 撮影例説明画面用のViewオブジェクト
    private var descriptionOfShootingView: DescriptionOfShootingView?
    
    /// 現在表示中の説明画像のインデックス
    private var index = 0
    
    /// 撮影例情報の設定
    func setDescriptionOfShootingInfo(title: String, explanationInfo:[ExplanationInfo]) {
        self.descriptionOfShootingInfo.setDescriptionOfShootingInfo(title: title, explanationInfo: explanationInfo)
    }
    
    /// 撮影例説明画面の作成
    func createDescriptionOfShootingView() -> UIView? {
        
        // インデックスの初期化
        index = 0
        // 撮影例説明画面Viewのインスタンス化
        self.descriptionOfShootingView = DescriptionOfShootingView()
        // 撮影例説明画面のタイトルを設定
        self.descriptionOfShootingView?.setTitle(text: self.descriptionOfShootingInfo.title)
        
        if let samples = self.descriptionOfShootingInfo.descriptionList.first {
            // 説明文の設定
            self.descriptionOfShootingView?.setDescriptionText(text: samples.explanation)
            // 説明画像の設定
            self.descriptionOfShootingView?.setDescriptionImage(image: samples.image)
        } else {
            // 表示例登録なし
            return nil
        }
        // テキストVIewの高さを調整
        self.descriptionOfShootingView?.setTextViewHeight()
        
        return descriptionOfShootingView!
    }
    
    /// 説明画面を進める
    func advanceDescriptionOfShootingView() {
        
        // 撮影例説明画面で表示する画像を設定
        if self.descriptionOfShootingInfo.descriptionList.count > (index + 1) {
            // 撮影例が最後のもの以外を表示していたら次の撮影例を表示する
            index += 1
            self.descriptionOfShootingView!.setDescriptionImage(image: self.descriptionOfShootingInfo.descriptionList[index].image)
            self.descriptionOfShootingView!.setDescriptionText(text: self.descriptionOfShootingInfo.descriptionList[index].explanation)
            
        } else {
            // 撮影例が最後のものを表示していたら最初の撮影例を表示する
            // インデックスの初期化
            index = self.descriptionOfShootingInfo.descriptionList.startIndex
            self.descriptionOfShootingView!.setDescriptionImage(image: self.descriptionOfShootingInfo.descriptionList[index].image)
            self.descriptionOfShootingView!.setDescriptionText(text: self.descriptionOfShootingInfo.descriptionList[index].explanation)
        }
    }
    
    /// 説明画面を戻す
    func decreaseDescriptionOfShootingView() {
        
        // 撮影例説明画面で表示する画像を設定
        if 0 <= (index - 1) {
            // 撮影例が最初のもの以外を表示していたら前の撮影例を表示する
            index -= 1
            self.descriptionOfShootingView!.setDescriptionImage(image: self.descriptionOfShootingInfo.descriptionList[index].image)
            self.descriptionOfShootingView!.setDescriptionText(text: self.descriptionOfShootingInfo.descriptionList[index].explanation)
        } else {
            // 撮影例が最初のものを表示していたら最後の撮影例を表示する
            // インデックスの初期化
            index = self.descriptionOfShootingInfo.descriptionList.endIndex - 1
            self.descriptionOfShootingView!.setDescriptionImage(image: self.descriptionOfShootingInfo.descriptionList[index].image)
            self.descriptionOfShootingView!.setDescriptionText(text: self.descriptionOfShootingInfo.descriptionList[index].explanation)
        }
    }
}
