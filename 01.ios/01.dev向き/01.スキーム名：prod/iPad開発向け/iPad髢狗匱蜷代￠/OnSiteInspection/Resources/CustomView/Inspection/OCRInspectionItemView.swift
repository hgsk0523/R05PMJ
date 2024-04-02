import UIKit

/// OCRの点検項目View
class OCRInspectionItemView: UIView {
    
    // MARK: - Property
    
    /// 点検項目名のアウトレット
    @IBOutlet weak var inspectionItemName: CustomLabel!
    /// 編集ボタンのアウトレット
    @IBOutlet weak var exitButton: CustomButton!
    /// 日時のラベルのアウトレット
    @IBOutlet weak var dateText: UILabel!
    /// 品番ラベルのアウトレット
    @IBOutlet weak var modelText: UILabel!
    /// 製造番号のアウトレット
    @IBOutlet weak var serialNumberText: UILabel!
    /// カメラボタンのアウトレット
    @IBOutlet weak var photographButton: CustomButton!
    /// 画像解析ボタンのアウトレット
    @IBOutlet weak var imageAnalysisButton: CustomButton!
    /// コンテンツの高さのアウトレット
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    /// サムネイルボタンのアウトレット
    @IBOutlet weak var thumbnailImageButton: UIButton!
    /// 撮影ボタンの状態
    private var isUnsent: Bool = false
    /// S3画像パス
    private var s3ImagePath: String?
    /// 点検項目名
    private var itemName: String = ""
    /// 解析種別
    private var analysisType: String?
    /// 進捗状況
    private var progress: Int?
    /// 点検項目id(Int)
    /// どの点検項目かを識別するために必要
    private var inspectionItemId: Int?
    /// 点検項目id(UUID)
    private var inspectionItemUUID: UUID?
    /// 点検項目名ID
    private var inspectionItemNameID: Int?
    
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
    
