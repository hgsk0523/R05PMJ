import UIKit
import Foundation

/// NGコメント登録View
class RegisterNGCommentView: UIView {
    
    // MARK: - Property
    
    /// NGコメントのアウトレット
    @IBOutlet weak var ngComment: UITextField!
    
    /// 登録ボタンのアウトレット
    @IBOutlet weak var registerButton: CustomButton!
    
    /// 画面名
    private let SCREEN_NAME: String = "NGコメント登録画面"
    
    // 文字入力
    private var inputText = ""
    
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
        infoLog(screen: SCREEN_NAME, logMessage: "閉じるボタン押下")
        self.removeFromSuperview()
    }
    
    /// 登録ボタンを押した時
    /// - Parameter sender: 登録ボタン
    @IBAction func onTapRegisterButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "登録ボタン押下")
        if let parentVC = self.parentViewController() as? InspectionViewController{
            parentVC.onTapRegisterNGCommentButton(ngComment: self.ngComment.text!) {
                self.removeFromSuperview()
            }
        }
    }
    
    @IBAction func changeText(_ sender: UITextField) {
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
    // 入力済み文字の保存
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        inputText = textField.text ?? ""
        return true
    }
    
    // キーボードを閉じた際にも文字数確認(リターンキー以外で閉じた時のため)
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        let textFieldNumber = textField.text?.count ?? 0
        let text = textField.text ?? ""
        if textFieldNumber >= WORD_COUNT.NG_COMMENT.getWordCount() {
            textField.text = String(text.prefix(WORD_COUNT.NG_COMMENT.getWordCount()))
        }
        return true
    }
    
    // 入力制限
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let textFieldNumber = textField.text?.count ?? 0
        let text = textField.text ?? ""
        if(inputText == text && textFieldNumber >= WORD_COUNT.NG_COMMENT.getWordCount()){
            textField.text = String(text.prefix(WORD_COUNT.NG_COMMENT.getWordCount()))
        }
    }
    
    // returnキーを押下時キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

