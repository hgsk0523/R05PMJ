import UIKit

/// コメント表示View
class DisplayCommentView: UIView {
    
    // MARK: - Property
    
    /// コメントのアウトレット
    @IBOutlet weak var comment: UITextView!
    
    // MARK: - Lifecycle
    
    // コードから生成された場合
    override init(frame: CGRect){
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
    
    private func loadNib(){
        let view = Bundle.main.loadNibNamed("DisplayCommentView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// 閉じるボタンを押した時
    @IBAction func onTapCloseButton(_ sender: Any) {
        self.removeFromSuperview()
    }
    
    // MARK: - Method
    
    // 初期設定
    private func initialSetting() {
        // コメントを取得しセットする
        self.comment.text = InspectionViewDataSource.shared.getInspectionViewInfo().comment
    }
}