    func loadNib() {
        let view = Bundle.main.loadNibNamed("OCRInspectionItemView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
    }
    
    // MARK: - Action
    
    /// カメラボタンを押した時
    /// - Parameter sender: カメラボタン
    @IBAction func onTapCameraButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            if isUnsent {
                // 再送処理実行
                parentVC.onTapResend(inspectionItemUUID: self.inspectionItemUUID!,
                                     inspectionItemID: self.inspectionItemId,
                                     inspectionItemName: self.inspectionItemName.text!,
                                     inspectionItemNameID: self.inspectionItemNameID,
                                     analysisType: self.analysisType!)
            } else {
                // 撮影画面に遷移
                parentVC.onTapPhotograph(inspectionItemUUID: self.inspectionItemUUID!,
                                         inspectionItemID: self.inspectionItemId,
                                         inspectionItemName: self.inspectionItemName.text!,
                                         inspectionItemNameID: self.inspectionItemNameID,
                                         analysisType: self.analysisType!)
            }
        }
    }
    
    /// 画像解析ボタンを押した時
    /// - Parameter sender: 画像解析ボタン
    @IBAction func onTapAnalysisButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            parentVC.onTapAnalysisButton(inspectionItemID: self.inspectionItemId!)
        }
    }
    
    /// 編集ボタンを押した時
    /// - Parameter sender: 編集ボタン
    @IBAction func onTapExitButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            // 編集画面表示
                        parentVC.onTapExitInspectionResultButton(inspectionItemUUID: self.inspectionItemUUID!)
        }
    }
    
    
    /// 画像表示ボタンを押した時
    /// - Parameter sender: 画像表示ボタン
    @IBAction func onTapEnlargeImageButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            // 画像拡大画面表示
                        parentVC.onTapEnlargeImageButton(inspectionItemUUID: self.inspectionItemUUID!)
        }
    }
    
    // MARK: - Method
    
    /// コンテンツの初期化
    /// - Parameter inspectionItemData: ローカルから取得した点検項目のデータ
    private func initContents(inspectionItemData: TBL_T_INSPECTION_ITEM) {
        // 点検項目Viewにid(Int)を格納する
        self.inspectionItemId = inspectionItemData.inspection_item_id
        // 点検項目Viewに(UUID)を格納する
        self.inspectionItemUUID = inspectionItemData.inspection_item_uuid
        // 点検項目名設定
        self.inspectionItemName.text = inspectionItemData.item_name
        // s3イメージパス
        self.s3ImagePath = inspectionItemData.s3_original_image_path
        // 撮影日時を保存
        self.dateText.text = inspectionItemData.taken_dt?.toJst(format: DRAW_DATE_FORMAT)
        // 品番
        self.modelText.text = inspectionItemData.edited_model == nil ? inspectionItemData.model : inspectionItemData.edited_model
        // 製造番号
        self.serialNumberText.text = inspectionItemData.edited_serial_number == nil ? inspectionItemData.serial_number : inspectionItemData.edited_serial_number
        // 解析種別
        self.analysisType = inspectionItemData.analysis_type
        // 進捗状況
        self.progress = inspectionItemData.progress
        // 点検項目名ID
        self.inspectionItemNameID = inspectionItemData.item_name_id
        // 画像解析ボタンの非活性
        self.imageAnalysisButton.isEnabled = false
        // 編集ボタンを非活性
        if inspectionItemData.progress != INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue {
            self.exitButton.isEnabled = false
        }
        // 製造番号の文字の色を設定する
        self.setOCRLabelColor(inspectionItemData: inspectionItemData)
        // 高さを調整
        self.heightAnchor.constraint(equalToConstant: CGFloat(self.contentHeight.constant)).isActive = true
    }
    
    /// 画像解析ボタンの制御
    /// - Parameters:
    ///     - inspectionItemData: ローカルから取得した点検項目のデータ
    ///     - inspectionData: 点検データ
    private func setImageAnalysisButton(inspectionItemData: TBL_T_INSPECTION_ITEM, inspectionData: InspectionViewInfo) {
        
        // 進捗状態がサーバー保存済み出ない時は非活性化
        if inspectionItemData.progress != INSPECTION_PROGRESS.IMAGE_SAVED_REMOTE.rawValue {
            // 画像解析ボタンの非活性化
            self.imageAnalysisButton.isEnabled = false
            // 後続処理を行わない
            return
        }
        
        // 検査待ち、検査中、再点検の時のみ活性化
        switch inspectionData.status {
        case INSPECTION_STATUS.WAITING.rawValue, INSPECTION_STATUS.UNDER_INSPECTION.rawValue, INSPECTION_STATUS.RE_INSPECTION.rawValue:
            // 画像解析ボタンの活性化
            self.imageAnalysisButton.isEnabled = true
        default:
            // 画像解析ボタンの非活性化
            self.imageAnalysisButton.isEnabled = false
        }
    }
    
    /// 編集ボタンの制御
    /// - Parameter inspectionData: 点検データ
    private func setExitButton(inspectionData: InspectionViewInfo) {
        // 検査待ち、検査中、再点検の時のみ活性化
        switch inspectionData.status {
        case INSPECTION_STATUS.WAITING.rawValue, INSPECTION_STATUS.UNDER_INSPECTION.rawValue, INSPECTION_STATUS.RE_INSPECTION.rawValue:
            break
        default:
            // 編集の非表示
            self.exitButton.isHidden = true
        }
    }
    
    /// OCR後の品番と製造番号の色を条件によって変更する
    /// - 文字数一致：緑
    /// - 文字数不一致：赤
    /// - 読取失敗：黄
    /// - Colorは色が見やすいようにsystemColorを利用
    /// - Parameter inspectionItemData: ローカルから取得した点検項目のデータ
    private func setOCRLabelColor(inspectionItemData: TBL_T_INSPECTION_ITEM) {
        // 製造番号の色を決定する
        if inspectionItemData.edited_serial_number == nil {
            // 製造番号が編集されていない場合
            if self.serialNumberText.text == OCR_FAILURE {
                // OCRの読取が失敗した時
                self.serialNumberText.textColor = .systemYellow
            } else if self.serialNumberText.text?.count != 10 {
                // OCRの文字数が一致しない時
                self.serialNumberText.textColor = .systemRed
            } else {
                // OCRの文字数が一致する時
                self.serialNumberText.textColor = .systemGreen
            }
        }
    }
    
    /// 表示コンテンツの初期化
    func initialize(inspectionItemData: TBL_T_INSPECTION_ITEM, inspectionData: InspectionViewInfo) {
        // 表示内容の初期化
        self.initContents(inspectionItemData: inspectionItemData)
        // 各ボタンの活性化設定
        // 撮影・再送ボタン
        setShootingResendButton(inspectionItemData: inspectionItemData, inspectionData: inspectionData, isUnsent: &self.isUnsent, photographButton: self.photographButton)
        // 画像解析ボタン
        self.setImageAnalysisButton(inspectionItemData: inspectionItemData, inspectionData: inspectionData)
        // 編集ボタン
        self.setExitButton(inspectionData: inspectionData)
        // サムネイルボタン
        setThumbnailImage(inspectionItemData: inspectionItemData, inspectionData: inspectionData, thumbnailButton: self.thumbnailImageButton)
    }
}
