import UIKit

/// ログアウトView
class LogoutView: UIView {
    
    // MARK: - Lifecycle
    
    // コードから生成された場合
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }
    
    // ストーリーボードから生成された場合
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
    }
    
    private func loadNib() {
        let view = Bundle.main.loadNibNamed("LogoutView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// ログアウトボタンを押した時
    /// - Parameter sender: ログアウトボタン
    @IBAction func onTapLogoutButton(_ sender: Any) {
        log.info("ログアウトボタン押下")
        NavigationBarController.shared.logout()
        self.removeFromSuperview()
    }
}
