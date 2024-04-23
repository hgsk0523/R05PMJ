import UIKit

/// アラート機能をまとめるクラス
final class Alert {
    
    /// OKラベル
    static let okLabel = "OK"
    
    /// キャンセルラベル
    static let cancelLabel = "キャンセル"
    
    /// OKのみアラート
    static func okAlert(vc: UIViewController, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let okAlertVC = UIAlertController(title: "", message: message, preferredStyle: .alert)
        okAlertVC.addAction(UIAlertAction(title: okLabel, style: .default, handler: handler))
        vc.present(okAlertVC, animated: true, completion: nil)
    }
    
    /// OK&キャンセルアラート
    static func cancelAlert(vc: UIViewController, message: String, handler: ((UIAlertAction) -> Void)? = nil) {
        let cancelAlertVC = UIAlertController(title: "", message: message, preferredStyle: .alert)
        cancelAlertVC.addAction(UIAlertAction(title: okLabel, style: .default, handler: handler))
        cancelAlertVC.addAction(UIAlertAction(title: cancelLabel, style: .cancel, handler: nil))
        vc.present(cancelAlertVC, animated: true, completion: nil)
    }
}
