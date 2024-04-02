import UIKit

/// 点検項目追加View
class AddInspectionItemView: UIView {
    
    // MARK: - Property
    
    /// 項目名のアウトレット
    @IBOutlet weak var itemName: UITextField!
    
    /// 追加ボタンのアウトレット
    @IBOutlet weak var addButton: UIButton!
    
    /// 画面名
    private let SCREEN_NAME: String = "点検項目追加画面"
    
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
        let view = Bundle.main.loadNibNamed("AddInspectionItemView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// テキストの制限
    /// - Parameter sender: 項目名フィールド
    @IBAction func changeText(_ sender: UITextField) {
        self.setActiveButton()
    }
    
    /// 閉じるボタンを押した時
    @IBAction func onTapCloseButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "閉じるボタン押下")
        self.removeFromSuperview()
    }
    
    /// 追加ボタンアクション
    @IBAction func onTapAddButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "リストに追加ボタン押下")
        // 点検項目を追加する
        if let parentVC = self.parentViewController() as? InspectionViewController {
            parentVC.onTapAddInspectionItem(inspectionItemName: self.itemName.text!) {
                self.removeFromSuperview()
            }
        }
    }
    
    // MARK: - Method
    
    // 初期設定
    private func initialSetting() {
        /// 入力欄のデリゲート
        self.itemName.delegate = self
        
        self.setActiveButton()
    }
    
    /// ボタン非活性
    private func setActiveButton() {
        // 入力欄が入力されていたら新規追加ボタンを活性化
        self.addButton.isEnabled = (
            !(itemName.text?.isEmpty ?? true) &&
            (self.checkText(text: itemName.text!))
        )
    }
    
    /// テキストが空白のみかチェックする
    /// - 空白以外の文字が入っていたらtrueを返す
    /// - Parameter text: 記入欄のテキスト
    /// - Returns: 判定結果
    private func checkText(text: String) -> Bool {
        for oneCharacter in text {
            // 文字があるかどうかを判定
            if oneCharacter != " " && oneCharacter != "　" {
                return true
            }
        }
        return false
    }
}

// MARK: - UITextFieldDelegate

extension AddInspectionItemView : UITextFieldDelegate {
    // 入力済み文字の保存
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        inputText = textField.text ?? ""
        return true
    }
    
    // キーボードを閉じた際にも文字数確認(リターンキー以外で閉じた時のため)
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        let textFieldNumber = textField.text?.count ?? 0
        let text = textField.text ?? ""
        if textFieldNumber >= WORD_COUNT.INSPECTION_ITEM_NAME.getWordCount() {
            textField.text = String(text.prefix(WORD_COUNT.INSPECTION_ITEM_NAME.getWordCount()))
        }
        return true
    }
    
    // 入力制限
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let textFieldNumber = textField.text?.count ?? 0
        let text = textField.text ?? ""
        if(inputText == text && textFieldNumber >= WORD_COUNT.INSPECTION_ITEM_NAME.getWordCount()){
            textField.text = String(text.prefix(WORD_COUNT.INSPECTION_ITEM_NAME.getWordCount()))
        }
    }
    
    // returnキーを押下時キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
