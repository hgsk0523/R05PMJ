import UIKit

/// AI判定をする点検項目View
class AIInspectionItemView: UIView {
    
    // MARK: - Property
    
    /// 点検項目名のアウトレット
    @IBOutlet weak var inspectionItemName: CustomLabel!
    /// 日時のラベルのアウトレット
    @IBOutlet weak var dateText: UILabel!
    /// AI判定ラベルのアウトレット
    @IBOutlet weak var aiResultText: UILabel!
    /// カメラボタンのアウトレット
    @IBOutlet weak var photographButton: CustomButton!
    /// 画像解析ボタンのアウトレット
    @IBOutlet weak var imageAnalysisButton: CustomButton!
    /// コンテンツの高さのアウトレット
    @IBOutlet weak var contentHeight: NSLayoutConstraint!
    /// ngコメントボタンのアウトレット
    @IBOutlet weak var ngCommentButton: CustomButton!
    /// サムネイルボタンのアウトレット
    @IBOutlet weak var thumbnailImageButton: UIButton!
    /// 撮影ボタンの状態
    private var isUnsent: Bool = false
    /// S3画像パス
    private var s3ImagePath: String?
    /// 点検項目名
    private var itemName: String = ""
    /// NGコメント
    private var ngCommentText: String?
    /// 解析種別
    private var analysisType: String?
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
        let view = Bundle.main.loadNibNamed("AIInspectionItemView", owner: self, options: nil)?.first as! UIView
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
    
    /// ngコメントボタンを押した時
    /// - Parameter sender: ngコメントボタン
    @IBAction func onTapNgCommentButton(_ sender: Any) {
        if let parentVC = self.parentViewController() as? InspectionViewController {
            // NGコメント登録画面表示
            parentVC.onTapNGCommentButton(inspectionItemUUID: self.inspectionItemUUID!)
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
        // AI判定
        self.aiResultText.text = inspectionItemData.ai_result
        // NGコメント
        self.ngCommentText = inspectionItemData.ng_comment
        // 解析種別
        self.analysisType = inspectionItemData.analysis_type
        // 点検項目名ID
        self.inspectionItemNameID = inspectionItemData.item_name_id
        // 進捗状況
        self.progress = inspectionItemData.progress
        // 画像解析ボタンの非活性
        self.imageAnalysisButton.isEnabled = false
        // NGコメントボタンの非活性化
        self.ngCommentButton.isEnabled = false
        // AI判定のラベルを代入
        self.setAILabelColor(inspectionItemData: inspectionItemData)
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
    
    /// AI判定のラベルの色を条件によって変更する
    /// - AI判定OK：緑
    /// - AI判定NG：赤
    /// - 解析失敗：黄
    /// - Colorは色が見やすいようにsystemColorを利用
    /// - Parameter inspectionItemData: ローカルから取得した点検項目のデータ
    private func setAILabelColor(inspectionItemData: TBL_T_INSPECTION_ITEM) {
        // AI判定のラベルの色を条件によって変更
        if inspectionItemData.ai_result == AI_OK {
            // AI判定がOKのとき緑色
            self.aiResultText.textColor = .systemGreen
        } else if (inspectionItemData.ai_result == AI_NG) {
            // AI判定がNGのとき赤色
            self.aiResultText.textColor = .systemRed
        } else {
            // AI判定が解析失敗のとき黄色
            self.aiResultText.textColor = .systemYellow
        }
    }
    
    /// NGコメントボタンの制御
    /// - Parameters:
    ///     - inspectionItemData: ローカルから取得した点検項目のデータ
    ///     - inspectionData: 点検データ
    private func setNGCommentButton(inspectionItemData: TBL_T_INSPECTION_ITEM, inspectionData: InspectionViewInfo) {

        // エビデンス登録ボタンの活性非活性
        if inspectionItemData.ai_result == nil || inspectionItemData.ai_result == AI_OK {
            // AI判定が未実施またはOKの時
            // NGコメントボタンを非活性化
            self.ngCommentButton.isEnabled = false
            // 後続処理をしない
            return
        }
        
        // 検査待ち、検査中、再点検の時のみ活性化
        switch inspectionData.status {
        case INSPECTION_STATUS.WAITING.rawValue, INSPECTION_STATUS.UNDER_INSPECTION.rawValue, INSPECTION_STATUS.RE_INSPECTION.rawValue:
            //
            if inspectionItemData.progress == INSPECTION_PROGRESS.ANALYSIS_COMPLETED.rawValue {
                // NGコメントボタンを活性化
                self.ngCommentButton.isEnabled = true
            }
        default:
            // NGコメントボタンを非活性化
            self.ngCommentButton.isEnabled = false
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
        // NGコメントボタン
        self.setNGCommentButton(inspectionItemData: inspectionItemData, inspectionData: inspectionData)
        // サムネイルボタン
        setThumbnailImage(inspectionItemData: inspectionItemData, inspectionData: inspectionData, thumbnailButton: self.thumbnailImageButton)
    }
}
