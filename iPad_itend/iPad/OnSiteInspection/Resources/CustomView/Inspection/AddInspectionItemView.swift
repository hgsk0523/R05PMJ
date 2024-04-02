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
    // 文字数制限
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        
        // 文字数最大値を定義
        var maxLength: Int = 0
        
        switch (textField.tag) {
        case 1: // 点検項目名
            maxLength = WORD_COUNT.INSPECTION_ITEM_NAME.getWordCount()
            
        default:
            break
        }
        
        // textField内の文字数
        let textFieldNumber = textField.text?.count ?? 0
        // 入力された文字数
        let stringNumber = string.count
        // 指定の文字数以下なら入力
        return textFieldNumber + stringNumber <= maxLength
    }
    
    // returnキーを押下時キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
