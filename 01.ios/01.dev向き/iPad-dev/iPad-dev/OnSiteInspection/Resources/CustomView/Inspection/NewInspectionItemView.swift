import UIKit

/// 新規追加した点検項目View
class NewInspectionItemView: UIView {
    
    // MARK: - Property
    
    /// 点検項目名のアウトレット
    @IBOutlet weak var inspectionItemName: CustomLabel!
    /// 日時のラベルのアウトレット
    @IBOutlet weak var dateText: UILabel!
    /// カメラボタンのアウトレット
    @IBOutlet weak var photographButton: CustomButton!
    /// 画像解析ボタンのアウトレット
    @IBOutlet weak var imageAnalysisButton: CustomButton!
    /// 削除ボタンのアウトレット
    @IBOutlet weak var deleteButton: CustomButton!
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
    /// 進捗状況
    private var progress: Int?
    /// 点検項目id
    /// どの点検項目かを識別するために必要
    var inspectionItemId: Int?
    /// 点検項目id(UUID)
    var inspectionItemUUID: UUID?
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
    
    private func loadNib() {
        let view = Bundle.main.loadNibNamed("NewInspectionItemView", owner: self, options: nil)?.first as! UIView
        view.frame = self.bounds
        self.addSubview(view)
        
        // 高さを調整
        self.heightAnchor.constraint(equalToConstant: CGFloat(self.contentHeight.constant)).isActive = true
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
                                     analysisType: nil)
            } else {
                // 撮影画面に遷移
                parentVC.onTapPhotograph(inspectionItemUUID: self.inspectionItemUUID!,
                                         inspectionItemID: self.inspectionItemId,
                                         inspectionItemName: self.inspectionItemName.text!,
                                         inspectionItemNameID: self.inspectionItemNameID,
                                         analysisType: nil)
            }
        }
    }
    
    /// 削除ボタンを押した時
    /// - Parameter sender: 削除ボタン
    @IBAction func onTapDeleteButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            // 削除確認ダイアログ表示
            parentVC.onTapDeleteButton(inspectionItemUUID: self.inspectionItemUUID!)
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
        // 点検項目Viewにidを格納する
        self.inspectionItemId = inspectionItemData.inspection_item_id
        // 点検項目Viewに(UUID)を格納する
        self.inspectionItemUUID = inspectionItemData.inspection_item_uuid
        // 点検項目名設定
        self.inspectionItemName.text = inspectionItemData.item_name
        // s3イメージパス
        self.s3ImagePath = inspectionItemData.s3_original_image_path
        // 撮影日時を保存
        self.dateText.text = inspectionItemData.taken_dt?.toJst(format: DRAW_DATE_FORMAT)
        // 進捗状況
        self.progress = inspectionItemData.progress
        // 画像解析ボタンの非活性
        self.imageAnalysisButton.isEnabled = false
        // 高さを調整
        self.heightAnchor.constraint(equalToConstant: CGFloat(self.contentHeight.constant)).isActive = true
    }
    
    /// 削除ボタンの制御
    /// - Parameter inspectionData: 点検データ
    private func setDeleteButton(inspectionData: InspectionViewInfo) {
        
        // 検査待ち、検査中、再点検の時のみ活性化
        switch inspectionData.status {
        case INSPECTION_STATUS.WAITING.rawValue, INSPECTION_STATUS.UNDER_INSPECTION.rawValue, INSPECTION_STATUS.RE_INSPECTION.rawValue:
            break
        default:
            // 削除ボタンの非表示
            self.deleteButton.isHidden = true
        }
    }
    
    /// 表示コンテンツの初期化
    func initialize(inspectionItemData: TBL_T_INSPECTION_ITEM, inspectionData: InspectionViewInfo) {
        // 表示内容の初期化
        self.initContents(inspectionItemData: inspectionItemData)
        // 各ボタンの活性化設定
        // 撮影・再送ボタン
        setShootingResendButton(inspectionItemData: inspectionItemData, inspectionData: inspectionData, isUnsent: &self.isUnsent, photographButton: self.photographButton)
        // サムネイルボタン
        setThumbnailImage(inspectionItemData: inspectionItemData, inspectionData: inspectionData, thumbnailButton: self.thumbnailImageButton)
        // 削除ボタン
        self.setDeleteButton(inspectionData: inspectionData)
    }
}
