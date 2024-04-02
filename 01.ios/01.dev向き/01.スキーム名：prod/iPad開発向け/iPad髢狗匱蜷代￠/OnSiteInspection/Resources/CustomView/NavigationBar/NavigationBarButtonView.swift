import UIKit

/// ナビゲーションボタンのView(ユーザーアカウント)
class NavigationBarButtonView: UIView {
    
    // MARK: - Property
    
    /// ビュー全体のアウトレット
    @IBOutlet weak var view: UIStackView!
    
    /// 担当者CDのアウトレット
    @IBOutlet weak var repCd: UILabel!
    
    // MARK: - Lifecycle
    
    // コードから生成された場合
    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
        // 初期設定
        self.initialSetting()
    }
    
    // ストーリーボードから生成された場合
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)!
        loadNib()
        // 初期設定
        self.initialSetting()
    }
    
    private func loadNib() {
        // カスタムビューを登録
        let view = Bundle.main.loadNibNamed("NavigationBarButtonView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
        
    }
    
    // MARK: - Action
    
    /// タップされた時の処理
    /// - Parameter sender: UITapGestureRecognizer
    @objc func onTapView(_ sender : UITapGestureRecognizer) {
        /// 現在見ているViewController
        let vc = UIApplication.topViewController()
        /// サブビューを取り出す
        let subviews = vc!.view.subviews
        // ユーザーアカウントのSubViewを消す
        for subview in subviews {
            if subview is LogoutView{
                subview.removeFromSuperview()
                return
            }
        }
        /// 表示したいユーザーアカウントView
        let userView = LogoutView()
        userView.frame = (vc!.view.bounds)
        vc?.view.addSubview(userView)
    }
    
    // MARK: - Method
    
    /// 初期登録
    private func initialSetting() {
        // タップ検知時の処理を登録
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapView(_:)))
        self.view.addGestureRecognizer(tapGesture)
    }
}
