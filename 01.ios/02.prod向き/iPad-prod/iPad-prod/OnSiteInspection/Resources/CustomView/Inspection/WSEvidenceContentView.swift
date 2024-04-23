import UIKit

/// WSエビデンスコンテンツView
class WSEvidenceContentView: UITableViewCell {
    // MARK: - Property
    
    /// ラジオボタンのアウトレット
    @IBOutlet weak var radioButton: UIButton!
    
    /// ラベルのアウトレット
    @IBOutlet weak var label: UILabel!
    
    /// WSエビデンスコンテンツのアウトレット
    @IBOutlet weak var wsEvidenceContent: UIStackView!
    
    /// ボタンが押されているかどうかをみるフラグ
    private var buttonCheckFlag: Bool = false
    
    /// エビデンスID
    private var evidenceID: Int!
    
    /// 再点検フラグ
    private var isEditable: Bool!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    /// セルを初期化するメソッド
    /// - Returns: WSエビデンスコンテントView
    class func initFromNib() -> WSEvidenceContentView {
        // xibファイルのオブジェクトをインスタンス
        let className : String = String(describing: WSEvidenceContentView.self)
        return Bundle.main.loadNibNamed(className, owner: self, options: nil)?.first as! WSEvidenceContentView
    }
    
    // MARK: - Method
    
    /// ラジオボタンのフラグを返す
    /// - Returns: ラジオボタンにチェックが入っているかどうか
    func getRadioButtonFlag() -> Bool {
        return buttonCheckFlag
    }
    
    /// エビデンスIDを設定
    /// - Parameter evidenceID: エビデンスID
    func setEvidenceID(evidenceID: Int) {
        self.evidenceID = evidenceID
    }
    
    /// エビデンスIDを取得
    /// - Returns: エビデンスID
    func getEvidenceID() -> Int {
        return self.evidenceID
    }
    
    /// 再点検フラグを設定
    /// - Parameter isEditable: 再点検
    func setIsEditable(isEditable: Bool) {
        self.isEditable = isEditable
    }
    
    /// 再点検グラグを取得
    /// - Returns: 再点検フラグ
    func getIsEditable() -> Bool {
        return self.isEditable
    }
    
    /// ラジオボタンのフラグをセット
    /// - Parameter flag: フラグ
    func setRadioButtonFlag(flag: Bool) {
        self.buttonCheckFlag = flag
    }
    
    /// ラジオボタンのイメージと状態をセットする
    /// - Parameters:
    ///   - flag: セットしたいフラグ
    func setRadioButtonImage() {
        if self.getRadioButtonFlag() {
            // ラジオボタンが押されている状態の場合
            // 押されているイメージに変更
            self.radioButton.setImage(UIImage(systemName: "circle.inset.filled"), for: .normal)
        } else {
            // ラジオボタンが押されていない状態の場合
            // circleイメージに変更
            self.radioButton.setImage(UIImage(systemName: "circle"), for: .normal)
        }
    }
}
