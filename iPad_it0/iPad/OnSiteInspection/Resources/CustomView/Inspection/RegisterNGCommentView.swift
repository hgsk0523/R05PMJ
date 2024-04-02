import UIKit
import Foundation

/// NGコメント登録View
class RegisterNGCommentView: UIView {
    
    // MARK: - Property
    
    /// NGコメントのアウトレット
    @IBOutlet weak var ngComment: UITextField!
    
    /// 登録ボタンのアウトレット
    @IBOutlet weak var registerButton: CustomButton!
    
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
        let view = Bundle.main.loadNibNamed("RegisterNGCommentView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// 閉じるボタンを押した時
    /// - Parameter sender: 閉じるボタン
    @IBAction func onTapCloseButton(_ sender: Any) {
        self.removeFromSuperview()
    }
    
    /// 登録ボタンを押した時
    /// - Parameter sender: 登録ボタン
    @IBAction func onTapRegisterButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController{
            parentVC.onTapRegisterNGCommentButton(ngComment: self.ngComment.text!) {
                self.removeFromSuperview()
            }
        }
    }
    
    @IBAction func changeText(_ sender: UITextField) {
        let regex = "^[^0-9A-Za-zぁ-ゞァ-ヾ\u{3005}\u{3007}\u{303b}\u{3400}-\u{9fff}\u{f900}-\u{faff}\u{20000}-\u{2ffff}]+$"
        sender.text = (sender.text ?? "").filter({String($0).range(of: regex, options: .regularExpression) == nil})
        // 登録ボタンの活性非活性設定
        self.setActiveButton()
    }
    
    // MARK: - Method
    
    // 初期設定
    private func initialSetting() {
        // ngコメントのデリゲート設定
        self.ngComment.delegate = self
        // 登録ボタンの活性非活性設定
        self.setActiveButton()
    }
    
    /// ボタン非活性
    private func setActiveButton() {
        // 入力欄が入力されていたら新規追加ボタンを活性化
        self.registerButton.isEnabled = (
            !(ngComment.text?.isEmpty ?? true) 
        )
    }
    
    /// 点検項目データをセット
    /// - Parameter inspectionItemData: 点検項目データ
    func setInspectionItemData(inspectionItemData: TBL_T_INSPECTION_ITEM) {
        /// NGコメント設置
        self.ngComment.text = inspectionItemData.ng_comment
    }
}

// MARK: - UITextFieldDelegate

extension RegisterNGCommentView : UITextFieldDelegate {
    
    // 文字数制限
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        // textField内の文字数
        let textFieldNumber = textField.text?.count ?? 0
        // 入力された文字数
        let stringNumber = string.count
        // 指定の文字数以下なら入力
        return textFieldNumber + stringNumber <= WORD_COUNT.NG_COMMENT.getWordCount()
    }
    
    // returnキーを押下時キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

