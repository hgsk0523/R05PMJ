import UIKit

/// 点検View
class InspectionView: UITableViewCell {
    
    // MARK: - Property
    
    /// 点検名
    @IBOutlet weak var inspectionName: CustomLabel!
    /// 日付
    @IBOutlet weak var date: UILabel!
    /// 時間
    @IBOutlet weak var time: UILabel!
    /// wscd
    @IBOutlet weak var wscd: UILabel!
    /// 品番
    @IBOutlet weak var model: UILabel!
    /// 品番の横幅
    @IBOutlet weak var serialNumberWidth: NSLayoutConstraint!
    /// 名称
    @IBOutlet weak var name: UILabel!
    /// 状態イメージのアウトレット
    @IBOutlet weak var statusButton: CustomButton!
    /// コメントViewのアウトレット
    @IBOutlet weak var commentButton: CustomButton!
    /// 全体Viewのアウトレット
    @IBOutlet weak var view: UIView!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        // 初期設定
        // NOTE: - initFromNibでは利用できなかった
        self.initialSetting()
    }
    
    /// セルを初期化するメソッド
    /// - Returns: 点検View
    class func initFromNib() -> InspectionView {
        // xibファイルのオブジェクトをインスタンス
        let className : String = String(describing: InspectionView.self)
        return Bundle.main.loadNibNamed(className, owner: self, options: nil)?.first as! InspectionView
    }
    
    // MARK: - Action
    
    /// コメントボタンをタップされた時の処理
    /// - Parameter sender: コメントボタン
    @IBAction func onTapCommentButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            parentVC.onTapDisplayCommentButton()
        }
    }
    
    // MARK: - Method
    
    /// 初期設定
    private func initialSetting() {
        // 品番の文字列表示数制限
        self.serialNumberWidth.constant = self.model.font.pointSize * 10
        self.model.lineBreakMode = .byTruncatingTail
    }
}
