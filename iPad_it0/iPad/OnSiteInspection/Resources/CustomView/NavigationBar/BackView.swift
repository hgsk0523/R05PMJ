import UIKit

/// バックボタンView
class BackView: UIView {
    
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
        let view = Bundle.main.loadNibNamed("BackView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// タップされた時の処理
    /// - Parameter sender: バックボタン
    @IBAction func onTapBackButton(_ sender: Any) {
        log.info("戻るボタン押下")
        NavigationBarController.shared.backProcess()
    }
}
