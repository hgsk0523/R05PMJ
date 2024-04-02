import UIKit

/// 点検結果編集View
class ExitInspectionResultView: UIView {
    
    // MARK: - Property
    
    /// 品番のアウトレット
    @IBOutlet weak var model: UITextField!
    
    /// 製造番号のアウトレット
    @IBOutlet weak var serialNumber: UITextField!
    
    /// 更新ボタンのアウトレット
    @IBOutlet weak var updateButton: CustomButton!
    
    /// 画面名
    private let SCREEN_NAME: String = "点検結果編集画面"
    
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
        let view = Bundle.main.loadNibNamed("ExitInspectionResultView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// 閉じるボタンを押した時
    @IBAction func onTapCloseButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "閉じるボタン押下")
        self.removeFromSuperview()
    }
        
    /// 更新ボタンを押した時
    /// - Parameter sender: 更新ボタン
    @IBAction func onTapExitButton(_ sender: Any) {
        infoLog(screen: SCREEN_NAME, logMessage: "更新ボタン押下")
        if let parentVC = self.parentViewController() as? InspectionViewController {
            parentVC.onTapExitInspectionResult(exitInspectionResultView: self) {
                self.removeFromSuperview()
            }
        }
    }
    
    /// テキストを制御する
    /// - Parameter sender: テキストフィールド
    @IBAction func changeText(_ sender: UITextField) {
        // 更新ボタンの活性非活性
        self.setActiveButton()
    }
    
    // MARK: - Method
    
    /// 初期設定
    private func initialSetting() {
        /// 各入力欄のデリゲート
        self.model.delegate = self
        self.serialNumber.delegate = self
    }
    
    /// 点検項目データをセットする
    /// 品番、製造番号のデフォルト値用
    /// - Parameter inspectionItemData: 点検項目データ
    func setInspectionItemData(inspectionItemData: TBL_T_INSPECTION_ITEM) {
        // 品番にテキストを代入
        self.model.text = inspectionItemData.edited_model == nil ? inspectionItemData.model : inspectionItemData.edited_model
        // 製造番号にテキストを代入
        self.serialNumber.text = inspectionItemData.edited_serial_number == nil ? inspectionItemData.serial_number : inspectionItemData.edited_serial_number
        // 更新ボタンの活性非活性
        self.setActiveButton()
    }
    
    /// ボタン非活性
    private func setActiveButton() {
        // 入力欄が入力されていたら新規追加ボタンを活性化
        self.updateButton.isEnabled = (
            !(model.text?.isEmpty ?? true) &&
            !(serialNumber.text?.isEmpty ?? true)
        )
    }
}

// MARK: - Delegate

extension ExitInspectionResultView : UITextFieldDelegate {
    // 入力済み文字の保存
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        inputText = textField.text ?? ""
        return true
    }
    
    // キーボードを閉じた際にも文字数確認(リターンキー以外で閉じた時のため)
    func textFieldShouldEndEditing(_ textField: UITextField) -> Bool {
        // 文字数最大値を定義
        var maxLength: Int = 0
        
        switch (textField.tag) {
        case 1: // 品番
            maxLength = WORD_COUNT.MODEL.getWordCount()
        case 2: // 製造番号
            maxLength = WORD_COUNT.SERIAL_NUMBER.getWordCount()
        default:
            break
        }
        
        let textFieldNumber = textField.text?.count ?? 0
        let text = textField.text ?? ""
        if textFieldNumber >= maxLength {
            textField.text = String(text.prefix(maxLength))
        }
        return true
    }
    
    // 入力制限
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // 文字数最大値を定義
        var maxLength: Int = 0
        
        switch (textField.tag) {
        case 1: // 品番
            maxLength = WORD_COUNT.MODEL.getWordCount()
        case 2: // 製造番号
            maxLength = WORD_COUNT.SERIAL_NUMBER.getWordCount()
        default:
            break
        }
        let textFieldNumber = textField.text?.count ?? 0
        let text = textField.text ?? ""
        if(inputText == text && textFieldNumber >= maxLength){
            textField.text = String(text.prefix(maxLength))
        }
    }
    
    // returnキーを押下時キーボードを閉じる
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}

